import os
from contextlib import asynccontextmanager
from typing import List, AsyncGenerator

import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field # <-- Importar Field
from sqlalchemy import Column, ForeignKey, Integer, String, Table, create_engine, text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import declarative_base, relationship, sessionmaker, Mapped, mapped_column

# --- Configuración de la Base de Datos ---
load_dotenv()

DB_USER = os.getenv("DB_USER", "db_admin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "MiProyecto-Tesis-2025!")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "postgres")

DATABASE_URL = f"postgresql+asyncpg://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

engine = create_async_engine(DATABASE_URL)
AsyncSessionLocal = sessionmaker(
    bind=engine, class_=AsyncSession, expire_on_commit=False
)
Base = declarative_base()


# --- Modelos de Base de Datos (SQLAlchemy) ---
student_courses_table = Table(
    "student_courses",
    Base.metadata,
    Column("student_id", Integer, ForeignKey("students.id"), primary_key=True),
    Column("course_id", Integer, ForeignKey("courses.id"), primary_key=True),
)

class Student(Base):
    __tablename__ = "students"
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    first_name: Mapped[str] = mapped_column(String(100))
    last_name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(100), unique=True)
    courses = relationship("Course", secondary=student_courses_table, back_populates="students")

class Course(Base):
    __tablename__ = "courses"
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    credits: Mapped[int] = mapped_column(Integer)
    students = relationship("Student", secondary=student_courses_table, back_populates="courses")


# --- Schemas de Datos (Pydantic) ---

# ================== INICIO DE LA CORRECCIÓN ==================
# Le decimos a Pydantic que acepte "firstName" y "lastName" (camelCase)
# como alias para nuestros campos "first_name" y "last_name" (snake_case)

class StudentCreate(BaseModel):
    first_name: str = Field(..., alias='firstName')
    last_name: str = Field(..., alias='lastName')
    email: str

class StudentSchema(BaseModel):
    id: int
    first_name: str = Field(..., alias='firstName')
    last_name: str = Field(..., alias='lastName')
    email: str

    class Config:
        from_attributes = True
        # Esta configuración permite que Pydantic devuelva JSON en camelCase también
        populate_by_name = True 
# =================== FIN DE LA CORRECCIÓN ===================


# --- Gestión de la App y Sesión de BD ---

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all, checkfirst=True)
    yield
    await engine.dispose()

app = FastAPI(lifespan=lifespan)

async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session

# --- Endpoints CRUD ---

@app.post("/api/students", response_model=StudentSchema)
async def create_student(student: StudentCreate, db: AsyncSession = Depends(get_db_session)):
    # Convertimos el Pydantic (con alias) a un dict de Python
    student_data = student.model_dump(by_alias=False) 
    
    # Creamos el objeto SQLAlchemy
    new_student = Student(**student_data)
    
    db.add(new_student)
    await db.commit()
    await db.refresh(new_student)
    return new_student

@app.get("/api/students", response_model=List[StudentSchema])
async def get_all_students(db: AsyncSession = Depends(get_db_session)):
    result = await db.execute(text("SELECT id, first_name, last_name, email FROM students"))
    students_raw = result.fetchall()
    
    # Mapeo manual para asegurar que los nombres de campo coincidan
    students = [
        {"id": s[0], "first_name": s[1], "last_name": s[2], "email": s[3]}
        for s in students_raw
    ]
    return students

@app.get("/api/students/{student_id}", response_model=StudentSchema)
async def get_student_by_id(student_id: int, db: AsyncSession = Depends(get_db_session)):
    result = await db.execute(
        text("SELECT id, first_name, last_name, email FROM students WHERE id = :id"), 
        {"id": student_id}
    )
    student = result.fetchone()
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    
    # Mapeo manual
    return {"id": student[0], "first_name": student[1], "last_name": student[2], "email": student[3]}

# --- Punto de entrada para Uvicorn ---
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

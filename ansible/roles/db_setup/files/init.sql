-- Eliminar tablas si ya existen (para pruebas)
DROP TABLE IF EXISTS student_courses;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;

-- Crear la tabla de Estudiantes
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

-- Crear la tabla de Cursos
CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    credits INT NOT NULL
);

-- Crear la tabla de unión (relación muchos a muchos)
CREATE TABLE student_courses (
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);

-- Insertar algunos datos de ejemplo (opcional)
INSERT INTO students (first_name, last_name, email) VALUES
('Juan', 'Perez', 'juan.perez@test.com'),
('Maria', 'Gomez', 'maria.gomez@test.com');

INSERT INTO courses (name, credits) VALUES
('Pruebas Avanzadas de Software', 5),
('Arquitectura de Nube', 4);

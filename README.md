# AWS JMeter Benchmark: Comparativa de Rendimiento Backend

Este proyecto implementa una infraestructura automatizada en AWS para realizar pruebas de carga y comparar el rendimiento de aplicaciones API RESTful desarrolladas en diferentes frameworks. Actualmente, el foco principal es la comparativa entre **Spring Boot (Java)** y **FastAPI (Python)**.

El despliegue utiliza **Terraform** para la Infraestructura como Código (IaC) y **Ansible** para la gestión de configuración y orquestación de pruebas.

## 1. Arquitectura y Diseño del Experimento

El experimento despliega una arquitectura distribuida de tres nodos para simular un entorno de producción realista:

1. **Cliente de Pruebas (JMeter Node):** Una instancia EC2 (`t3.large`) dedicada exclusivamente a generar tráfico.

2. **Servidor de Aplicación (App Server):** Una instancia EC2 (`t3.large`) que aloja la API (Spring Boot o FastAPI).

3. **Base de Datos:** Una instancia RDS (`db.t3.micro`) con motor **PostgreSQL**.

### Modelo de Datos

Para cumplir con requisitos de complejidad realista, se utiliza un esquema relacional de tres tablas:

* `students`: Información de estudiantes.

* `courses`: Información de cursos.

* `student_courses`: Tabla de unión para relaciones muchos a muchos.

La base de datos se inicializa y puebla automáticamente mediante un script SQL ejecutado por Ansible (`ansible/roles/db_setup/files/init.sql`) al momento del despliegue.

## 2. Requisitos Previos y Configuración de AWS

Para replicar este experimento, es crítico configurar correctamente la seguridad y el acceso en AWS. Se requieren dos tipos de credenciales distintas:

### A. Par de Claves EC2 (.pem)

**¿Para qué sirve?** Permite que Ansible (desde tu máquina local) se conecte por SSH a las instancias EC2 creadas para instalar software y ejecutar pruebas.

* **Cómo obtenerla:** En la consola de AWS > EC2 > Key Pairs > "Create key pair".

* **Configuración:** Descarga el archivo `.pem`. Debes darle permisos restrictivos (`chmod 400 tu-clave.pem`) y configurar su ruta en el archivo `terraform/inventory.tpl`.

### B. Credenciales de Acceso (IAM Access Keys)

**¿Para qué sirve?** Permite que Terraform se comunique con la API de AWS para crear y destruir recursos (VPC, EC2, RDS).

* **Cómo obtenerla:** En AWS IAM > Users > Security credentials > Create access key.

* **Configuración:** Se configuran generalmente mediante `aws configure` en tu terminal o exportando las variables `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`.

### C. Variables Sensibles (Secretos)

Antes de iniciar, debes asegurarte de tener definidas las siguientes variables críticas. Estas no deben estar escritas directamente en el código que se sube al repositorio.

* **`ssh_key_name`**: El nombre exacto del par de claves que creaste en la consola de AWS.

* **`db_password`**: La contraseña maestra para la base de datos RDS (PostgreSQL).

## 3. Proyectos Backend (Sujetos de Prueba)

Los proyectos de backend ubicados en la carpeta `projects/` han sido generados asistidos por Inteligencia Artificial para propósitos de este benchmark.

* **Spring Boot CRUD:** Implementación estándar con Spring Data JPA y Tomcat embebido.

* **FastAPI CRUD:** Implementación asíncrona con Uvicorn y SQLAlchemy (async).

> **Nota:** Dado que el código fue generado por IA, puede no seguir estrictamente todos los patrones de diseño de producción, pero son funcionalmente aptos para la prueba de carga transaccional.

## 4. Configuración de la Prueba (JMeter)

El plan de pruebas se encuentra en: `ansible/roles/deploy_jmeter_test/templates/test_plan.jmx.j2`.

Es una plantilla dinámica de Ansible que inyecta automáticamente la IP del servidor y el puerto de la aplicación. Las condiciones del experimento son:

* **Usuarios Concurrentes (Hilos):** 100 usuarios.

* **Periodo de Rampa (Ramp-up):** 30 segundos (los usuarios entran gradualmente).

* **Duración:** 300 segundos (5 minutos de carga sostenida).

* **Mezcla de Transacciones:**

  * 80% Lectura (GET `/api/students`)

  * 15% Escritura (POST `/api/students`)

  * 5% Lectura unitaria (GET `/api/students/{id}`)

## 5. Despliegue y Ejecución

El flujo de trabajo recomendado para ejecutar una prueba completa es secuencial:

1. **Infraestructura:** Ejecutar `terraform apply` para levantar los servidores.

2. **Despliegue de App:** Usar `ansible-playbook` para instalar el framework específico (Spring o FastAPI).

3. **Ejecución de Test:** Usar `ansible-playbook` para disparar la prueba de carga JMeter.

### Ejemplo de Comandos de Ejecución

Para ejecutar una prueba de **Spring Boot**, los comandos exactos serían:

```bash
# 1. Crear infraestructura
cd terraform
terraform apply -auto-approve

# 2. Desplegar Spring Boot
cd ../ansible
ansible-playbook -i inventory.ini playbook-deploy-spring.yml -e "db_password=TU_CONTRASEÑA_SECRETA"

# 3. Ejecutar Prueba JMeter
ansible-playbook -i inventory.ini playbook-run-test.yml -e "app_name=spring-boot"
```

**Salida Esperada:**

* **Paso 1:** Verás a Terraform creando recursos (`Creating...`) y al final te mostrará las IPs públicas de las nuevas instancias.

* **Paso 2:** Verás a Ansible conectándose a las instancias, instalando Java, configurando la BD y arrancando el servicio. Deberías ver `changed=...` y ningún `failed`.

* **Paso 3:** Verás a Ansible ejecutando JMeter en el cliente remoto. Al final, descargará el reporte a tu carpeta local `results/spring-boot-dashboard/`.

### Visualización de Resultados (Nginx)

Se ha desarrollado un script automatizado (`serve_reports.sh`) con ayuda de IA para exponer los resultados HTML de JMeter vía web.

* **Requisitos:** Este script requiere tener `nginx` instalado en la máquina de control (`apt install nginx`).

* **Uso:** `./serve_reports.sh`

* **Resultado:** Configurará Nginx para servir los reportes en el puerto 80. Podrás acceder a ellos en:

  * `http://<TU_IP>/spring/`

  * `http://<TU_IP>/fastapi/`

## 6. Resultados Obtenidos

A continuación, se presenta un resumen de los resultados obtenidos en las pruebas realizadas sobre instancias `t3.large` en la región `us-east-1`.

| **Métrica** | **Spring Boot (Java)** | **FastAPI (Python)** |
| :--- | :--- | :--- |
| **Throughput (Tx/seg)** | **~125.78** | ~63.08 |
| **Tasa de Error** | **0.00%** | 2.90% |
| **Tiempo Respuesta Promedio** | **754 ms** | 1502 ms |
| **APDEX** | **0.618 (Tolerable)** | 0.435 (Pobre) |

**Observaciones del Experimento:**
En las condiciones de esta prueba, la aplicación **Spring Boot** demostró un rendimiento y estabilidad significativamente superiores. Manejó el doble de transacciones por segundo que FastAPI y operó con cero errores. **FastAPI** mostró dificultades bajo la carga de escritura (POST), generando excepciones de `SocketTimeoutException` y colapsando parcialmente bajo la carga concurrente.

## 7. Extensibilidad del Proyecto

Este proyecto ha sido diseñado de forma modular para ser fácilmente extensible. Animamos a otros estudiantes e investigadores a utilizar esta base para:

* **Añadir Nuevos Frameworks:** Simplemente crea una nueva carpeta en `projects/` (ej. `projects/go-gin-crud/`) y un nuevo rol de Ansible (`ansible/roles/deploy_go_app`) siguiendo el patrón existente.

* **Cambiar la Infraestructura:** Modifica `terraform/variables.tf` para probar con instancias más grandes (`c5.xlarge`) o diferentes bases de datos (MySQL, Aurora).

* **Escalar la Prueba:** Ajusta `test_plan.jmx.j2` para simular 500 o 1000 usuarios y encontrar el punto de quiebre de cada tecnología.

## Limpieza

Para evitar costos en AWS, siempre destruye la infraestructura al finalizar las pruebas:

```bash
cd terraform
terraform destroy
```

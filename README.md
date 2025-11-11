# AWS JMeter Benchmark

Este proyecto provee la infraestructura como código (IaC) y la configuración necesaria para desplegar un entorno de benchmarking de rendimiento en AWS utilizando Terraform y Ansible. El objetivo es facilitar la creación de un servidor de aplicaciones y un cliente JMeter para realizar pruebas de carga.

## Estructura del Proyecto

- `terraform/`: Contiene los archivos de Terraform para provisionar la infraestructura en AWS.
  - `modules/`: Módulos reutilizables de Terraform (networking, compute, database).
  - `terraform.tfvars`: Variables de configuración sensibles (NO SUBIR A GIT).
  - `terraform.tfvars.example`: Ejemplo de `terraform.tfvars`.
  - `inventory.tpl`: Plantilla para el inventario de Ansible.
  - `inventory.tpl.example`: Ejemplo de `inventory.tpl`.
- `ansible/`: Contiene los playbooks y roles de Ansible para configurar las instancias EC2.
  - `roles/`: Roles de Ansible para configuración común, cliente JMeter y servidor de aplicaciones.

## Pre-requisitos

- [Terraform](https://www.terraform.io/downloads.html) instalado.
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) instalado.
- Credenciales de AWS configuradas (CLI de AWS o variables de entorno).
- Un par de claves SSH de AWS existente y configurado para acceso a las instancias EC2.

## Configuración Inicial

1.  **Clonar el repositorio**:
    ```bash
    git clone <URL_DEL_REPOSITORIO>
    cd aws_jmeter_benchmark
    ```

2.  **Configurar Terraform**:
    Navegue al directorio `terraform`:
    ```bash
    cd terraform
    ```
    Cree su archivo `terraform.tfvars` a partir del ejemplo y edítelo con sus valores:
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    # Edite terraform.tfvars con su aws_region, instance_type, ssh_key_name y db_password
    ```
    Asegúrese de que `ssh_key_name` coincida con el nombre de un par de claves existente en su cuenta de AWS. Descomente y establezca `db_password` con una contraseña segura.

3.  **Inicializar Terraform**:
    ```bash
    terraform init
    ```

4.  **Configurar Ansible**:
    Cree su archivo `inventory.tpl` a partir del ejemplo y edítelo con la ruta a su clave SSH privada:
    ```bash
    cp inventory.tpl.example inventory.tpl
    # Edite inventory.tpl y cambie "~/.ssh/tu-llave-ssh-en-aws.pem" por la ruta real a su clave privada.
    ```

## Despliegue de la Infraestructura

Desde el directorio `terraform`, ejecute:

```bash
terraform plan
terraform apply
```

Confirme la aplicación escribiendo `yes` cuando se le solicite.

Una vez que Terraform haya terminado, generará un archivo `ansible/inventory.ini` con las IPs públicas de las instancias desplegadas.

## Ejecución de Playbooks de Ansible

Desde el directorio raíz del proyecto (`aws_jmeter_benchmark`), ejecute los playbooks de Ansible para configurar las instancias:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

## Pruebas de Carga con JMeter

Después de que Ansible haya configurado el cliente JMeter, puede conectarse a la instancia del cliente JMeter usando SSH y ejecutar sus scripts de prueba de JMeter.

```bash
ssh -i ~/.ssh/tu-llave-ssh-en-aws.pem ubuntu@<IP_PUBLICA_JMETER_CLIENT>
```

Dentro de la instancia de JMeter, puede encontrar la instalación en `/opt/apache-jmeter-5.6.3/bin/jmeter` o simplemente usar el comando `jmeter` si el enlace simbólico se creó correctamente.

## Limpieza

Para destruir la infraestructura creada por Terraform, navegue al directorio `terraform` y ejecute:

```bash
terraform destroy
```

Confirme la destrucción escribiendo `yes` cuando se le solicite.

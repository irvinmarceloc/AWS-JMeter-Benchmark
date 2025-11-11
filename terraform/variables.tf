variable "aws_region" {
  description = "Región de AWS para desplegar la infraestructura."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Tipo de instancia EC2 (ej. t3.large)."
  type        = string
  default     = "t3.large"
}

variable "db_password" {
  description = "Contraseña para el usuario admin de la BD RDS."
  type        = string
  sensitive   = true
}

variable "ssh_key_name" {
  description = "Nombre del Key Pair de AWS para acceder a las EC2."
  type        = string
}

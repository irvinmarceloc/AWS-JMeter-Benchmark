variable "instance_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "ssh_key_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS en us-east-1"
  type        = string
  default     = "ami-053b0d5c279acc90"
}

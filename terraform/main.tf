terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source     = "./modules/networking"
  aws_region = var.aws_region
}

module "database" {
  source                 = "./modules/database"
  db_password            = var.db_password
  db_subnet_group_name   = module.networking.db_subnet_group_name
  vpc_security_group_ids = [module.networking.sg_database_id]
}

module "app_server" {
  source                   = "./modules/compute"
  instance_name            = "App-Server-Node"
  subnet_id                = module.networking.public_subnet_id
  vpc_security_group_ids   = [module.networking.sg_app_server_id]
  ssh_key_name             = var.ssh_key_name
  instance_type            = var.instance_type
}

module "jmeter_client" {
  source                   = "./modules/compute"
  instance_name            = "JMeter-Client-Node"
  subnet_id                = module.networking.public_subnet_id
  vpc_security_group_ids   = [module.networking.sg_jmeter_client_id]
  ssh_key_name             = var.ssh_key_name
  instance_type            = var.instance_type
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    app_server_ip    = module.app_server.public_ip,
    jmeter_client_ip = module.jmeter_client.public_ip
  })
  filename = "../ansible/inventory.ini"
}

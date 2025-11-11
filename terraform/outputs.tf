output "app_server_public_ip" {
  description = "IP pública del servidor de aplicaciones."
  value       = module.app_server.public_ip
}

output "jmeter_client_public_ip" {
  description = "IP pública del cliente JMeter."
  value       = module.jmeter_client.public_ip
}

output "rds_database_endpoint" {
  description = "Endpoint de la base de datos RDS."
  value       = module.database.db_endpoint
  sensitive   = true
}

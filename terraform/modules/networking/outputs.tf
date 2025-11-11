output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.rds_subnet_group.name
}

output "sg_jmeter_client_id" {
  value = aws_security_group.jmeter_client.id
}

output "sg_app_server_id" {
  value = aws_security_group.app_server.id
}

output "sg_database_id" {
  value = aws_security_group.database.id
}

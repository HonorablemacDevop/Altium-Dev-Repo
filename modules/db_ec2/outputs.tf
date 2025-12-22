output "db_private_ip" {
  value = aws_instance.db.private_ip
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "db_security_group_id" {
  value = aws_security_group.db_sg.id
}

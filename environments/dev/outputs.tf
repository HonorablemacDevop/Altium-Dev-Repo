output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "app_url" {
  value = "https://${var.domain_name}"
}

output "db_private_ip" {
  value = module.db.db_private_ip
}

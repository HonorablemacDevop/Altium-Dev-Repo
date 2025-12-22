variable "altium_dev" { type = string }
variable "tags" { type = map(string) }

variable "vpc_id" { type = string }
variable "private_subnet_id" { type = string }

variable "instance_type" { type = string }
variable "db_port" { type = number }

variable "ssh_ingress_cidr" { type = string }

variable "app_security_group_id" {
  description = "App SG ID so DB allows inbound 3306 from app tier"
  type        = string
}

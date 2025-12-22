variable "name_prefix" { type = string }
variable "tags" { type = map(string) }

variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "instance_type" { type = string }
variable "app_port" { type = number }

variable "alb_target_group_arn" { type = string }
variable "alb_security_group_id" { type = string }

variable "db_endpoint" { type = string }
variable "db_port" { type = number }

variable "secrets_manager_secret_arn" {
  description = "Secret containing DB creds"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile for reading secret"
  type        = string
}

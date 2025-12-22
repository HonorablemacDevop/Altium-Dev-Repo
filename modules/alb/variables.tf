variable "altium_dev" { type = string }
variable "tags" { type = map(string) }

variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }

variable "acm_certificate_arn" { type = string }
variable "app_port" { type = number }

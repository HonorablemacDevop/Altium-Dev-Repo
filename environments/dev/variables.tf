variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "altium-3tier"
}

variable "domain_name" {
  description = "FQDN to point to ALB, e.g. app-dev.yourdomain.com"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 zone name, e.g. yourdomain.com"
  type        = string
}

variable "instance_type_app" {
  type    = string
  default = "t3.micro"
}

variable "instance_type_db" {
  type    = string
  default = "t3.micro"
}

variable "app_port" {
  type    = number
  default = 80
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "ssh_ingress_cidr" {
  description = "Optional: restrict SSH to your IP. Set to 0.0.0.0/0 only if required."
  type        = string
  default     = "0.0.0.0/0"
}

data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "random_password" "db" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.altium_dev}/db/mysql"
  recovery_window_in_days = 0
  tags                    = merge(var.tags, { Name = "${var.altium_dev}-db-secret" })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "appuser"
    password = random_password.db.result
  })
}

resource "aws_security_group" "db_sg" {
  name        = "${var.altium_dev}-db-sg"
  description = "DB SG: MySQL from app SG, SSH optional"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.altium_dev}-db-sg" })
}

resource "aws_security_group_rule" "db_in_mysql" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db_sg.id
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.app_security_group_id
  description              = "MySQL from app tier"
}

resource "aws_security_group_rule" "db_in_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.db_sg.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_ingress_cidr]
  description       = "SSH (lock down in real life)"
}

# User-data installs and configures MySQL. Uses generated password from Terraform (not fetched by DB instance).
locals {
  db_user = "appuser"
  db_pass = random_password.db.result
}

resource "aws_instance" "db" {
  ami                         = data.aws_ami.al2.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  associate_public_ip_address = true # default VPC subnets are public; keep simple for interview
  tags                        = merge(var.tags, { Name = "${var.altium_dev}-db" })


}

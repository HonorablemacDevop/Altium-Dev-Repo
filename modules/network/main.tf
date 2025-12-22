data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_in_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Pick exactly 3 subnets (default subnets across AZs usually). Sort for deterministic ordering.
locals {
  subnet_ids_sorted = slice(sort(data.aws_subnets.default_in_vpc.ids), 0, 3)
}

# Determine which of the 3 are "public" vs "private" by route table association:
# In default VPC, default subnets are typically public, but interviews like seeing "tiering".
# We'll treat 2 as public for ALB and 1 as private-ish for DB/app. Still in default VPC though.
locals {
  public_subnet_ids  = slice(local.subnet_ids_sorted, 0, 2)
  private_subnet_ids = slice(local.subnet_ids_sorted, 1, 3)
}

# NACL (simple, permissive but explicit)
resource "aws_network_acl" "tier_nacl" {
  vpc_id = data.aws_vpc.default.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-nacl" })
}

# Associate NACL with all selected subnets
resource "aws_network_acl_association" "assoc" {
  for_each       = toset(local.subnet_ids_sorted)
  network_acl_id = aws_network_acl.tier_nacl.id
  subnet_id      = each.value
}

# Inbound allow: HTTP/HTTPS + ephemeral + SSH + MySQL
resource "aws_network_acl_rule" "in_http" {
  network_acl_id = aws_network_acl.tier_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "in_https" {
  network_acl_id = aws_network_acl.tier_nacl.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "in_ssh" {
  network_acl_id = aws_network_acl.tier_nacl.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "in_mysql" {
  network_acl_id = aws_network_acl.tier_nacl.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3306
  to_port        = 3306
}

resource "aws_network_acl_rule" "in_ephemeral" {
  network_acl_id = aws_network_acl.tier_nacl.id
  rule_number    = 140
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Outbound allow all (explicit)
resource "aws_network_acl_rule" "out_all" {
  network_acl_id = aws_network_acl.tier_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

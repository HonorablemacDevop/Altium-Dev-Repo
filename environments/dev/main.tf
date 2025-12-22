locals {
  name_prefix = "${var.project}-${var.env}"
  tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

module "network" {
  source      = "../../modules/network"
  name_prefix = local.name_prefix
  tags        = local.tags
}

module "route53_acm" {
  source           = "../../modules/route53_acm"
  name_prefix      = local.name_prefix
  tags             = local.tags
  hosted_zone_name = var.hosted_zone_name
  domain_name      = var.domain_name
}

module "iam" {
  source      = "../../modules/iam"
  name_prefix = local.name_prefix
  tags        = local.tags
}

module "alb" {
  source      = "../../modules/alb"
  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_id          = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids

  acm_certificate_arn = module.route53_acm.certificate_arn
  app_port            = var.app_port
}

module "db" {
  source      = "../../modules/db_ec2"
  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_id              = module.network.vpc_id
  private_subnet_id    = module.network.private_subnet_ids[0]
  instance_type        = var.instance_type_db
  db_port              = var.db_port
  ssh_ingress_cidr     = var.ssh_ingress_cidr
  app_security_group_id = module.alb.app_security_group_id
}

module "asg_app" {
  source      = "../../modules/asg_app"
  name_prefix = local.name_prefix
  tags        = local.tags

  vpc_id               = module.network.vpc_id
  private_subnet_ids   = module.network.private_subnet_ids
  instance_type        = var.instance_type_app
  app_port             = var.app_port

  alb_target_group_arn = module.alb.target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id

  db_endpoint          = module.db.db_private_ip
  db_port              = var.db_port

  secrets_manager_secret_arn = module.db.db_secret_arn

  instance_profile_name = module.iam.instance_profile_name
}

module "route53_record" {
  source           = "../../modules/route53_acm"
  name_prefix      = local.name_prefix
  tags = local.tags
  domain_name = var.domain_name
  hosted_zone_name = var.hosted_zone_name

}

data "aws_route53_zone" "zone" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_record" "app_alias" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}

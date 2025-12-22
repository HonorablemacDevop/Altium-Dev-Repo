data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Launch template user-data:
# - installs awscli + jq
# - installs package from repository example.com (placeholder)
# - if package missing, app won't start
# - fetches DB creds from Secrets Manager at boot (requires IAM role from module/iam)
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    yum update -y
    yum install -y awscli jq

    # ----- Example external repo/package install (placeholder) -----
    # In real life you'd add the repo properly (yum repo file / gpg key).
    # This models the interview requirement: if not installed, app won't start.

    # pretend to add repo
    cat > /etc/yum.repos.d/example.repo <<'REPO'
    [example]
    name=Example Repo
    baseurl=https://example.com/repo/yum
    enabled=1
    gpgcheck=0
    REPO

    # install required package
    yum install -y example-app || true

    if ! rpm -q example-app; then
      echo "example-app package not installed; application will not start." | tee /var/log/example-app-bootstrap.log
      exit 1
    fi

    # ----- Fetch DB credentials from Secrets Manager -----
    SECRET_ARN="${var.secrets_manager_secret_arn}"
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --query SecretString --output text --region ${data.aws_region.current.name})

    DB_USER=$(echo "$SECRET_JSON" | jq -r .username)
    DB_PASS=$(echo "$SECRET_JSON" | jq -r .password)

    # Write app env
    cat > /etc/example-app.env <<ENV
    DB_HOST=${var.db_endpoint}
    DB_PORT=${var.db_port}
    DB_USER=$DB_USER
    DB_PASS=$DB_PASS
    ENV=${var.name_prefix}
    ENV

    # ----- Start a simple web service to prove ALB works -----
    # If example-app provides a service, replace below with systemctl start example-app
    yum install -y httpd
    echo "OK - ${var.name_prefix} - DB ${var.db_endpoint}:${var.db_port}" > /var/www/html/index.html
    systemctl enable httpd
    systemctl start httpd
  EOF
}

data "aws_region" "current" {}

resource "aws_security_group" "app_sg" {
  name        = "${var.name_prefix}-app-instances-sg"
  description = "App instances SG: allow inbound from ALB on app port"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-app-instances-sg" })
}

resource "aws_security_group_rule" "app_in_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.app_sg.id
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = var.alb_security_group_id
  description              = "App port from ALB"
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = data.aws_ami.al2.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = base64encode(local.user_data)

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-app" })
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.name_prefix}-asg"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  health_check_type         = "ELB"
  health_check_grace_period = 120
  vpc_zone_identifier       = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [var.alb_target_group_arn]

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-app"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

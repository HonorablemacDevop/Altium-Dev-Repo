## Altium AWS 3-tier (Default VPC) Terraform POC

### What it creates
- Default VPC + 3 default subnets (discovered)
- ACM cert (DNS validated) + Route53 record
- Public ALB with HTTP->HTTPS redirect + HTTPS listener
- ASG with desired capacity = 1 (Linux app instance)
- EC2 MySQL instance
- Security Groups + NACLs
- Secrets Manager secret for DB password (generated)
- IAM role allowing app instance to fetch secret at boot

### Prereqs
- Terraform >= 1.6
- AWS account credentials configured
- Route53 Hosted Zone for yourdomain.com

### Run
cd environments/dev
terraform init
terraform apply

### Destroy
terraform destroy

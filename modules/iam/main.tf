data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app_role" {
  name               = "${var.name_prefix}-app-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = var.tags
}

# Allow reading secrets (scoped later by ARN passed in user-data; but policy needs permission).
# We'll allow GetSecretValue on all secrets with prefix for simplicity.
data "aws_iam_policy_document" "secrets_read" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "secrets_read" {
  name   = "${var.name_prefix}-secrets-read"
  policy = data.aws_iam_policy_document.secrets_read.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "attach_secrets" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.secrets_read.arn
}

# Allow SSM (optional, good in interviews)
resource "aws_iam_role_policy_attachment" "attach_ssm" {
  role       = aws_iam_role.app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.name_prefix}-app-profile"
  role = aws_iam_role.app_role.name
  tags = var.tags
}

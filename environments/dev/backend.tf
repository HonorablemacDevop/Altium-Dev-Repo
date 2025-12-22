terraform {
  backend "s3" {
    bucket         = "altium_dev_tf_state_bucket"
    key            = "altium/dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "altium_dev_tf_state_lock"
    encrypt        = true
  }
}

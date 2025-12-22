terraform {
  backend "s3" {
    bucket         = "CHANGE_ME_tf_state_bucket"
    key            = "altium/dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "CHANGE_ME_tf_state_lock"
    encrypt        = true
  }
}

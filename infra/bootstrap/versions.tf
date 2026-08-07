terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "eks-deployment-state-s3-sm22"
    key          = "bootstrap/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    encrypt      = true
    kms_key_id   = "arn:aws:kms:eu-west-2:112639119087:key/41c68d5f-3a3e-4463-b022-8b1e66008f6a"
  }
}

# required_providers, not a provider block. The module declares which provider it
# needs and what it is compatible with; the root configures it and the module
# inherits that configuration.

terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

terraform {
  # S3 native state locking (use_lockfile) landed in 1.10 — that is the real
  # floor for this layer, so pin the constraint to it rather than to whichever
  # version happens to be installed locally.
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

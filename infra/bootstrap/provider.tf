provider "aws" {
  region = var.region
  # Propagates to every resource this provider creates
  default_tags {
    tags = local.tags
  }
}

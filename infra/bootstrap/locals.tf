locals {
  # Applied to every resource through the provider's default_tags block.
  tags = merge(
    {
      Project     = var.project
      Environment = "shared"
      Owner       = var.owner
      ManagedBy   = "terraform"
      Repository  = var.repository
      Layer       = "bootstrap"
    },
    var.additional_tags,
  )
}

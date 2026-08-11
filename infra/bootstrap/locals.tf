locals {
  # Immutable subject prefix: the numeric user and repository IDs rather than their
  # names, so a renamed or re-created repository cannot inherit this trust.
  github_sub_prefix = "repo:smir22@115804940/eks-deployment-app@1320666729"

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

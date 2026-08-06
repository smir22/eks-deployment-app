locals {
  # Applied to every resource through the provider's default_tags block. Modules
  # inherit the root provider, so these reach module-created resources without
  # any tags variable being threaded through — a module only needs its own tags
  # variable when it has genuinely module-specific tags to add.
  #
  # Scalars rather than a single opaque map, because project/environment are
  # also needed for resource naming; keeping them as variables avoids writing
  # "eks-deployment-app" in both a name and a tag and letting the two drift.
  tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "terraform"
      Repository  = var.repository
    },
    var.additional_tags,
  )
}

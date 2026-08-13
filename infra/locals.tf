locals {
  # Names are derived once here rather than in each module block, so the EKS
  # module and the VPC module cannot drift apart on what the cluster is called -
  # the subnet discovery tags have to match the real cluster name exactly.
  name_prefix  = "${var.project}-${var.environment}"
  cluster_name = local.name_prefix

  # Applied to every resource through the provider's default_tags block. Modules
  # inherit the root provider, so these reach module-created resources without
  # any tags variable being threaded through - a module only needs its own tags
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

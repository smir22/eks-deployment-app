provider "aws" {
  region = var.region

  # Propagates to every resource this provider creates, including those inside
  # modules. Note that ASG-backed resources (EKS managed node groups) do not
  # propagate default_tags to the instances they launch - those need explicit
  # tags on the node group itself.
  default_tags {
    tags = local.tags
  }
}

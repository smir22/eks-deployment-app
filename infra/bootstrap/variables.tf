variable "region" {
  description = "AWS region for every resource in this layer."
  type        = string
  default     = "eu-west-2"
}

variable "project" {
  description = "Project identifier. Feeds resource naming and the Project tag."
  type        = string
  default     = "eks-deployment-app"
}

variable "owner" {
  description = "Owning individual or team, for cost attribution."
  type        = string
  default     = "smir22"
}

variable "repository" {
  description = "Source repository, tagged onto resources so they can be traced back to code."
  type        = string
  default     = "github.com/smir22/eks-deployment-app"
}

variable "additional_tags" {
  description = <<-EOT
    Extra tags merged over the computed baseline in locals.tf. Keys set here win,
    so this can also override a baseline value for a one-off. Intended for
    ad-hoc or environment-specific tags that do not justify their own variable.
  EOT
  type        = map(string)
  default     = {}
}

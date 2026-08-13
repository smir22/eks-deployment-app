variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block, for example 10.0.0.0/16."
  }
}

variable "subnets" {
  description = <<-EOT
    Subnets to create, keyed by the suffix used in their Name tag. `public`
    drives three things at once: whether instances get a public IP, which EKS
    discovery tag is applied, and whether the subnet is associated with the
    public route table.
  EOT
  type = map(object({
    cidr_block        = string
    availability_zone = string
    public            = bool
  }))

  # Overlapping ranges are otherwise an apply-time InvalidSubnet.Conflict, and
  # only on the second subnet - the first is created and left behind. Catching
  # it at plan time is worth the four lines.
  validation {
    condition     = length(distinct([for s in var.subnets : s.cidr_block])) == length(var.subnets)
    error_message = "Every subnet must have a unique cidr_block."
  }

  validation {
    condition     = alltrue([for s in var.subnets : can(cidrhost(s.cidr_block, 0))])
    error_message = "Every subnet cidr_block must be a valid IPv4 CIDR block."
  }
}

variable "cluster_name" {
  description = <<-EOT
    Name of the EKS cluster these subnets serve. Used only for the
    kubernetes.io/cluster/<name> discovery tag - this module creates no cluster.
  EOT
  type        = string
}

variable "name_prefix" {
  description = <<-EOT
    Prefix for the Name tag on every resource here. The provider's default_tags
    covers Project, Environment and the rest, but not Name, which has to be set
    per resource.
  EOT
  type        = string
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr     = "10.0.0.0/16"
  cluster_name = local.cluster_name
  name_prefix  = local.name_prefix

  # /19 on the private subnets is sized for prefix delegation - the CNI hands out
  # a whole /28 per ENI slot, so a /24 runs out of addresses long before the node
  # runs out of capacity. The public subnets hold nothing but load balancer ENIs.
  subnets = {
    "private-2a" = { cidr_block = "10.0.0.0/19", availability_zone = "eu-west-2a", public = false }
    "private-2b" = { cidr_block = "10.0.32.0/19", availability_zone = "eu-west-2b", public = false }
    "private-2c" = { cidr_block = "10.0.64.0/19", availability_zone = "eu-west-2c", public = false }
    "public-2a"  = { cidr_block = "10.0.96.0/24", availability_zone = "eu-west-2a", public = true }
    "public-2b"  = { cidr_block = "10.0.97.0/24", availability_zone = "eu-west-2b", public = true }
    "public-2c"  = { cidr_block = "10.0.98.0/24", availability_zone = "eu-west-2c", public = true }
  }
}

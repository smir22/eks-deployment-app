# VPC

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  # Both are required by EKS. enable_dns_support defaults to true but is stated
  # here so the pair reads together; enable_dns_hostnames defaults to false, and
  # without it the interface endpoints and the cluster's private endpoint have
  # no resolvable names.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# Subnets

resource "aws_subnet" "main" {
  for_each = var.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  # The kubernetes.io tags are how the load balancer controller discovers where
  # it may place a load balancer. They are not optional and they fail silently:
  # the cluster comes up healthy and no load balancer is ever provisioned.
  tags = merge(
    {
      Name                                        = "${var.name_prefix}-${each.key}"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    },
    each.value.public
    ? { "kubernetes.io/role/elb" = "1" }
    : { "kubernetes.io/role/internal-elb" = "1" }
  )
}

# IGW + Regional NAT Gateway

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_nat_gateway" "main" {
  vpc_id            = aws_vpc.main.id
  availability_mode = "regional"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.name_prefix}-reg-nat"
  }
}


# Route Tables + Associations

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.name_prefix}-public"
  }
}

resource "aws_route_table_association" "public" {
  # Filtered rather than driven off a second variable, so the public/private
  # split is declared once in var.subnets and derived everywhere else.
  for_each = { for name, subnet in var.subnets : name => subnet if subnet.public }

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.main[each.key].id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {

    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.name_prefix}-private"
  }
}

resource "aws_route_table_association" "private" {
  # Filtered rather than driven off a second variable, so the public/private
  # split is declared once in var.subnets and derived everywhere else.
  for_each = { for name, subnet in var.subnets : name => subnet if !subnet.public }

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.main[each.key].id
}

# VPC Endpoint for S3

# Read off the inherited provider rather than taken as a variable, so the
# endpoint cannot end up pointing at a different region to the VPC it sits in.
data "aws_region" "current" {}

# No endpoint policy on purpose. ECR serves image layers out of S3 buckets that
# belong to AWS, not to this account, so a policy scoped to our own buckets
# would break every image pull.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.name_prefix}-s3-vpce"
  }
}

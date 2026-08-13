output "vpc_id" {
  description = "ID of the VPC. Needed by the cluster, every security group and every VPC endpoint."
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = <<-EOT
    IPv4 CIDR block of the VPC. Echoed back from the resource rather than from
    var.vpc_cidr so it reflects what AWS actually assigned. Used as the ingress
    source on the interface endpoint security groups.
  EOT
  value       = aws_vpc.main.cidr_block
}

# Both lists iterate var.subnets, which Terraform walks in sorted key order, so
# the IDs come out stable between plans. Building them off an unordered source
# would show up later as a node group perpetually rewriting its subnet list.

output "private_subnet_ids" {
  description = "IDs of the private subnets, for the cluster control plane ENIs and the node groups."
  value       = [for name, subnet in var.subnets : aws_subnet.main[name].id if !subnet.public]
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, for internet-facing load balancers."
  value       = [for name, subnet in var.subnets : aws_subnet.main[name].id if subnet.public]
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table."
  value       = aws_route_table.private.id
}

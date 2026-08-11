output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state for every layer."
  value       = aws_s3_bucket.tf_state.bucket
}

output "state_kms_key_arn" {
  description = "ARN of the KMS key encrypting Terraform state."
  value       = aws_kms_key.tf_state.arn
}

output "eks_secrets_kms_key_arn" {
  description = "ARN of the KMS key encrypting EKS Cluster secrets."
  value       = aws_kms_key.eks_cluster.arn
}

output "ecr_url" {
  description = "ECR Repo URL"
  value       = aws_ecr_repository.eks_ecr.repository_url
}

output "terraform_plan_role_arn" {
  description = "Role assumed by the plan-on-PR job in Pipeline 1."
  value       = aws_iam_role.terraform_plan.arn
}

output "terraform_apply_role_arn" {
  description = "Role assumed by the apply job in Pipeline 1, gated on the prod environment."
  value       = aws_iam_role.terraform_apply.arn
}

output "image_push_role_arn" {
  description = "Role assumed by the build-and-push job in Pipeline 2."
  value       = aws_iam_role.image_push.arn
}

output "workload_boundary_policy_arn" {
  description = "Permissions boundary that every IAM role created by the main layer must carry."
  value       = aws_iam_policy.workload_boundary.arn
}

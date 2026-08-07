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

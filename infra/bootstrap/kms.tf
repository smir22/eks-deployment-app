resource "aws_kms_key" "eks_cluster" {
  description             = "Envelope-encrypts Kubernetes Secrets in the EKS cluster's etcd."
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "eks_cluster" {
  name          = "alias/eks-cluster"
  target_key_id = aws_kms_key.eks_cluster.key_id
}

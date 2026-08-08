resource "aws_ecr_repository" "eks_ecr" {
  # checkov:skip=CKV_AWS_136: images hold no sensitive data, and a CMK would add a
  # kms:Decrypt dependency to every node image pull for no security gain.
  name                 = var.project
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "eks_ecr" {
  repository = aws_ecr_repository.eks_ecr.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain the 30 most recent sha-tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = { type = "expire" }
      }
    ]
  })
}

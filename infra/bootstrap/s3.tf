# Terraform state bucket and the key that encrypts it.

# The key lives here rather than in a shared kms.tf because it shares a lifecycle
# with this bucket and encrypts nothing else.

resource "aws_kms_key" "tf_state" {
  description             = "Encrypts Terraform state objects in the bootstrap state bucket"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "tf_state" {
  name          = "alias/eks-tf-state"
  target_key_id = aws_kms_key.tf_state.key_id
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "eks-deployment-state-s3-sm22"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tf_state.arn
    }
    bucket_key_enabled = true

    # SSE-C keys are not retained by S3, so an object written with one would be
    # permanently unreadable to us.
    blocked_encryption_types = ["SSE-C"]
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "tf_state" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    # Both ARNs are required: bucket-level actions such as ListBucket authorise
    # against the bucket itself, object-level actions against the objects. A
    # policy carrying only the /* form leaves bucket-level calls unprotected.
    resources = [
      aws_s3_bucket.tf_state.arn,
      "${aws_s3_bucket.tf_state.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyOutdatedTLS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.tf_state.arn,
      "${aws_s3_bucket.tf_state.arn}/*",
    ]

    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = ["1.2"]
    }
  }

  # The apply role runs the main layer and has no business reconfiguring the bucket
  # that holds its own state. Bootstrap is applied by hand, so nothing legitimate is
  # lost. Bucket-level actions only — the role must still read, write and lock state
  # objects, so the /* ARN is deliberately absent here.
  statement {
    sid    = "DenyBucketReconfiguration"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.terraform_apply.arn]
    }

    actions = [
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketAcl",
      "s3:PutBucketPolicy",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutLifecycleConfiguration",
    ]

    resources = [aws_s3_bucket.tf_state.arn]
  }
}

resource "aws_s3_bucket_policy" "tf_state" {
  bucket     = aws_s3_bucket.tf_state.id
  policy     = data.aws_iam_policy_document.tf_state.json
  depends_on = [aws_s3_bucket_public_access_block.tf_state]
}

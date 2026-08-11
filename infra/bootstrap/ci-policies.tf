# Permissions for the three GitHub Actions roles declared in oidc.tf, plus the
# boundary that caps every role the apply role is allowed to create.

locals {
  # Every IAM role the main layer creates must sit under this path. The apply role's
  # policy uses it to confine role mutation to the main layer's own roles.
  workload_role_path_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}/*"
}

# --- Boundary -----------------------------------------------------------------
# A boundary grants nothing. It is a ceiling: a role's effective permissions are
# its identity policy intersected with this. Denying iam:* here is what stops a
# role created by CI from creating another role.

data "aws_iam_policy_document" "workload_boundary" {
  # Checkov reads the Allow statement and stops; it does not evaluate the Deny
  # statements that follow, and a boundary grants nothing on its own in any case.
  # checkov:skip=CKV_AWS_1: a boundary is a ceiling, not a grant
  # checkov:skip=CKV_AWS_49: the wildcard is the point — Deny narrows it
  # checkov:skip=CKV_AWS_107: credentials exposure is closed by DenyIdentityAndAccountControl
  # checkov:skip=CKV_AWS_108: exfiltration paths are capped by the bounded role's own policy
  # checkov:skip=CKV_AWS_109: iam:* is denied outright
  # checkov:skip=CKV_AWS_110: escalation requires iam:*, which is denied outright
  # checkov:skip=CKV_AWS_111: intentional — the intersecting identity policy is the constraint
  # checkov:skip=CKV_AWS_356: intentional — see above
  statement {
    sid       = "AllowAllServices"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }

  statement {
    sid    = "DenyIdentityAndAccountControl"
    effect = "Deny"
    actions = [
      "account:*",
      "iam:*",
      "organizations:*",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "DenyTerraformState"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.tf_state.arn,
      "${aws_s3_bucket.tf_state.arn}/*",
    ]
  }

  statement {
    sid    = "DenyKeyDestruction"
    effect = "Deny"
    actions = [
      "kms:DisableKey",
      "kms:ScheduleKeyDeletion",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "workload_boundary" {
  name        = "eks-workload-boundary"
  description = "Maximum permissions any IAM role created by CI may hold."
  policy      = data.aws_iam_policy_document.workload_boundary.json
}

# --- Plan role ----------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "terraform_plan_readonly" {
  role       = aws_iam_role.terraform_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "terraform_plan_state" {
  # terraform plan takes a state lock, and with use_lockfile that means writing and
  # deleting a .tflock object. ReadOnlyAccess covers none of the writes, nor the
  # KMS data-plane calls needed to read the state itself.

  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tf_state.arn]
  }

  statement {
    sid    = "ReadStateAndHoldLock"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = ["${aws_s3_bucket.tf_state.arn}/*"]
  }

  statement {
    sid    = "UseStateKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = [aws_kms_key.tf_state.arn]
  }
}

resource "aws_iam_role_policy" "terraform_plan_state" {
  name   = "terraform-state-access"
  role   = aws_iam_role.terraform_plan.id
  policy = data.aws_iam_policy_document.terraform_plan_state.json
}

# --- Apply role ---------------------------------------------------------------

data "aws_iam_policy_document" "terraform_apply" {
  # Deliberate deny-list. Enumerating every API the main layer calls would still have
  # to include iam:CreateRole, so it needs the boundary condition regardless — the
  # allow-list buys nothing here and costs an edit per failed apply. Checkov does not
  # evaluate the Deny statements below.
  # checkov:skip=CKV_AWS_1: constrained by the Deny statements, not by the Allow
  # checkov:skip=CKV_AWS_49: intentional — Terraform's API surface is not enumerable
  # checkov:skip=CKV_AWS_107: DenyLongLivedCredentials blocks access-key creation
  # checkov:skip=CKV_AWS_108: single-account CI role; no cross-account trust exists
  # checkov:skip=CKV_AWS_109: role mutation is confined to the workload path
  # checkov:skip=CKV_AWS_110: DenyRoleCreationWithoutBoundary closes the escalation path
  # checkov:skip=CKV_AWS_111: intentional — see above
  # checkov:skip=CKV_AWS_356: intentional — see above
  statement {
    sid       = "AllowAllServices"
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
  }

  # iam:PermissionsBoundary is only populated for CreateRole, CreateUser and the
  # Put*PermissionsBoundary calls. A negated operator matches when its key is absent
  # from the request, so a CreateRole that supplies no boundary at all is denied.
  statement {
    sid       = "DenyRoleCreationWithoutBoundary"
    effect    = "Deny"
    actions   = ["iam:CreateRole"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values   = [aws_iam_policy.workload_boundary.arn]
    }
  }

  statement {
    sid    = "DenyBoundaryRemoval"
    effect = "Deny"
    actions = [
      "iam:DeleteRolePermissionsBoundary",
      "iam:PutRolePermissionsBoundary",
    ]
    resources = ["*"]
  }

  # Confines role mutation to the main layer's own path, so CI cannot re-point an
  # existing privileged role's trust policy at itself. Also covers the three
  # github-actions-* roles and anything else outside that path.
  statement {
    sid    = "DenyMutatingRolesOutsideWorkloadPath"
    effect = "Deny"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
    ]
    not_resources = [local.workload_role_path_arn]
  }

  # A boundary that the bounded principal can rewrite is not a boundary.
  statement {
    sid    = "DenyBoundaryTampering"
    effect = "Deny"
    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
    ]
    resources = [aws_iam_policy.workload_boundary.arn]
  }

  statement {
    sid    = "DenyFederationChanges"
    effect = "Deny"
    actions = [
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyLongLivedCredentials"
    effect = "Deny"
    actions = [
      "iam:CreateAccessKey",
      "iam:CreateLoginProfile",
      "iam:CreateUser",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "terraform_apply" {
  name   = "terraform-apply"
  role   = aws_iam_role.terraform_apply.id
  policy = data.aws_iam_policy_document.terraform_apply.json
}

# --- Image push role ----------------------------------------------------------

data "aws_iam_policy_document" "image_push" {
  # GetAuthorizationToken is an account-level endpoint with no repository ARN, so
  # it cannot be resource-scoped.
  statement {
    sid       = "AuthenticateToRegistry"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushAndScanImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [aws_ecr_repository.eks_ecr.arn]
  }
}

resource "aws_iam_role_policy" "image_push" {
  name   = "ecr-push"
  role   = aws_iam_role.image_push.id
  policy = data.aws_iam_policy_document.image_push.json
}

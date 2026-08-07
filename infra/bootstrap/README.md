# bootstrap

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.15.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.58.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.tf_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.tf_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.tf_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.tf_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.tf_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.tf_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.tf_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.tf_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Extra tags merged over the computed baseline in locals.tf. Keys set here win,<br/>so this can also override a baseline value for a one-off. Intended for<br/>ad-hoc or environment-specific tags that do not justify their own variable. | `map(string)` | `{}` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owning individual or team, for cost attribution. | `string` | `"smir22"` | no |
| <a name="input_project"></a> [project](#input\_project) | Project identifier. Feeds resource naming and the Project tag. | `string` | `"eks-deployment-app"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for every resource in this layer. | `string` | `"eu-west-2"` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | Source repository, tagged onto resources so they can be traced back to code. | `string` | `"github.com/smir22/eks-deployment-app"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_state_bucket_name"></a> [state\_bucket\_name](#output\_state\_bucket\_name) | Name of the S3 bucket holding Terraform state for every layer. |
| <a name="output_state_kms_key_arn"></a> [state\_kms\_key\_arn](#output\_state\_kms\_key\_arn) | ARN of the KMS key encrypting Terraform state. |
<!-- END_TF_DOCS -->

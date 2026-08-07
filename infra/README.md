# infra

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.15.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Extra tags merged over the computed baseline in locals.tf. Keys set here win,<br/>so this can also override a baseline value for a one-off. Intended for<br/>ad-hoc or environment-specific tags that do not justify their own variable. | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment. Feeds resource naming and the Environment tag. | `string` | `"dev"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owning individual or team, for cost attribution. | `string` | `"smir22"` | no |
| <a name="input_project"></a> [project](#input\_project) | Project identifier. Feeds resource naming and the Project tag. | `string` | `"eks-deployment-app"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for every resource in this layer. | `string` | `"eu-west-2"` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | Source repository, tagged onto resources so they can be traced back to code. | `string` | `"github.com/smir22/eks-deployment-app"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

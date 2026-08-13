# Committed deliberately - this holds only non-sensitive configuration so the
# layer is reproducible from the repository alone. Every other *.tfvars file is
# ignored by .gitignore; secrets belong in AWS Secrets Manager, never here.

region      = "eu-west-2"
project     = "eks-deployment-app"
environment = "dev"
owner       = "smir22"

# Merged over the baseline in locals.tf; keys here take precedence.
# additional_tags = {
#   CostCentre = "personal"
# }

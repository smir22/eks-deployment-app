# eks-deployment-app

Production-grade Kubernetes application on Amazon EKS, provisioned with Terraform
and delivered via GitOps. Region `eu-west-2`.

## Repository layout

```
infra/                Terraform
  bootstrap/          applied once by hand — state bucket, KMS, ECR, GitHub OIDC
  modules/            vpc, iam, eks
  *.tf                main layer, consumes the modules
app/                  static site + Dockerfile
gitops/               ArgoCD Applications and the app Helm chart
scripts/hooks/        optional local git hooks
.github/workflows/    CI — terraform plan/apply, build and deploy
```

The bootstrap layer is deliberately separate: it creates the state bucket the
main layer stores its state in, and holds a `data` reference to a pre-existing
Route53 hosted zone that Terraform must never own.

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Terraform | >= 1.10 | 1.10 introduced S3 native state locking (`use_lockfile`) |
| AWS CLI | v2 | credentials for the target account |
| pre-commit | >= 3.0 | manages its own hook environments |
| Docker | any | required by the `hadolint-docker` hook and image builds |
| kubectl / helm | current | cluster access once EKS is up |

`tflint`, `checkov`, `gitleaks`, and `terraform-docs` do **not** need to be
installed manually — pre-commit provisions them into isolated environments.

## Development setup

```bash
git clone https://github.com/smir22/eks-deployment-app
cd eks-deployment-app
pre-commit install
```

`pre-commit install` alone is enough: `default_install_hook_types` in
`.pre-commit-config.yaml` installs both the `pre-commit` and `commit-msg` hooks.

Run the whole suite manually at any time:

```bash
pre-commit run --all-files
```

### Hooks

| Hook | Scope | Purpose |
|---|---|---|
| `terraform_fmt` | `infra/**/*.tf` | canonical formatting |
| `terraform_validate` | `infra/**/*.tf` | config is internally consistent |
| `terraform_tflint` | `infra/**/*.tf` | provider-aware linting, recursive |
| `terraform_docs` | `infra/**/*.tf` | regenerates module READMEs from variables/outputs |
| `terraform_checkov` | `infra/**/*.tf` | IaC security policy |
| `gitleaks` | repo-wide | secret detection — intentionally unscoped |
| `hadolint-docker` | `app/**` Dockerfiles | Dockerfile linting |
| `conventional-pre-commit` | commit message | enforces the commit convention below |
| whitespace / YAML / JSON / private-key | repo-wide | general hygiene |

Terraform hooks are path-scoped to `infra/` so a `.tf` file elsewhere — a docs
example, a vendored chart — cannot trigger an init cycle. `gitleaks` is
deliberately left repo-wide, since a leaked secret matters wherever it lands.

Helm chart templates are excluded from `check-yaml`: they are Go templates, and
`{{ ... }}` is not valid YAML.

## Commit convention

[Conventional Commits](https://www.conventionalcommits.org/), enforced by a
`commit-msg` hook:

```
<type>(<scope>): <description> (#issue)
```

Types: `feat` `fix` `docs` `refactor` `chore` `ci` `test` `style` `perf` `build`
`revert`. Scope is the epic — `vpc`, `eks`, `bootstrap`, `argocd`, `ingress`,
`app`, `pipelines`, `docs`. Imperative mood, lowercase, no full stop, ~72 chars.

```
feat(vpc): add NAT gateway with single_nat_gateway toggle (#23)
fix(eks): correct subnet discovery tags for LB controller (#28)
```

PRs are squash-merged so `main` carries one clean commit per ticket.

### Optional: commit message drafting

`scripts/hooks/prepare-commit-msg` drafts a Conventional Commits subject line
from the staged diff using the [Claude CLI](https://claude.com/claude-code), and
pre-fills it into your editor. It is opt-in:

```bash
ln -sf ../../scripts/hooks/prepare-commit-msg .git/hooks/prepare-commit-msg
```

It only fires on a bare `git commit` — `git commit -m`, merges, squashes, and
amends are left untouched. `NO_AI_COMMIT=1 git commit` bypasses it for one
commit. The message is always pre-filled rather than applied, so you review and
edit before saving, and the `commit-msg` hook validates the result either way.
If the CLI is missing or returns anything malformed, the hook exits silently and
git behaves as though it were not installed.

## Terraform

```bash
terraform -chdir=infra init
terraform -chdir=infra plan
```

`.terraform.lock.hcl` is committed so provider versions are identical locally
and in CI.

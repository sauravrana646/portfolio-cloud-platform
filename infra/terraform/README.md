# Terraform

Default `deploy_target = local` creates **no** AWS resources (empty apply).

- `ecs` — VPC + ECS cluster skeleton (cheap path)
- `eks` — VPC + placeholder (do not apply without budget approval)

```bash
cd infra/terraform
terraform init
terraform validate
terraform plan -var='deploy_target=local'
# NEVER apply without explicit user approval
```

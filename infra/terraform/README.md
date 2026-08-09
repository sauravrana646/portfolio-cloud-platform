# Terraform — portfolio-cloud-platform

`deploy_target`:

| Value | Resources |
|-------|-----------|
| `local` (default) | None |
| `eks` | VPC (public+private, **no NAT by default**) + EKS + managed node group + OIDC/IRSA provider + add-ons |

**ECS is removed** from this pack.

```bash
cd infra/terraform
terraform init
terraform validate
terraform plan -var='deploy_target=local'
# Sandbox only, with approval:
# terraform plan -var='deploy_target=eks'
# terraform apply -var='deploy_target=eks'
# terraform destroy -var='deploy_target=eks'
```

## Cost (sandbox)

- EKS control plane ≈ $70–75/month if left up
- 1× `t3.medium` node ≈ $15–40/month
- **No NAT Gateway** in the default design (`eks_public_nodes=true`) to avoid ~$32+/month
- Destroy when the demo ends

Makefile `apply` refuses unattended applies.

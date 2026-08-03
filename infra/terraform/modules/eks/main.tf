variable "project" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

# Off by default. This is a placeholder so validate works when enable_eks=true.
# Prefer kind/k3d locally; do not apply without explicit budget approval.

resource "null_resource" "eks_placeholder" {
  triggers = {
    project = var.project
    vpc_id  = var.vpc_id
    subnets = join(",", var.private_subnet_ids)
  }
}

output "note" {
  value = "EKS module is a placeholder. Use local kind + Helm for demos; apply only with approval."
}

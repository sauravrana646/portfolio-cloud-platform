locals {
  enable_eks = var.deploy_target == "eks"
}

module "vpc" {
  source = "./modules/vpc"
  count  = local.enable_eks ? 1 : 0

  project      = var.project
  vpc_cidr     = var.vpc_cidr
  public_nodes = var.eks_public_nodes
}

module "eks" {
  source = "./modules/eks"
  count  = local.enable_eks ? 1 : 0

  project            = var.project
  vpc_id             = module.vpc[0].vpc_id
  private_subnet_ids = module.vpc[0].private_subnet_ids
  public_subnet_ids  = module.vpc[0].public_subnet_ids
  node_subnet_ids    = var.eks_public_nodes ? module.vpc[0].public_subnet_ids : module.vpc[0].private_subnet_ids
  cluster_subnet_ids = concat(module.vpc[0].private_subnet_ids, module.vpc[0].public_subnet_ids)
  node_instance_type = var.eks_node_instance_type
  desired_size       = var.eks_desired_size
  max_size           = var.eks_max_size
  min_size           = var.eks_min_size
  endpoint_public    = true
}

output "deploy_target" {
  value = var.deploy_target
}

output "note" {
  value = "Default deploy_target=local means no AWS resources. Use eks only with sandbox approval and destroy when done."
}

output "eks_cluster_name" {
  value = try(module.eks[0].cluster_name, null)
}

output "eks_cluster_endpoint" {
  value = try(module.eks[0].cluster_endpoint, null)
}

output "eks_oidc_provider_arn" {
  value = try(module.eks[0].oidc_provider_arn, null)
}

output "kubeconfig_command" {
  value = try(module.eks[0].kubeconfig_command, null)
}

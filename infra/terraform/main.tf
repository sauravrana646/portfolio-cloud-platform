locals {
  enable_cloud = var.deploy_target != "local"
  enable_ecs   = var.deploy_target == "ecs"
  enable_eks   = var.deploy_target == "eks"
}

module "vpc" {
  source = "./modules/vpc"
  count  = local.enable_cloud ? 1 : 0

  project  = var.project
  vpc_cidr = var.vpc_cidr
}

module "ecs" {
  source = "./modules/ecs"
  count  = local.enable_ecs ? 1 : 0

  project          = var.project
  vpc_id           = module.vpc[0].vpc_id
  private_subnet_ids = module.vpc[0].private_subnet_ids
}

module "eks" {
  source = "./modules/eks"
  count  = local.enable_eks ? 1 : 0

  project            = var.project
  vpc_id             = module.vpc[0].vpc_id
  private_subnet_ids = module.vpc[0].private_subnet_ids
}

output "deploy_target" {
  value = var.deploy_target
}

output "note" {
  value = "Default deploy_target=local means no AWS resources. Use ecs for cheap cloud; eks only with budget approval."
}

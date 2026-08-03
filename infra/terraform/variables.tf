variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "portfolio-cloud-platform"
}

variable "deploy_target" {
  type        = string
  description = "local | ecs | eks — cloud modules only for ecs/eks"
  default     = "local"
  validation {
    condition     = contains(["local", "ecs", "eks"], var.deploy_target)
    error_message = "deploy_target must be local, ecs, or eks."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

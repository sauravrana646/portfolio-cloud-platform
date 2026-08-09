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
  description = "local | eks — cloud modules only for eks (ECS removed)"
  default     = "local"
  validation {
    condition     = contains(["local", "eks"], var.deploy_target)
    error_message = "deploy_target must be local or eks."
  }
}

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "eks_node_instance_type" {
  type        = string
  description = "Sandbox node type — keep small"
  default     = "t3.medium"
}

variable "eks_desired_size" {
  type    = number
  default = 1
}

variable "eks_max_size" {
  type    = number
  default = 2
}

variable "eks_min_size" {
  type    = number
  default = 1
}

variable "eks_public_nodes" {
  type        = bool
  description = "If true, nodes in public subnets (no NAT) to cut sandbox cost"
  default     = true
}

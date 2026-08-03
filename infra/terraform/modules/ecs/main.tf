variable "project" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-cluster"
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  tags = { Name = "${var.project}-ecs" }
}

output "cluster_name" { value = aws_ecs_cluster.this.name }
output "note" {
  value = "Skeleton cluster only — wire task definitions after sandbox approval."
}

##################################################################################################################
# ECR registry
##################################################################################################################

resource "aws_ecr_repository" "ecr_repository" {
  name = "${var.swarm_name}_repository"
}

output "aws_ecr_repository_id" {
  value = "${aws_ecr_repository.ecr_repository.registry_id}"
}

output "aws_ecr_repository_name" {
  value = "${aws_ecr_repository.ecr_repository.name}"
}

##################################################################################################################
# ECS cluster
##################################################################################################################

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.swarm_name}_cluster"
}

output "aws_ecs_cluster_name" {
  value = "${aws_ecs_cluster.ecs_cluster.name}"
}

output "aws_ecs_cluster_id" {
  value = "${aws_ecs_cluster.ecs_cluster.id}"
}

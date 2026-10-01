variable "ecs_cluster_name" {
  description = "De naam van het ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "De naam van de ECS service"
  type        = string
}

variable "alb_arn_suffix" {
  description = "De ARN suffix van de Application Load Balancer"
  type        = string
}

variable "rds_cluster_identifier" {
  description = "De identifier van de RDS database"
  type        = string
}
output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "alb_zone_id" {
  value = aws_lb.web.zone_id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.web.name
}

output "ecs_service_name" {
  value = aws_ecs_service.web.name
}

output "alb_arn_suffix" {
  value = aws_lb.web.arn_suffix
}
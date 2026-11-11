output "flow_logs_log_group_name" {
  description = "CloudWatch Log Group naam voor AWS VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "vpc_id" {
  description = "VPC ID van Spoke 3 (Security)"
  value       = aws_vpc.security.id
}

output "subnet_id" {
  description = "Subnet ID van Spoke 3 (Security)"
  value       = aws_subnet.security.id
}

output "route_table_id" {
  description = "Route Table ID van Spoke 3 (Security)"
  value       = aws_route_table.security.id
}

output "private_ip" {
  description = "Private IP van de Security Stack (Shuffle / Loki / Prometheus / Grafana)"
  value       = aws_instance.sec_stack.private_ip
}

output "public_ip" {
  description = "Publiek IP voor directe toegang tot Grafana/Shuffle"
  value       = aws_instance.sec_stack.public_ip
}

output "security_group_id" {
  description = "Security Group ID van de Security Stack"
  value       = aws_security_group.security_stack.id
}

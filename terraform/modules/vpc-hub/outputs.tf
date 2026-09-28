output "vpc_id" {
  value = aws_vpc.hub.id
}

output "subnet_id" {
  value = aws_subnet.mgmt.id
}

output "route_table_id" {
  value = aws_route_table.mgmt.id
}
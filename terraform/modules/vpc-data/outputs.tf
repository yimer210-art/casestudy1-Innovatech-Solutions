output "vpc_id" {
  value = aws_vpc.data.id
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "subnet_ids" {
  value = [aws_subnet.db_a.id, aws_subnet.db_b.id]
}

output "main_route_table_id" {
  value = aws_vpc.data.main_route_table_id
}

output "rds_identifier" {
  value = aws_db_instance.postgres.identifier
}
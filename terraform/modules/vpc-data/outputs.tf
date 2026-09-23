output "vpc_id" {
  value = aws_vpc.data.id
}

output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}
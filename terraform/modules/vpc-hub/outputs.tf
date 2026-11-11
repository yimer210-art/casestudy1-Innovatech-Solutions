output "vpc_id" {
  value = aws_vpc.hub.id
}

output "subnet_id" {
  value = aws_subnet.mgmt.id
}

output "route_table_id" {
  value = aws_route_table.mgmt.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}

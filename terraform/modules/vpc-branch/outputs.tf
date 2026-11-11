output "vpc_id" {
  description = "VPC ID van Spoke 4 (Branch Office)"
  value       = aws_vpc.branch.id
}

output "subnet_id" {
  description = "Subnet ID van Spoke 4 (Branch Office)"
  value       = aws_subnet.branch.id
}

output "route_table_id" {
  description = "Route Table ID van Spoke 4 (Branch Office)"
  value       = aws_route_table.branch.id
}

output "workstation_private_ip" {
  description = "Private IP van Workstation 01 (192.168.56.10)"
  value       = aws_instance.workstation_01.private_ip
}

output "workstation_public_ip" {
  description = "Publiek IP van Workstation 01"
  value       = aws_instance.workstation_01.public_ip
}

output "branch_server_private_ip" {
  description = "Private IP van Branch Server 01 (192.168.56.20)"
  value       = aws_instance.branch_server_01.private_ip
}

output "branch_server_public_ip" {
  description = "Publiek IP van Branch Server 01"
  value       = aws_instance.branch_server_01.public_ip
}

output "attacker_private_ip" {
  description = "Private IP van Attacker Node (192.168.56.30)"
  value       = aws_instance.attacker_node.private_ip
}

output "attacker_public_ip" {
  description = "Publiek IP van Attacker Node"
  value       = aws_instance.attacker_node.public_ip
}

# ==========================================
# Beheer & Toegang Outputs
# ==========================================

output "bastion_public_ip" {
  description = "Publiek IP van de Bastion Host (Hub VPC)"
  value       = module.vpc_hub.bastion_public_ip
}

output "bastion_private_ip" {
  description = "Private IP van de Bastion Host"
  value       = module.vpc_hub.bastion_private_ip
}

output "security_public_ip" {
  description = "Publiek IP van de Security & Observability Server (Grafana / Shuffle)"
  value       = module.vpc_security.public_ip
}

output "security_private_ip" {
  description = "Private IP van de Security Stack (10.3.1.50)"
  value       = module.vpc_security.private_ip
}

output "grafana_url" {
  description = "Directe URL naar Grafana Dashboard"
  value       = "http://${module.vpc_security.public_ip}:3000"
}

output "shuffle_soar_url" {
  description = "Directe URL naar Shuffle SOAR Interface"
  value       = "https://${module.vpc_security.public_ip}:3443"
}

output "workstation_private_ip" {
  description = "Private IP van Workstation 01 (192.168.56.10)"
  value       = module.vpc_branch.workstation_private_ip
}

output "workstation_public_ip" {
  description = "Publiek IP van Workstation 01"
  value       = module.vpc_branch.workstation_public_ip
}

output "branch_server_private_ip" {
  description = "Private IP van Branch Server 01 (192.168.56.20)"
  value       = module.vpc_branch.branch_server_private_ip
}

output "branch_server_public_ip" {
  description = "Publiek IP van Branch Server 01"
  value       = module.vpc_branch.branch_server_public_ip
}

output "attacker_private_ip" {
  description = "Private IP van Attacker Node (192.168.56.30)"
  value       = module.vpc_branch.attacker_private_ip
}

output "attacker_public_ip" {
  description = "Publiek IP van Attacker Node"
  value       = module.vpc_branch.attacker_public_ip
}

output "route53_internal_zone_id" {
  description = "Route 53 Private Hosted Zone ID (innovatech.internal)"
  value       = module.dns.zone_id
}

output "zone_id" {
  description = "Route 53 Private Hosted Zone ID"
  value       = aws_route53_zone.internal.zone_id
}

output "name_servers" {
  description = "Name servers van de private zone"
  value       = aws_route53_zone.internal.name_servers
}

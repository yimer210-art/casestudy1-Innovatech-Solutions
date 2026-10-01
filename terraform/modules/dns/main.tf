/*
resource "aws_route53_record" "web" {
  zone_id = var.hosted_zone_id
  name    = "www.innovatech-tickets.nl"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
*/
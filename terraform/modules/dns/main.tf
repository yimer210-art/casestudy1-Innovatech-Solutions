resource "aws_route53_zone" "internal" {
  name    = "innovatech.internal"
  comment = "Innovatech Private Hosted Zone voor interne service discovery (REQ-04)"

  vpc {
    vpc_id = var.hub_vpc_id
  }

  tags = {
    Name = "innovatech-internal-dns"
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_zone_association" "web" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = var.web_vpc_id
}

resource "aws_route53_zone_association" "data" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = var.data_vpc_id
}

resource "aws_route53_zone_association" "security" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = var.security_vpc_id
}

resource "aws_route53_zone_association" "branch" {
  zone_id = aws_route53_zone.internal.zone_id
  vpc_id  = var.branch_vpc_id
}

# --- DNS Records voor Interne Diensten (REQ-04) ---

resource "aws_route53_record" "soar" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "soar.innovatech.internal"
  type    = "A"
  ttl     = 300
  records = [var.security_ip]
}

resource "aws_route53_record" "loki" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "loki.innovatech.internal"
  type    = "A"
  ttl     = 300
  records = [var.security_ip]
}

resource "aws_route53_record" "monitoring" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "monitoring.innovatech.internal"
  type    = "A"
  ttl     = 300
  records = [var.security_ip]
}

resource "aws_route53_record" "workstation_01" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "workstation-01.innovatech.internal"
  type    = "A"
  ttl     = 300
  records = [var.workstation_ip]
}

resource "aws_route53_record" "branch_server_01" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "branch-server-01.innovatech.internal"
  type    = "A"
  ttl     = 300
  records = [var.branch_server_ip]
}

resource "aws_route53_record" "attacker" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "attacker.innovatech.internal"
  type    = "A"
  ttl     = 300
  records = [var.attacker_ip]
}

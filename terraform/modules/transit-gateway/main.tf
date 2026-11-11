resource "aws_ec2_transit_gateway" "main" {
  description                     = "Innovatech hub-and-spoke"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  tags = { Name = "tgw-innovatech" }
}

# --- Attachments (één per VPC) ---

resource "aws_ec2_transit_gateway_vpc_attachment" "web" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.web_vpc_id
  subnet_ids         = var.web_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = { Name = "tgw-attach-web" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "data" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.data_vpc_id
  subnet_ids         = var.data_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = { Name = "tgw-attach-data" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.hub_vpc_id
  subnet_ids         = var.hub_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = { Name = "tgw-attach-hub" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "security" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.security_vpc_id
  subnet_ids         = var.security_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = { Name = "tgw-attach-security" }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "branch" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.branch_vpc_id
  subnet_ids         = var.branch_subnet_ids

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = { Name = "tgw-attach-branch" }
}

# --- Aparte route tables op de TGW (Segmentatie & Isolatie) ---

resource "aws_ec2_transit_gateway_route_table" "web" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags               = { Name = "tgw-rt-web" }
}

resource "aws_ec2_transit_gateway_route_table" "data" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags               = { Name = "tgw-rt-data" }
}

resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags               = { Name = "tgw-rt-hub" }
}

resource "aws_ec2_transit_gateway_route_table" "security" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags               = { Name = "tgw-rt-security" }
}

resource "aws_ec2_transit_gateway_route_table" "branch" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags               = { Name = "tgw-rt-branch" }
}

# --- Route Table Associations ---

resource "aws_ec2_transit_gateway_route_table_association" "web" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.web.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.web.id
}

resource "aws_ec2_transit_gateway_route_table_association" "data" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.data.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.data.id
}

resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route_table_association" "security" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security.id
}

resource "aws_ec2_transit_gateway_route_table_association" "branch" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.branch.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.branch.id
}

# --- Routes op de TGW ---

# Web RT
resource "aws_ec2_transit_gateway_route" "web_to_data" {
  destination_cidr_block         = var.data_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.data.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.web.id
}

resource "aws_ec2_transit_gateway_route" "web_to_security" {
  destination_cidr_block         = var.security_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.web.id
}

# Data RT
resource "aws_ec2_transit_gateway_route" "data_to_web" {
  destination_cidr_block         = var.web_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.web.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.data.id
}

resource "aws_ec2_transit_gateway_route" "data_to_hub" {
  destination_cidr_block         = var.hub_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.data.id
}

# REQ-07: Data VPC stuurt via TGW naar Security voor monitoring
resource "aws_ec2_transit_gateway_route" "data_to_security" {
  destination_cidr_block         = var.security_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.data.id
}

# Hub RT (Bastion / Ansible beheer naar alle spokes)
resource "aws_ec2_transit_gateway_route" "hub_to_data" {
  destination_cidr_block         = var.data_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.data.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route" "hub_to_web" {
  destination_cidr_block         = var.web_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.web.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route" "hub_to_security" {
  destination_cidr_block         = var.security_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route" "hub_to_branch" {
  destination_cidr_block         = var.branch_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.branch.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# Security RT
resource "aws_ec2_transit_gateway_route" "security_to_hub" {
  destination_cidr_block         = var.hub_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security.id
}

resource "aws_ec2_transit_gateway_route" "security_to_web" {
  destination_cidr_block         = var.web_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.web.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security.id
}

resource "aws_ec2_transit_gateway_route" "security_to_branch" {
  destination_cidr_block         = var.branch_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.branch.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security.id
}

# Branch RT
resource "aws_ec2_transit_gateway_route" "branch_to_security" {
  destination_cidr_block         = var.security_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.branch.id
}

resource "aws_ec2_transit_gateway_route" "branch_to_hub" {
  destination_cidr_block         = var.hub_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.branch.id
}

# --- Routes in de VPC's zelf: stuur verkeer naar de TGW ---

resource "aws_route" "web_to_data" {
  route_table_id         = var.web_route_table_id
  destination_cidr_block = var.data_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.web]
}

resource "aws_route" "web_to_security" {
  route_table_id         = var.web_route_table_id
  destination_cidr_block = var.security_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.web]
}

resource "aws_route" "hub_to_data" {
  route_table_id         = var.hub_route_table_id
  destination_cidr_block = var.data_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_to_security" {
  route_table_id         = var.hub_route_table_id
  destination_cidr_block = var.security_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "hub_to_branch" {
  route_table_id         = var.hub_route_table_id
  destination_cidr_block = var.branch_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.hub]
}

resource "aws_route" "data_to_web" {
  route_table_id         = var.data_route_table_id
  destination_cidr_block = var.web_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.data]
}

resource "aws_route" "data_to_hub" {
  route_table_id         = var.data_route_table_id
  destination_cidr_block = var.hub_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.data]
}

# REQ-07: Data VPC moet Security VPC kunnen bereiken (Prometheus scraping RDS metrics)
resource "aws_route" "data_to_security" {
  route_table_id         = var.data_route_table_id
  destination_cidr_block = var.security_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.data]
}

# Bastion (Hub) moet web-nodes kunnen bereiken voor beheer
resource "aws_route" "web_to_hub" {
  route_table_id         = var.web_route_table_id
  destination_cidr_block = var.hub_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.web]
}

resource "aws_route" "security_to_hub" {
  route_table_id         = var.security_route_table_id
  destination_cidr_block = var.hub_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.security]
}

resource "aws_route" "security_to_web" {
  route_table_id         = var.security_route_table_id
  destination_cidr_block = var.web_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.security]
}

resource "aws_route" "security_to_branch" {
  route_table_id         = var.security_route_table_id
  destination_cidr_block = var.branch_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.security]
}

resource "aws_route" "branch_to_hub" {
  route_table_id         = var.branch_route_table_id
  destination_cidr_block = var.hub_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.branch]
}

resource "aws_route" "branch_to_security" {
  route_table_id         = var.branch_route_table_id
  destination_cidr_block = var.security_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.branch]
}

resource "aws_vpc" "branch" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-branch"
  }
}

resource "aws_internet_gateway" "branch" {
  vpc_id = aws_vpc.branch.id

  tags = {
    Name = "igw-branch"
  }
}

resource "aws_subnet" "branch" {
  vpc_id                  = aws_vpc.branch.id
  cidr_block              = "192.168.56.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-branch-lan"
  }
}

resource "aws_route_table" "branch" {
  vpc_id = aws_vpc.branch.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.branch.id
  }

  tags = {
    Name = "rt-branch-lan"
  }
}

resource "aws_route_table_association" "branch" {
  subnet_id      = aws_subnet.branch.id
  route_table_id = aws_route_table.branch.id
}

# --- Security Group voor Branch Office Nodes ---
resource "aws_security_group" "branch" {
  name        = "branch-nodes-sg"
  description = "Toegang tot filiaal nodes voor Ansible, SOAR mitigatie en monitoring"
  vpc_id      = aws_vpc.branch.id

  # SSH beheer vanaf Admin, Hub Bastion (Ansible), Security VPC (SOAR) en intern Branch LAN (lateral movement detectie)
  ingress {
    description = "SSH Beheer en SOAR Active Response"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr, var.hub_cidr, var.security_cidr, aws_vpc.branch.cidr_block]
  }

  # Node Exporter voor Prometheus monitoring (Poort 9100)
  ingress {
    description = "Prometheus Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.security_cidr]
  }

  # ICMP (Ping)
  ingress {
    description = "ICMP Ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8", "192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "branch-nodes-sg"
  }
}

# --- Ubuntu 22.04 LTS AMI Data Source ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Workstation 01: Doelwit voor SOAR brute force mitigatie & Ansible ---
resource "aws_instance" "workstation_01" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.branch.id
  private_ip                  = "192.168.56.10"
  vpc_security_group_ids      = [aws_security_group.branch.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3 python3-pip curl git fail2ban
              # Zorg dat auth logging direct klaar staat voor Promtail & SOAR tests
              touch /var/log/auth.log
              chmod 644 /var/log/auth.log
              EOF

  tags = {
    Name      = "workstation-01"
    Role      = "Branch-Workstation"
    Monitored = "true"
  }
}

# --- Branch Server 01: Tweede node voor Ansible multi-node updates ---
resource "aws_instance" "branch_server_01" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.branch.id
  private_ip                  = "192.168.56.20"
  vpc_security_group_ids      = [aws_security_group.branch.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3 python3-pip curl git
              EOF

  tags = {
    Name = "branch-server-01"
    Role = "Branch-Server"
  }
}

# --- Attacker Node: Dedicated Red-Team / Simulatie Node voor SOAR Validatie ---
resource "aws_instance" "attacker_node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.branch.id
  private_ip                  = "192.168.56.30"
  vpc_security_group_ids      = [aws_security_group.branch.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname attacker-node
              apt-get update -y
              apt-get install -y nmap hydra netcat-openbsd curl iputils-ping python3
              EOF

  tags = {
    Name = "attacker-node"
    Role = "RedTeam-Attacker"
  }
}

resource "aws_vpc" "hub" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "vpc-hub" }
}

resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id
  tags   = { Name = "igw-hub" }
}

resource "aws_subnet" "mgmt" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.2.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = { Name = "subnet-mgmt-a" }
}

resource "aws_route_table" "mgmt" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub.id
  }

  tags = { Name = "rt-mgmt-hub" }
}

resource "aws_route_table_association" "mgmt" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.mgmt.id
}

resource "aws_security_group" "bastion" {
  name   = "bastion-hub-sg"
  vpc_id = aws_vpc.hub.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion-hub-sg" }
}

resource "aws_key_pair" "bastion" {
  key_name   = "bastion-key"
  public_key = var.bastion_public_key
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.mgmt.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.bastion.key_name

  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  tags = { Name = "bastion-hub" }
}

# --- NIEUWE IAM BLOKKEN VOOR DE CI/CD RUNNER ---

# 1. De IAM rol die de Bastion (EC2) mag aannemen
resource "aws_iam_role" "bastion_runner_role" {
  name = "bastion-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. De rechten voor de rol (AdministratorAccess voor Terraform)
resource "aws_iam_role_policy_attachment" "bastion_admin" {
  role       = aws_iam_role.bastion_runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 3. Het profiel dat we aan de EC2 instance hangen
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-runner-profile"
  role = aws_iam_role.bastion_runner_role.name
}
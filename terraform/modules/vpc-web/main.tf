resource "aws_vpc" "web" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-web"
  }
}

resource "aws_internet_gateway" "web" {
  vpc_id = aws_vpc.web.id

  tags = {
    Name = "igw-web"
  }
}

# --- Subnets AZ A ---

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.web.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-public-a"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.web.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "subnet-private-a"
  }
}

# --- Subnets AZ B ---

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.web.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-public-b"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.web.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "subnet-private-b"
  }
}

# --- NAT Gateway (in publiek subnet AZ A) ---

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "eip-nat-web"
  }
}

resource "aws_nat_gateway" "web" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "nat-web"
  }

  depends_on = [aws_internet_gateway.web]
}

# --- Route tables ---

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.web.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.web.id
  }

  tags = {
    Name = "rt-public-web"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.web.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.web.id
  }

  tags = {
    Name = "rt-private-web"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
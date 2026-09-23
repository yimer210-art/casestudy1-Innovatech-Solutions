resource "aws_vpc" "data" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-data"
  }
}

# --- Private subnets voor de database, over 2 AZ's ---

resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.data.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "subnet-db-a"
  }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.data.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "subnet-db-b"
  }
}

resource "aws_db_subnet_group" "data" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_b.id]

  tags = {
    Name = "db-subnet-group"
  }
}

# --- Security Group: alleen 5432 vanaf de ECS-tasks ---

resource "aws_security_group" "rds" {
  name   = "rds-data-sg"
  vpc_id = aws_vpc.data.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # CIDR van vpc-web
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-data-sg"
  }
}

# --- RDS PostgreSQL, Multi-AZ ---

resource "aws_db_instance" "postgres" {
  identifier             = "innovatech-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "innovatech"
  username               = "dbadmin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.data.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = true
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = "innovatech-db"
  }
}
# ═══════════════════════════════════════════
# PROVIDER
# ═══════════════════════════════════════════

provider "aws" {
  region = var.aws_region
}

# ═══════════════════════════════════════════
# VPC
# ═══════════════════════════════════════════

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
    Type = "public"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "ap-south-1a"

  tags = {
    Name = "${var.project_name}-private-subnet-1a"
    Type = "private"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "ap-south-1b"

  tags = {
    Name = "${var.project_name}-private-subnet-1b"
    Type = "private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ═══════════════════════════════════════════
# SECURITY GROUPS
# ═══════════════════════════════════════════

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow MySQL from EC2 SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EC2 SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# ═══════════════════════════════════════════
# DB SUBNET GROUP
# ═══════════════════════════════════════════

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ═══════════════════════════════════════════
# RDS MySQL INSTANCE
# ═══════════════════════════════════════════

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "hcadb"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az            = false
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name = "${var.project_name}-mysql"
  }
}

# ═══════════════════════════════════════════
# TEST EC2
# ═══════════════════════════════════════════

resource "aws_instance" "test_ec2" {
  ami                    = "ami-0fa52f1a01deb1658"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.lab_key.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y mysql-client
  EOF

  tags = {
    Name = "${var.project_name}-test-ec2"
  }
}

# ═══════════════════════════════════════════
# SSH KEY PAIR
# ═══════════════════════════════════════════

resource "aws_key_pair" "lab_key" {
  key_name   = "rds-lab-key"
  public_key = file("~/.ssh/hca-web-key.pub")

  tags = {
    Name = "rds-lab-key"
  }
}

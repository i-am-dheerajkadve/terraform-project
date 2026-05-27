provider "aws" {
  region = var.region
}

# ---------------- VPC ----------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project-vpc"
  }
}

# ---------------- Internet Gateway ----------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# ---------------- Public Subnet ----------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "public-subnet"
  }
}

# ---------------- Private Subnet ----------------

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private-subnet"
  }
}

# ---------------- Route Table ----------------

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------- Security Group ----------------

resource "aws_security_group" "project_sg" {
  name   = "project-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------- DB Subnet Group ----------------

resource "aws_db_subnet_group" "db_subnet" {
  name = "db-subnet-group"

  subnet_ids = [
    aws_subnet.private.id
  ]
}

# ---------------- RDS PostgreSQL ----------------

resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"

  db_name              = "appdb"

  username             = var.db_username
  password             = var.db_password

  publicly_accessible  = false
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.project_sg.id]

  db_subnet_group_name = aws_db_subnet_group.db_subnet.name
}

# ---------------- User Data ----------------



# ---------------- EC2 ----------------
resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform-key"
  public_key = file("${path.module}/terraform-key")
}

resource "aws_instance" "app_server" {

  ami                    = var.ami
  instance_type          = var.instance_type

  subnet_id              = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.project_sg.id]

  key_name = aws_key_pair.terraform_key.key_name

  associate_public_ip_address = true

#   user_data = replace(
#   file("userdata.sh"),
#   "RDS_ENDPOINT",
#   aws_db_instance.postgres.address
#)

  tags = {
    Name = "docker-server"
  }
}

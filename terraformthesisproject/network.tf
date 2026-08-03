# network.tf

# 1. THE VPC (The House)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16" # Allocates 65,536 IP addresses
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-VPC"
  }
}

# 2. THE INTERNET GATEWAY (The Front Door)
# This allows public subnets to talk to the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}

# 3. PUBLIC SUBNETS (The Living Room - Accessible by Guests)
# We need two for High Availability (e.g., eu-north-1a and eu-north-1b)

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true # Instances here get a public IP automatically

  tags = {
    Name = "${var.project_name}-Public-Subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-Public-Subnet-2"
  }
}

# 4. PRIVATE SUBNETS (The Bedroom - Private, Secure)
# Servers here (App & DB) have NO direct internet access.

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "${var.project_name}-Private-Subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "${var.project_name}-Private-Subnet-2"
  }
}

# 5. ROUTING (The Hallways)
# We need to tell the Public Subnets how to find the Internet Gateway.

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Represents "The entire internet"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-Public-RouteTable"
  }
}

# Associate the Route Table with the Public Subnets
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}
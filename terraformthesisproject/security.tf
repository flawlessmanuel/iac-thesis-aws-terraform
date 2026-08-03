# security.tf

# 1. WEB SECURITY GROUP (Public Layer)
# Allows users to access the website via HTTP/HTTPS
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-Web-SG"
  description = "Allow HTTP and SSH traffic from internet"
  vpc_id      = aws_vpc.main.id

  # INBOUND RULES (Ingress)
  
  # Allow HTTP (Port 80) from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    description = "Allow HTTP traffic"
  }

  # Allow HTTPS (Port 443) from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic"
  }

  # Allow SSH (Port 22) - restricted to a single trusted IP via variable
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
    description = "Allow SSH access from a trusted IP only"
  }

  # OUTBOUND RULES (Egress)
  # Allow the server to reach the internet (e.g., to download updates)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # "-1" means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-Web-SG"
  }
}

# 2. APPLICATION SECURITY GROUP (Private Layer)
# Only allows traffic from the Web Security Group (Chaining)
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-App-SG"
  description = "Allow traffic only from Web Tier"
  vpc_id      = aws_vpc.main.id

  # INBOUND RULES
  
  # Allow HTTP traffic from the Web Servers ONLY
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # Reference the ID of the Web SG
    description     = "Allow traffic from Web Layer"
  }

  # Allow SSH from the Web Servers (Bastion Host concept)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
    description     = "Allow SSH from Web Layer"
  }

  # OUTBOUND RULES
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-App-SG"
  }
}
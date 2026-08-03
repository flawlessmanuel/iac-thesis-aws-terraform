# database.tf

# 1. SUBNET GROUP (The Location)
# We need to tell RDS which subnets it is allowed to use.
resource "aws_db_subnet_group" "default" {
  name       = lower("${var.project_name}-db-subnet-group")
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.project_name}-DB-Subnet-Group"
  }
}

# 2. THE DATABASE INSTANCE (The Engine)
resource "aws_db_instance" "default" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" # Free Tier eligible
  db_name                = "thesis_db"
  username               = "admin"
  password               = var.db_password # Sourced from a sensitive variable, never hardcoded
  parameter_group_name   = "default.mysql8.0"
  storage_encrypted      = true # Encrypts data at rest (AWS-managed KMS key)

  # Network Settings
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.app_sg.id] # Only allow App SG traffic
  publicly_accessible    = false                            # SECURITY: No public internet access
  
  # Thesis Settings (Makes deletion faster/cheaper)
  skip_final_snapshot    = true
  delete_automated_backups = true

  tags = {
    Name = "${var.project_name}-RDS"
  }
}
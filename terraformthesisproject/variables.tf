# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy infrastructure"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Name of the project for tagging"
  type        = string
  default     = "Thesis-Project"
}

variable "vpc_cidr" {
  description = "The IP range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_password" {
  description = "Master password for the RDS instance. Provide via terraform.tfvars (gitignored) or TF_VAR_db_password env var. Never commit a real value."
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the web tier. Set this to YOUR_PUBLIC_IP/32, never 0.0.0.0/0."
  type        = string
}
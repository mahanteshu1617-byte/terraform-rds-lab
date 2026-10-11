variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "project_name" {
  description = "project name"
  type        = string
  default     = "rds-lab"
}

variable "vpc_cidr" {
  description = "VPC cidr"
  type        = string
  default     = "10.50.0.0/16"
}

variable "public_subnet_cidr" {
  description = "public subnet cidr"
  type        = string
  default     = "10.50.1.0/24"
}

variable "private_subnet_1_cidr" {
  description = "private subent1  cidr for(AZ-a for rds)"
  type        = string
  default     = "10.50.11.0/24"
}

variable "private_subnet_2_cidr" {
  description = "private subent 2 cidr for(AZ-b for rds)"
  type        = string
  default     = "10.50.12.0/24"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS master password (min 8 chars)"
  type        = string
  sensitive   = true
  default     = "ChangeMe2026!"
}

variable "my_ip_cidr" {
  description = "Your public IP for SSH"
  type        = string
  default     = "103.211.17.161/32"
}

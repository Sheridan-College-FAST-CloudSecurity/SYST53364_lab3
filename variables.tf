variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
  default     = "vpc-0b45abe1f37c68aea"
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-0c02fb55956c7d316"  # Amazon Linux 2
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "Minimum instances"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired instances"
  type        = number
  default     = 2
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "lab3db"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "backup_retention_period" {
  description = "Backup retention days"
  type        = number
  default     = 7
}

variable "storage_type" {
  description = "Storage type"
  type        = string
  default     = "gp2"
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "create_replica" {
  description = "Create read replica"
  type        = bool
  default     = false  # Set to false to save costs
}

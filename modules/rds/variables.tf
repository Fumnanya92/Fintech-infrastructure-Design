variable "allocated_storage" {
  type        = number
  description = "The allocated storage for the RDS instance in GB"
  default     = 20
}

variable "engine_version" {
  type        = string
  description = "The MySQL engine version for the RDS instance"
  default     = "8.0"
}

variable "instance_class" {
  type        = string
  description = "The instance class for the RDS instance"
  default     = "db.t3.micro"
}

#variable "db_username" {
 # type        = string
 # description = "The master username for the RDS instance"
#}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Allowed CIDR blocks for access to RDS"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for RDS deployment"
}

variable "db_name" {
  description = "The database name for WordPress"
  type        = string
  default     = "wordpress_db"
}

variable "db_username" {
  description = "The master username for the RDS instance"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "The master password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "The VPC ID where the RDS instance will be deployed"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to resources"
  type        = string
}
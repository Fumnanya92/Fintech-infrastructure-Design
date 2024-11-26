variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2"
  type        = string
  default     = "10.0.4.0/24"
}

variable "availability_zone_1" {
  description = "First availability zone"
  type        = string
  default     = "us-west-2a"
}

variable "availability_zone_2" {
  description = "Second availability zone"
  type        = string
  default     = "us-west-2b"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access EFS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_username" {
  description = "The master username for the RDS instance"
  type        = string

}

variable "db_password" {
  description = "The master password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment for the project (e.g., Production, Staging)"
  type        = string
  default     = "Production"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "iam_group_name" {
  description = "IAM group name for policy attachment"
  type        = string
}

variable "iam_user_name" {
  description = "IAM user name"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment for the S3 bucket"
  type        = string
  default     = "Production"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-2" # Replace with your default region if applicable
}

variable "iam_group_name" {
  description = "IAM group name for policy attachment"
  type        = string
}

variable "iam_user_name" {
  description = "IAM user name"
  type        = string
}

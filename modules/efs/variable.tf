variable "subnet_ids" {
  description = "List of private subnet IDs for the EFS mount targets"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the EFS will be created"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to resources"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access EFS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
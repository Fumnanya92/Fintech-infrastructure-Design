variable "vpc_id" {
  description = "VPC ID for the load balancer"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnets for the ALB"
  type        = list(string)
}
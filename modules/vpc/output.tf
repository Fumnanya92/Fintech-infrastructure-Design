output "vpc_id" {
  value = aws_vpc.fintech_vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.fintech_vpc.cidr_block
}

output "private_subnet_ids" {
  value = [aws_subnet.private_subnet_1.id, 
    aws_subnet.private_subnet_2.id]
}

output "public_subnet_1_id" {
    value = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
    value = aws_subnet.public_subnet_2.id
}


output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

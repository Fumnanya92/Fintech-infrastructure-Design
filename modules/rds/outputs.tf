output "rds_endpoint" {
  value = aws_db_instance.fintech_rds.endpoint
  description = "RDS instance endpoint"
}
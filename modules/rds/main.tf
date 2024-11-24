resource "aws_db_instance" "fintech_rds" {
  allocated_storage      = var.allocated_storage
  engine                 = "mysql"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = false

  # Enable encryption at rest
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_kms_key.arn

  # Attach the security group and subnet group
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
}

resource "aws_kms_key" "rds_kms_key" {
  description             = "KMS key for encrypting RDS instance"
  deletion_window_in_days = 7
}

resource "aws_db_subnet_group" "rds_subnet" {
  name        = "rds-subnet-group"
  description = "Subnet group for RDS instance"
  subnet_ids  = var.private_subnet_ids
}

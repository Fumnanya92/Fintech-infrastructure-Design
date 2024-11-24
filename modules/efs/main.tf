# EFS file system with encryption at rest
resource "aws_efs_file_system" "efs" {
  encrypted    = true
  kms_key_id   = aws_kms_key.efs_kms_key.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "fintech-efs"
  }
}

# KMS key for EFS encryption
resource "aws_kms_key" "efs_kms_key" {
  description             = "KMS key for encrypting EFS file system"
  deletion_window_in_days = 7
}

# EFS Mount Target for each private subnet
resource "aws_efs_mount_target" "efs_mount_target" {
  count            = length(var.subnet_ids)
  file_system_id   = aws_efs_file_system.efs.id
  subnet_id        = var.subnet_ids[count.index]
  security_groups  = [var.security_group_id]
}

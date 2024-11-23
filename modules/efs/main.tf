# EFS file system
resource "aws_efs_file_system" "efs" {
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "fintech-efs"
  }
}

# EFS Mount Target for each private subnet
resource "aws_efs_mount_target" "efs_mount_target" {
  count       = length(var.subnet_ids)
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = var.subnet_ids[count.index]
  security_groups = [var.security_group_id]
}
output "efs_id" {
  description = "EFS File System ID"
  value       = aws_efs_file_system.efs.id
}
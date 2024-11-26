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

##########################
# EFS IAM Role (if needed)
##########################
resource "aws_iam_role" "efs_role" {
  name = "efs-fintech-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "elasticfilesystem.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Environment = "Production"
    Project     = "FinTech-Infrastructure"
  }
}

resource "aws_iam_policy" "ec2_efs_access" {
  name        = "EC2-EFS-Access-Policy"
  description = "Allows EC2 instances to interact with EFS"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "elasticfilesystem:DescribeFileSystems"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "elasticfilesystem:ClientMount"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


# Attach AWS Managed Policy for EFS Access
resource "aws_iam_role_policy_attachment" "efs_role_policy_attachment" {
  role       = aws_iam_role.efs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
}
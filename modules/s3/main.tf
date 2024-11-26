resource "aws_s3_bucket" "fintech_bucket" {
  bucket        = var.s3_bucket_name
  force_destroy = true

  tags = {
    Name        = var.s3_bucket_name
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_policy" "mfa_enforcement" {
  name        = "MFA-Enforcement-Policy"
  description = "Requires MFA for all IAM users"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Deny",
        Action   = "*",
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "mfa_enforcement_attachment" {
  group      = var.iam_group_name # Replace hardcoded "admin" with a variable
  policy_arn = aws_iam_policy.mfa_enforcement.arn
}

resource "aws_iam_user" "fintech_user" {
  name = var.iam_user_name

  tags = {
    Name        = "fintech-user"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_user_policy_attachment" "fintech_user_s3_access" {
  user       = aws_iam_user.fintech_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_s3_bucket_policy" "combined_policy" {
  bucket = aws_s3_bucket.fintech_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowIAMUserAccess",
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
        Principal = {
          AWS = aws_iam_user.fintech_user.arn
        },
        Resource = [
          aws_s3_bucket.fintech_bucket.arn,
          "${aws_s3_bucket.fintech_bucket.arn}/*"
        ]
      },
      {
        Sid       = "AWSCloudTrailAclCheck20131101",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = aws_s3_bucket.fintech_bucket.arn
      },
      {
        Sid       = "AWSCloudTrailWrite20131101",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "${aws_s3_bucket.fintech_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

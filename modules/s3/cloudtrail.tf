resource "aws_cloudtrail" "fintech_trail" {
  name                          = "fintech-trail"
  s3_bucket_name                = var.s3_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_logging.arn
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.fintech_log_group.arn

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "fintech_log_group" {
  name              = "/aws/cloudtrail/fintech-log-group"
  retention_in_days = 90
}

resource "aws_cloudwatch_log_subscription_filter" "fintech_filter" {
  name             = "fintech-subscription-filter"
  log_group_name   = aws_cloudwatch_log_group.fintech_log_group.name
  filter_pattern   = "[timestamp=*Z, request_id=\"*-*\", event]"
  destination_arn  = aws_cloudwatch_log_destination.fintech_log_destination.arn
}

resource "aws_cloudwatch_log_destination" "fintech_log_destination" {
  name       = "fintech-cloudwatch-destination"
  target_arn = "arn:aws:kinesis:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stream/your-stream"
  role_arn   = aws_iam_role.cloudtrail_logging.arn
}

resource "aws_iam_role" "cloudtrail_logging" {
  name = "CloudTrail_Logging_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_logging_policy" {
  role = aws_iam_role.cloudtrail_logging.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = aws_cloudwatch_log_group.fintech_log_group.arn
      }
    ]
  })
}

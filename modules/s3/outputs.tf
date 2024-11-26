output "s3_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.fintech_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.fintech_bucket.arn
}
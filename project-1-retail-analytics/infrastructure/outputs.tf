# ============================================================================
# Outputs - Important values you'll need
# ============================================================================

output "raw_data_bucket_name" {
  description = "Name of the raw data S3 bucket (Bronze layer)"
  value       = aws_s3_bucket.raw_data.id
}

output "raw_data_bucket_arn" {
  description = "ARN of the raw data S3 bucket"
  value       = aws_s3_bucket.raw_data.arn
}

output "processed_data_bucket_name" {
  description = "Name of the processed data S3 bucket (Silver layer)"
  value       = aws_s3_bucket.processed_data.id
}

output "processed_data_bucket_arn" {
  description = "ARN of the processed data S3 bucket"
  value       = aws_s3_bucket.processed_data.arn
}

output "analytics_data_bucket_name" {
  description = "Name of the analytics data S3 bucket (Gold layer)"
  value       = aws_s3_bucket.analytics_data.id
}

output "analytics_data_bucket_arn" {
  description = "ARN of the analytics data S3 bucket"
  value       = aws_s3_bucket.analytics_data.arn
}

output "archive_bucket_name" {
  description = "Name of the archive S3 bucket"
  value       = aws_s3_bucket.archive.id
}

output "snowflake_role_arn" {
  description = "ARN of the IAM role for Snowflake access (use this in Snowflake storage integration)"
  value       = aws_iam_role.snowflake_role.arn
}

output "pipeline_user_name" {
  description = "Name of the IAM user for pipeline operations"
  value       = aws_iam_user.data_pipeline_user.name
}

output "pipeline_user_arn" {
  description = "ARN of the IAM user for pipeline operations"
  value       = aws_iam_user.data_pipeline_user.arn
}

output "pipeline_user_access_key_id" {
  description = "Access key ID for pipeline user (save this securely!)"
  value       = aws_iam_access_key.pipeline_user_key.id
  sensitive   = false
}

output "pipeline_user_secret_access_key" {
  description = "Secret access key for pipeline user (save this immediately, you won't see it again!)"
  value       = aws_iam_access_key.pipeline_user_key.secret
  sensitive   = true
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

# Instructions for next steps
output "next_steps" {
  description = "What to do next"
  value = <<-EOT
    
    ✅ Infrastructure deployed successfully!
    
    📝 SAVE THESE CREDENTIALS:
    - Pipeline User Access Key: ${aws_iam_access_key.pipeline_user_key.id}
    - Pipeline User Secret Key: Run 'terraform output pipeline_user_secret_access_key' to see it
    
    📦 YOUR S3 BUCKETS:
    - Raw Data (Bronze): ${aws_s3_bucket.raw_data.id}
    - Processed Data (Silver): ${aws_s3_bucket.processed_data.id}
    - Analytics Data (Gold): ${aws_s3_bucket.analytics_data.id}
    - Archive: ${aws_s3_bucket.archive.id}
    
    🔐 SNOWFLAKE INTEGRATION:
    - Role ARN: ${aws_iam_role.snowflake_role.arn}
    - Use this ARN when creating Snowflake storage integration
    
    🚀 NEXT STEPS:
    1. Save the secret access key: terraform output -raw pipeline_user_secret_access_key
    2. Test S3 upload: aws s3 cp test.txt s3://${aws_s3_bucket.raw_data.id}/test/
    3. Create Snowflake storage integration using the Role ARN
    4. Update snowflake_external_id variable after creating integration
    
  EOT
}

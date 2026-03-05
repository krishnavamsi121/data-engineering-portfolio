# ============================================================================
# S3 Buckets for Data Lake
# ============================================================================

# Raw Data Bucket (Bronze Layer)
resource "aws_s3_bucket" "raw_data" {
  bucket = "${var.project_name}-raw-${var.unique_suffix}"

  tags = {
    Name        = "Raw Data Bucket"
    Layer       = "Bronze"
    Description = "Landing zone for raw data from various sources"
  }
}

resource "aws_s3_bucket_versioning" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  rule {
    id     = "transition-old-data"
    status = "Enabled"

    transition {
      days          = var.lifecycle_transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.lifecycle_expiration_days
    }
  }
}

# Processed Data Bucket (Silver Layer)
resource "aws_s3_bucket" "processed_data" {
  bucket = "${var.project_name}-processed-${var.unique_suffix}"

  tags = {
    Name        = "Processed Data Bucket"
    Layer       = "Silver"
    Description = "Cleaned and validated data"
  }
}

resource "aws_s3_bucket_versioning" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Analytics Data Bucket (Gold Layer)
resource "aws_s3_bucket" "analytics_data" {
  bucket = "${var.project_name}-analytics-${var.unique_suffix}"

  tags = {
    Name        = "Analytics Data Bucket"
    Layer       = "Gold"
    Description = "Business-ready analytics data"
  }
}

resource "aws_s3_bucket_versioning" "analytics_data" {
  bucket = aws_s3_bucket.analytics_data.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "analytics_data" {
  bucket = aws_s3_bucket.analytics_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Archive Bucket for backups
resource "aws_s3_bucket" "archive" {
  bucket = "${var.project_name}-archive-${var.unique_suffix}"

  tags = {
    Name        = "Archive Bucket"
    Description = "Long-term archive and backups"
  }
}

resource "aws_s3_bucket_versioning" "archive" {
  bucket = aws_s3_bucket.archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "archive" {
  bucket = aws_s3_bucket.archive.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ============================================================================
# IAM Role for Snowflake to access S3
# ============================================================================

resource "aws_iam_role" "snowflake_role" {
  name = var.snowflake_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.snowflake_user_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.snowflake_external_id
          }
        }
      }
    ]
  })

  tags = {
    Name        = "Snowflake S3 Access Role"
    Description = "Role for Snowflake to access S3 buckets"
  }
}

# IAM Policy for S3 access
resource "aws_iam_policy" "snowflake_s3_policy" {
  name        = "${var.project_name}-snowflake-s3-access"
  description = "Policy for Snowflake to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.raw_data.arn,
          "${aws_s3_bucket.raw_data.arn}/*",
          aws_s3_bucket.processed_data.arn,
          "${aws_s3_bucket.processed_data.arn}/*",
          aws_s3_bucket.analytics_data.arn,
          "${aws_s3_bucket.analytics_data.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.processed_data.arn}/*",
          "${aws_s3_bucket.analytics_data.arn}/*"
        ]
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "snowflake_s3_attach" {
  role       = aws_iam_role.snowflake_role.name
  policy_arn = aws_iam_policy.snowflake_s3_policy.arn
}

# ============================================================================
# IAM User for programmatic access (for data generators, Dagster, etc.)
# ============================================================================

resource "aws_iam_user" "data_pipeline_user" {
  name = "${var.project_name}-pipeline-user"

  tags = {
    Name        = "Data Pipeline User"
    Description = "IAM user for data pipeline operations"
  }
}

# Policy for pipeline user
resource "aws_iam_policy" "pipeline_user_policy" {
  name        = "${var.project_name}-pipeline-user-policy"
  description = "Policy for data pipeline user to access S3 and other services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.raw_data.arn,
          "${aws_s3_bucket.raw_data.arn}/*",
          aws_s3_bucket.processed_data.arn,
          "${aws_s3_bucket.processed_data.arn}/*",
          aws_s3_bucket.analytics_data.arn,
          "${aws_s3_bucket.analytics_data.arn}/*",
          aws_s3_bucket.archive.arn,
          "${aws_s3_bucket.archive.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:*",
          "lambda:*",
          "logs:*",
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "pipeline_user_attach" {
  user       = aws_iam_user.data_pipeline_user.name
  policy_arn = aws_iam_policy.pipeline_user_policy.arn
}

# Create access key for the user
resource "aws_iam_access_key" "pipeline_user_key" {
  user = aws_iam_user.data_pipeline_user.name
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

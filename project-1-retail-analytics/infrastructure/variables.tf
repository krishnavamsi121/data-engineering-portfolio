variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "retail-analytics"
}

variable "project_owner" {
  description = "Owner of the project"
  type        = string
  default     = "data-engineering-portfolio"
}

# Generate a unique suffix for S3 bucket names to avoid conflicts
# S3 bucket names must be globally unique across all AWS accounts
variable "unique_suffix" {
  description = "Unique suffix for S3 bucket names (use your initials or random string)"
  type        = string
  default     = "demo123"  # CHANGE THIS to something unique like your initials + date
}

variable "snowflake_role_name" {
  description = "Name for the IAM role that Snowflake will assume"
  type        = string
  default     = "snowflake-s3-access-role"
}

variable "snowflake_external_id" {
  description = "External ID for Snowflake IAM role (will be set up later)"
  type        = string
  default     = "placeholder"  # You'll update this after creating Snowflake storage integration
}

variable "enable_versioning" {
  description = "Enable versioning on S3 buckets"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable server-side encryption on S3 buckets"
  type        = bool
  default     = true
}

variable "lifecycle_transition_days" {
  description = "Days before transitioning objects to cheaper storage"
  type        = number
  default     = 90
}

variable "lifecycle_expiration_days" {
  description = "Days before expiring old objects"
  type        = number
  default     = 365
}

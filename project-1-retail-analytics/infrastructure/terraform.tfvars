# ============================================================================
# Terraform Variables - Customize these for your project
# ============================================================================

# AWS Configuration
aws_region  = "us-east-1"
environment = "dev"

# Project Details
project_name  = "retail-analytics"
project_owner = "data-engineering-portfolio"

# IMPORTANT: Change this to something unique!
# Use your initials + date, or random string
# Example: "jd20240218" or "abc123xyz"
unique_suffix = "kvr20240218"  # ⚠️ CHANGE THIS BEFORE RUNNING TERRAFORM

# Snowflake Integration (leave as placeholder for now)
snowflake_user_arn = "arn:aws:iam::267815792638:user/enbh1000-s"
snowflake_external_id = "LW20561_SFCRole=4_kEJizdoAzmzZV8ndspGrBdlgrgo="

# Storage Configuration
enable_versioning            = true
enable_encryption            = true
lifecycle_transition_days    = 90   # Move to cheaper storage after 90 days
lifecycle_expiration_days    = 365  # Delete after 1 year

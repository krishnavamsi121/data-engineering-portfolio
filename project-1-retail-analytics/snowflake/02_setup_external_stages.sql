-- ============================================================================
-- EXTERNAL STAGES AND STORAGE INTEGRATION
-- ============================================================================
-- This script sets up Snowflake to access your S3 buckets
-- IMPORTANT: Replace placeholders with your actual values!
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE RETAIL_ANALYTICS_DB;
USE WAREHOUSE DATA_ENG_WH;

-- ============================================================================
-- STEP 1: CREATE STORAGE INTEGRATION
-- ============================================================================
-- This allows Snowflake to securely access your S3 buckets
-- REPLACE these values with your actual AWS information:
-- - YOUR_AWS_IAM_ROLE_ARN: Get from terraform output snowflake_role_arn
-- - YOUR_RAW_BUCKET: Get from terraform output raw_data_bucket_name
-- - YOUR_PROCESSED_BUCKET: Get from terraform output processed_data_bucket_name
-- - YOUR_ANALYTICS_BUCKET: Get from terraform output analytics_data_bucket_name

CREATE OR REPLACE STORAGE INTEGRATION S3_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::816504230314:role/snowflake-s3-access-role'  -- ⚠️ REPLACE THIS
    STORAGE_ALLOWED_LOCATIONS = (
        's3://retail-analytics-raw-kvr20240218/',      -- ⚠️ REPLACE THIS
        's3://retail-analytics-processed-kvr20240218', -- ⚠️ REPLACE THIS
        's3://retail-analytics-analytics-kvr20240218/'  -- ⚠️ REPLACE THIS
    )
    COMMENT = 'Integration for accessing S3 data lake buckets';

-- ============================================================================
-- STEP 2: GET SNOWFLAKE IAM USER AND EXTERNAL ID
-- ============================================================================
-- Run this command and SAVE the output:
DESC INTEGRATION S3_INTEGRATION;

-- Look for these two values in the output:
-- STORAGE_AWS_IAM_USER_ARN: arn:aws:iam::123456789012:user/abc...
-- STORAGE_AWS_EXTERNAL_ID: ABC12345_SFCRole=1_abcdefg...

-- YOU NEED TO:
-- 1. Copy the STORAGE_AWS_IAM_USER_ARN
-- 2. Copy the STORAGE_AWS_EXTERNAL_ID
-- 3. Update your Terraform with the external_id
-- 4. Update the IAM role trust policy in AWS

-- ============================================================================
-- STEP 3: CREATE EXTERNAL STAGES
-- ============================================================================

USE SCHEMA BRONZE;

-- External Stage for Raw Data (Bronze)
CREATE OR REPLACE STAGE S3_RAW_STAGE
    URL = 's3://retail-analytics-raw-YOUR-SUFFIX/'  -- ⚠️ REPLACE THIS
    STORAGE_INTEGRATION = S3_INTEGRATION
    FILE_FORMAT = CSV_FORMAT
    COMMENT = 'Stage for raw data from S3';

-- External Stage for Processed Data (Silver)
CREATE OR REPLACE STAGE S3_PROCESSED_STAGE
    URL = 's3://retail-analytics-processed-YOUR-SUFFIX/'  -- ⚠️ REPLACE THIS
    STORAGE_INTEGRATION = S3_INTEGRATION
    FILE_FORMAT = CSV_FORMAT
    COMMENT = 'Stage for processed data from S3';

-- External Stage for Analytics Data (Gold)
CREATE OR REPLACE STAGE S3_ANALYTICS_STAGE
    URL = 's3://retail-analytics-analytics-YOUR-SUFFIX/'  -- ⚠️ REPLACE THIS
    STORAGE_INTEGRATION = S3_INTEGRATION
    FILE_FORMAT = PARQUET_FORMAT
    COMMENT = 'Stage for analytics data from S3';

-- External Stage for JSON Events
CREATE OR REPLACE STAGE S3_EVENTS_STAGE
    URL = 's3://retail-analytics-raw-YOUR-SUFFIX/events/'  -- ⚠️ REPLACE THIS
    STORAGE_INTEGRATION = S3_INTEGRATION
    FILE_FORMAT = JSON_FORMAT
    COMMENT = 'Stage for JSON event data from S3';

-- ============================================================================
-- STEP 4: TEST THE STAGES
-- ============================================================================

-- List files in raw stage (should be empty initially)
LIST @S3_RAW_STAGE;

-- List files in processed stage
LIST @S3_PROCESSED_STAGE;

-- ============================================================================
-- STEP 5: CREATE EXTERNAL TABLES (Optional - query S3 directly)
-- ============================================================================

-- External table for customers in S3
CREATE OR REPLACE EXTERNAL TABLE EXT_CUSTOMERS (
    customer_id INTEGER AS (VALUE:c1::INTEGER),
    first_name STRING AS (VALUE:c2::STRING),
    last_name STRING AS (VALUE:c3::STRING),
    email STRING AS (VALUE:c4::STRING),
    phone STRING AS (VALUE:c5::STRING),
    address STRING AS (VALUE:c6::STRING),
    city STRING AS (VALUE:c7::STRING),
    state STRING AS (VALUE:c8::STRING),
    zip_code STRING AS (VALUE:c9::STRING),
    country STRING AS (VALUE:c10::STRING),
    signup_date STRING AS (VALUE:c11::STRING),
    customer_segment STRING AS (VALUE:c12::STRING)
)
LOCATION = @S3_RAW_STAGE/customers/
FILE_FORMAT = CSV_FORMAT
AUTO_REFRESH = FALSE
COMMENT = 'External table for customer data in S3';

-- External table for products in S3
CREATE OR REPLACE EXTERNAL TABLE EXT_PRODUCTS (
    product_id INTEGER AS (VALUE:c1::INTEGER),
    product_name STRING AS (VALUE:c2::STRING),
    category STRING AS (VALUE:c3::STRING),
    subcategory STRING AS (VALUE:c4::STRING),
    brand STRING AS (VALUE:c5::STRING),
    unit_price DECIMAL(10,2) AS (VALUE:c6::DECIMAL(10,2)),
    cost DECIMAL(10,2) AS (VALUE:c7::DECIMAL(10,2)),
    supplier_id INTEGER AS (VALUE:c8::INTEGER),
    supplier_name STRING AS (VALUE:c9::STRING)
)
LOCATION = @S3_RAW_STAGE/products/
FILE_FORMAT = CSV_FORMAT
AUTO_REFRESH = FALSE
COMMENT = 'External table for product data in S3';

-- ============================================================================
-- STEP 6: VERIFY SETUP
-- ============================================================================

-- Show all stages
SHOW STAGES IN SCHEMA BRONZE;

-- Show storage integration
SHOW INTEGRATIONS;

-- Test query external table (will be empty until you load data)
SELECT COUNT(*) as customer_count FROM EXT_CUSTOMERS;
SELECT COUNT(*) as product_count FROM EXT_PRODUCTS;

SELECT 'External stages created successfully!' AS status;

-- ============================================================================
-- IMPORTANT NEXT STEPS:
-- ============================================================================
-- 1. Copy the STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID from:
--    DESC INTEGRATION S3_INTEGRATION;
--
-- 2. Update your Terraform:
--    - Edit terraform.tfvars
--    - Set snowflake_external_id = "YOUR_EXTERNAL_ID"
--    - Run: terraform apply
--
-- 3. This will update the IAM role trust policy to allow Snowflake access
--
-- 4. Test the connection by uploading a file to S3 and querying it
-- ============================================================================

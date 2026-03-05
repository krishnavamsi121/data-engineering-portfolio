# Snowflake Setup Scripts

This directory contains all SQL scripts needed to set up the Snowflake environment for the Retail Analytics Platform.

## Architecture

**Medallion Architecture:**
- **Bronze Layer**: Raw data as-is from sources
- **Silver Layer**: Cleaned, validated, and conformed data
- **Gold Layer**: Business-ready analytics with star schema

**Star Schema in Gold Layer:**
- Fact: `FACT_SALES` - Sales transactions
- Dimensions: `DIM_CUSTOMER`, `DIM_PRODUCT`, `DIM_DATE`
- Aggregates: Pre-computed summaries for fast queries

## Scripts Execution Order

Run these scripts in order:

### 1. Database and Schema Setup
**File:** `01_setup_database.sql`

**What it does:**
- Creates `RETAIL_ANALYTICS_DB` database
- Creates Bronze, Silver, Gold, and Staging schemas
- Creates file formats (CSV, JSON, Parquet)
- Creates all tables in each layer
- Creates views for easy access

**How to run:**
```sql
-- In Snowflake Web UI, open a worksheet
-- Copy and paste the entire script
-- Click "Run All"
```

**Expected result:**
- 1 database created
- 4 schemas created
- ~20 tables created
- 3 views created

---

### 2. External Stages and S3 Integration
**File:** `02_setup_external_stages.sql`

**IMPORTANT - Before running:**
1. Get your AWS values from Terraform:
   ```bash
   cd ~/data-engineering-portfolio/project-1-retail-analytics/infrastructure
   terraform output snowflake_role_arn
   terraform output raw_data_bucket_name
   terraform output processed_data_bucket_name
   terraform output analytics_data_bucket_name
   ```

2. Replace these placeholders in the script:
   - `YOUR_AWS_IAM_ROLE_ARN` → Your Snowflake role ARN
   - `YOUR_RAW_BUCKET` → Your raw bucket name
   - `YOUR_PROCESSED_BUCKET` → Your processed bucket name
   - `YOUR_ANALYTICS_BUCKET` → Your analytics bucket name

**What it does:**
- Creates storage integration with S3
- Creates external stages pointing to your S3 buckets
- Creates external tables for querying S3 directly
- Tests the connection

**How to run:**
```sql
-- After replacing placeholders
-- Copy and paste the script
-- Run section by section (not all at once)
```

**Critical step after running:**
```sql
-- Run this and save the output:
DESC INTEGRATION S3_INTEGRATION;

-- Look for:
-- STORAGE_AWS_IAM_USER_ARN
-- STORAGE_AWS_EXTERNAL_ID
```

**Then update Terraform:**
```bash
cd ~/data-engineering-portfolio/project-1-retail-analytics/infrastructure
nano terraform.tfvars

# Change this line:
snowflake_external_id = "YOUR_EXTERNAL_ID_FROM_SNOWFLAKE"

# Apply changes:
terraform apply
```

---

### 3. Populate Date Dimension
**File:** `03_populate_date_dimension.sql`

**What it does:**
- Populates `DIM_DATE` with dates from 2020-2030
- Adds US holidays
- Marks weekends
- Adds fiscal year/quarter information

**How to run:**
```sql
-- Copy and paste the entire script
-- Click "Run All"
```

**Expected result:**
- ~3,650 rows in DIM_DATE (10 years of dates)
- Holidays properly marked

---

## Schema Details

### Bronze Layer Tables

**RAW_CUSTOMERS**
- Raw customer data from source systems
- Includes metadata columns (_loaded_at, _source_file, etc.)

**RAW_PRODUCTS**
- Product catalog with pricing and supplier info

**RAW_ORDERS**
- Order headers with shipping and payment info

**RAW_ORDER_ITEMS**
- Individual line items for each order

**RAW_EVENTS**
- Clickstream and event data (JSON)

**RAW_INVENTORY**
- Inventory levels by warehouse

### Silver Layer Tables

**CUSTOMERS**
- Cleaned customer data with derived fields
- Data quality scores
- Deduplication applied

**PRODUCTS**
- Cleaned product catalog
- Calculated margin and margin percentage

**ORDERS**
- Cleaned order data
- Standardized date formats

**ORDER_ITEMS**
- Cleaned line items
- Validated quantities and prices

### Gold Layer Tables

**DIM_CUSTOMER** (SCD Type 2)
- Customer dimension with history tracking
- Effective dates for tracking changes over time

**DIM_PRODUCT** (SCD Type 2)
- Product dimension with history
- Tracks price changes and product updates

**DIM_DATE**
- Complete date dimension
- Holidays, weekends, fiscal periods

**FACT_SALES**
- Sales transactions at line-item grain
- All measures (quantity, price, cost, margin)
- Foreign keys to dimensions

**AGG_DAILY_SALES**
- Pre-aggregated daily summaries
- Fast queries for dashboards

**AGG_PRODUCT_PERFORMANCE**
- Product metrics over time
- Daily, weekly, monthly rollups

### Views

**V_CURRENT_CUSTOMERS**
- Only current (active) customer records

**V_CURRENT_PRODUCTS**
- Only current product records

**V_SALES_SUMMARY**
- Denormalized view joining all dimensions
- Easy querying for reporting

---

## Testing Your Setup

### Verify Database Structure
```sql
-- List all schemas
SHOW SCHEMAS IN DATABASE RETAIL_ANALYTICS_DB;

-- Count tables in each layer
SELECT 
    table_schema,
    COUNT(*) as table_count
FROM RETAIL_ANALYTICS_DB.INFORMATION_SCHEMA.TABLES
WHERE table_type = 'BASE TABLE'
GROUP BY table_schema;
```

### Test External Stages
```sql
USE SCHEMA BRONZE;

-- List files in S3 (will be empty initially)
LIST @S3_RAW_STAGE;

-- Upload a test file to S3, then:
LIST @S3_RAW_STAGE/test/;
```

### Test External Tables
```sql
-- After uploading data to S3:
SELECT * FROM EXT_CUSTOMERS LIMIT 10;
SELECT COUNT(*) FROM EXT_PRODUCTS;
```

### Verify Date Dimension
```sql
USE SCHEMA GOLD;

-- Check date range
SELECT MIN(date_actual), MAX(date_actual) FROM DIM_DATE;

-- See holidays in 2024
SELECT * FROM DIM_DATE 
WHERE year = 2024 AND is_holiday = TRUE
ORDER BY date_actual;
```

---

## Next Steps

After running all setup scripts:

1. **Upload sample data to S3**
   ```bash
   aws s3 cp sample_customers.csv s3://your-raw-bucket/customers/
   ```

2. **Load data into Bronze tables**
   ```sql
   COPY INTO BRONZE.RAW_CUSTOMERS
   FROM @S3_RAW_STAGE/customers/
   FILE_FORMAT = CSV_FORMAT;
   ```

3. **Create dbt models** to transform Bronze → Silver → Gold

4. **Set up Dagster** to orchestrate the pipeline

5. **Implement data quality checks**

---

## Cost Management

**Warehouse Auto-Suspend:**
```sql
-- Ensure warehouse suspends when idle
ALTER WAREHOUSE DATA_ENG_WH SET AUTO_SUSPEND = 300; -- 5 minutes

-- Manually suspend when done:
ALTER WAREHOUSE DATA_ENG_WH SUSPEND;
```

**Monitor Usage:**
```sql
-- Check warehouse usage
SELECT * 
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'DATA_ENG_WH'
ORDER BY START_TIME DESC
LIMIT 100;

-- Check storage usage
SELECT * 
FROM SNOWFLAKE.ACCOUNT_USAGE.STORAGE_USAGE
ORDER BY USAGE_DATE DESC
LIMIT 30;
```

---

## Troubleshooting

### Error: "Integration does not exist"
**Solution:** Make sure you ran `01_setup_database.sql` first

### Error: "Insufficient privileges"
**Solution:** Use `ACCOUNTADMIN` role:
```sql
USE ROLE ACCOUNTADMIN;
```

### Error: "Access Denied" when accessing S3
**Possible causes:**
1. Storage integration not created properly
2. IAM role ARN is incorrect
3. External ID not updated in Terraform
4. S3 bucket names are incorrect

**Solution:**
1. Verify IAM role ARN matches Terraform output
2. Check bucket names are exact matches
3. Update Terraform with external_id and re-apply
4. Run `DESC INTEGRATION S3_INTEGRATION;` to verify setup

### Error: "File format does not exist"
**Solution:** Make sure you're in the correct schema:
```sql
USE SCHEMA BRONZE;
```

### External tables show 0 rows
**This is normal if:**
- You haven't uploaded any files to S3 yet
- Files are in wrong S3 location
- File format doesn't match data

---

## File Locations

```
project-1-retail-analytics/
└── snowflake/
    ├── README.md (this file)
    ├── 01_setup_database.sql
    ├── 02_setup_external_stages.sql
    └── 03_populate_date_dimension.sql
```

---

## Maintenance Scripts

### Refresh External Tables
```sql
-- Refresh metadata for external tables
ALTER EXTERNAL TABLE EXT_CUSTOMERS REFRESH;
ALTER EXTERNAL TABLE EXT_PRODUCTS REFRESH;
```

### Check Table Sizes
```sql
SELECT 
    table_schema,
    table_name,
    row_count,
    bytes
FROM RETAIL_ANALYTICS_DB.INFORMATION_SCHEMA.TABLES
WHERE table_type = 'BASE TABLE'
ORDER BY bytes DESC;
```

### Vacuum Old Data (if using Time Travel)
```sql
-- Drop old table versions to save storage
ALTER TABLE BRONZE.RAW_CUSTOMERS 
SET DATA_RETENTION_TIME_IN_DAYS = 1;
```

---

## Resources

- [Snowflake Documentation](https://docs.snowflake.com/)
- [External Stages Guide](https://docs.snowflake.com/en/user-guide/data-load-s3)
- [Storage Integration](https://docs.snowflake.com/en/sql-reference/sql/create-storage-integration)
- [Medallion Architecture](https://www.databricks.com/glossary/medallion-architecture)

---

**Questions?** Check the troubleshooting section or review the Snowflake documentation.

-- ============================================================================
-- RETAIL ANALYTICS PLATFORM - SNOWFLAKE SETUP
-- ============================================================================
-- This script creates the complete database structure for the retail analytics
-- platform using a medallion architecture (Bronze, Silver, Gold)
-- ============================================================================

-- Set context
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE DATA_ENG_WH;

-- ============================================================================
-- DATABASE SETUP
-- ============================================================================

-- Create main database
CREATE DATABASE IF NOT EXISTS RETAIL_ANALYTICS_DB
    COMMENT = 'Main database for retail analytics platform';

USE DATABASE RETAIL_ANALYTICS_DB;

-- ============================================================================
-- SCHEMA SETUP - Medallion Architecture
-- ============================================================================

-- BRONZE Layer: Raw data as-is from sources
CREATE SCHEMA IF NOT EXISTS BRONZE
    COMMENT = 'Bronze layer - Raw data landing zone';

-- SILVER Layer: Cleaned and validated data
CREATE SCHEMA IF NOT EXISTS SILVER
    COMMENT = 'Silver layer - Cleaned and validated data';

-- GOLD Layer: Business-ready analytics data
CREATE SCHEMA IF NOT EXISTS GOLD
    COMMENT = 'Gold layer - Business-ready analytics and aggregations';

-- STAGING: Temporary data processing
CREATE SCHEMA IF NOT EXISTS STAGING
    COMMENT = 'Staging area for data transformations';

-- ============================================================================
-- FILE FORMATS
-- ============================================================================

USE SCHEMA BRONZE;

-- CSV file format for raw data
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
    COMPRESSION = AUTO
    COMMENT = 'Standard CSV format for raw data ingestion';

-- JSON file format
CREATE OR REPLACE FILE FORMAT JSON_FORMAT
    TYPE = 'JSON'
    COMPRESSION = AUTO
    COMMENT = 'Standard JSON format for event data';

-- Parquet file format
CREATE OR REPLACE FILE FORMAT PARQUET_FORMAT
    TYPE = 'PARQUET'
    COMPRESSION = AUTO
    COMMENT = 'Parquet format for optimized storage';

-- ============================================================================
-- BRONZE LAYER TABLES - Raw Data
-- ============================================================================

USE SCHEMA BRONZE;

-- Raw Customers Table
CREATE OR REPLACE TABLE RAW_CUSTOMERS (
    customer_id INTEGER,
    first_name STRING,
    last_name STRING,
    email STRING,
    phone STRING,
    address STRING,
    city STRING,
    state STRING,
    zip_code STRING,
    country STRING,
    signup_date TIMESTAMP_NTZ,
    customer_segment STRING,
    -- Metadata columns
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file STRING,
    _source_row INTEGER
) COMMENT = 'Raw customer data from source systems';

-- Raw Products Table
CREATE OR REPLACE TABLE RAW_PRODUCTS (
    product_id INTEGER,
    product_name STRING,
    category STRING,
    subcategory STRING,
    brand STRING,
    unit_price DECIMAL(10,2),
    cost DECIMAL(10,2),
    supplier_id INTEGER,
    supplier_name STRING,
    -- Metadata columns
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file STRING,
    _source_row INTEGER
) COMMENT = 'Raw product catalog data';

-- Raw Orders Table
CREATE OR REPLACE TABLE RAW_ORDERS (
    order_id INTEGER,
    customer_id INTEGER,
    order_date TIMESTAMP_NTZ,
    order_status STRING,
    shipping_address STRING,
    shipping_city STRING,
    shipping_state STRING,
    shipping_zip STRING,
    payment_method STRING,
    total_amount DECIMAL(10,2),
    -- Metadata columns
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file STRING,
    _source_row INTEGER
) COMMENT = 'Raw order header data';

-- Raw Order Items Table
CREATE OR REPLACE TABLE RAW_ORDER_ITEMS (
    order_item_id INTEGER,
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    unit_price DECIMAL(10,2),
    discount DECIMAL(10,2),
    line_total DECIMAL(10,2),
    -- Metadata columns
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file STRING,
    _source_row INTEGER
) COMMENT = 'Raw order line items';

-- Raw Clickstream Events (JSON)
CREATE OR REPLACE TABLE RAW_EVENTS (
    event_id STRING,
    event_timestamp TIMESTAMP_NTZ,
    event_type STRING,
    customer_id INTEGER,
    session_id STRING,
    page_url STRING,
    product_id INTEGER,
    event_data VARIANT,
    -- Metadata columns
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file STRING
) COMMENT = 'Raw clickstream and event data';

-- Raw Inventory Table
CREATE OR REPLACE TABLE RAW_INVENTORY (
    inventory_id INTEGER,
    product_id INTEGER,
    warehouse_location STRING,
    quantity_on_hand INTEGER,
    quantity_reserved INTEGER,
    reorder_point INTEGER,
    last_restocked_date TIMESTAMP_NTZ,
    -- Metadata columns
    _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file STRING,
    _source_row INTEGER
) COMMENT = 'Raw inventory levels';

-- ============================================================================
-- SILVER LAYER TABLES - Cleaned Data
-- ============================================================================

USE SCHEMA SILVER;

-- Cleaned Customers
CREATE OR REPLACE TABLE CUSTOMERS (
    customer_key INTEGER AUTOINCREMENT PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    first_name STRING,
    last_name STRING,
    full_name STRING,
    email STRING,
    email_domain STRING,
    phone STRING,
    address STRING,
    city STRING,
    state STRING,
    zip_code STRING,
    country STRING,
    signup_date DATE,
    customer_segment STRING,
    is_active BOOLEAN,
    -- Audit columns
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    data_quality_score DECIMAL(3,2)
) COMMENT = 'Cleaned and validated customer data';

-- Cleaned Products
CREATE OR REPLACE TABLE PRODUCTS (
    product_key INTEGER AUTOINCREMENT PRIMARY KEY,
    product_id INTEGER NOT NULL,
    product_name STRING,
    category STRING,
    subcategory STRING,
    brand STRING,
    unit_price DECIMAL(10,2),
    cost DECIMAL(10,2),
    margin DECIMAL(10,2),
    margin_percent DECIMAL(5,2),
    supplier_id INTEGER,
    supplier_name STRING,
    is_active BOOLEAN,
    -- Audit columns
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Cleaned product catalog';

-- Cleaned Orders
CREATE OR REPLACE TABLE ORDERS (
    order_key INTEGER AUTOINCREMENT PRIMARY KEY,
    order_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    order_date DATE,
    order_timestamp TIMESTAMP_NTZ,
    order_status STRING,
    shipping_address STRING,
    shipping_city STRING,
    shipping_state STRING,
    shipping_zip STRING,
    payment_method STRING,
    total_amount DECIMAL(10,2),
    -- Audit columns
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Cleaned order headers';

-- Cleaned Order Items
CREATE OR REPLACE TABLE ORDER_ITEMS (
    order_item_key INTEGER AUTOINCREMENT PRIMARY KEY,
    order_item_id INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER,
    unit_price DECIMAL(10,2),
    discount DECIMAL(10,2),
    discount_percent DECIMAL(5,2),
    line_total DECIMAL(10,2),
    -- Audit columns
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Cleaned order line items';

-- ============================================================================
-- GOLD LAYER TABLES - Analytics Ready (Star Schema)
-- ============================================================================

USE SCHEMA GOLD;

-- Dimension: Customer
CREATE OR REPLACE TABLE DIM_CUSTOMER (
    customer_sk INTEGER AUTOINCREMENT PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    first_name STRING,
    last_name STRING,
    full_name STRING,
    email STRING,
    phone STRING,
    city STRING,
    state STRING,
    country STRING,
    customer_segment STRING,
    signup_date DATE,
    -- SCD Type 2 columns
    effective_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    -- Audit columns
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Customer dimension with SCD Type 2';

-- Dimension: Product
CREATE OR REPLACE TABLE DIM_PRODUCT (
    product_sk INTEGER AUTOINCREMENT PRIMARY KEY,
    product_id INTEGER NOT NULL,
    product_name STRING,
    category STRING,
    subcategory STRING,
    brand STRING,
    unit_price DECIMAL(10,2),
    cost DECIMAL(10,2),
    margin DECIMAL(10,2),
    margin_percent DECIMAL(5,2),
    supplier_name STRING,
    -- SCD Type 2 columns
    effective_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    -- Audit columns
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COMMENT = 'Product dimension with SCD Type 2';

-- Dimension: Date
CREATE OR REPLACE TABLE DIM_DATE (
    date_sk INTEGER PRIMARY KEY,
    date_actual DATE NOT NULL,
    day_of_week INTEGER,
    day_name STRING,
    day_of_month INTEGER,
    day_of_year INTEGER,
    week_of_year INTEGER,
    month_number INTEGER,
    month_name STRING,
    quarter INTEGER,
    year INTEGER,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN,
    holiday_name STRING,
    fiscal_year INTEGER,
    fiscal_quarter INTEGER
) COMMENT = 'Date dimension for time-based analysis';

-- Fact: Sales
CREATE OR REPLACE TABLE FACT_SALES (
    sales_sk INTEGER AUTOINCREMENT PRIMARY KEY,
    date_sk INTEGER NOT NULL,
    customer_sk INTEGER NOT NULL,
    product_sk INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    order_item_id INTEGER NOT NULL,
    -- Measures
    quantity INTEGER,
    unit_price DECIMAL(10,2),
    unit_cost DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    line_total DECIMAL(10,2),
    line_cost DECIMAL(10,2),
    line_margin DECIMAL(10,2),
    line_margin_percent DECIMAL(5,2),
    -- Audit
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    -- Foreign keys (for reference, not enforced)
    CONSTRAINT fk_date FOREIGN KEY (date_sk) REFERENCES DIM_DATE(date_sk) NOT ENFORCED,
    CONSTRAINT fk_customer FOREIGN KEY (customer_sk) REFERENCES DIM_CUSTOMER(customer_sk) NOT ENFORCED,
    CONSTRAINT fk_product FOREIGN KEY (product_sk) REFERENCES DIM_PRODUCT(product_sk) NOT ENFORCED
) COMMENT = 'Sales fact table with daily transaction grain';

-- Aggregate: Daily Sales Summary
CREATE OR REPLACE TABLE AGG_DAILY_SALES (
    date_sk INTEGER NOT NULL,
    date_actual DATE NOT NULL,
    total_orders INTEGER,
    total_items INTEGER,
    total_quantity INTEGER,
    total_revenue DECIMAL(12,2),
    total_cost DECIMAL(12,2),
    total_margin DECIMAL(12,2),
    margin_percent DECIMAL(5,2),
    avg_order_value DECIMAL(10,2),
    unique_customers INTEGER,
    -- Audit
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (date_sk)
) COMMENT = 'Daily sales aggregations for fast queries';

-- Aggregate: Product Performance
CREATE OR REPLACE TABLE AGG_PRODUCT_PERFORMANCE (
    product_sk INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    product_name STRING,
    category STRING,
    time_period STRING, -- 'daily', 'weekly', 'monthly'
    period_date DATE NOT NULL,
    total_quantity INTEGER,
    total_revenue DECIMAL(12,2),
    total_cost DECIMAL(12,2),
    total_margin DECIMAL(12,2),
    number_of_orders INTEGER,
    unique_customers INTEGER,
    -- Audit
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (product_sk, time_period, period_date)
) COMMENT = 'Product performance metrics over time';

-- ============================================================================
-- VIEWS FOR EASY ACCESS
-- ============================================================================

-- Current customers view
CREATE OR REPLACE VIEW V_CURRENT_CUSTOMERS AS
SELECT 
    customer_sk,
    customer_id,
    full_name,
    email,
    city,
    state,
    customer_segment,
    signup_date
FROM DIM_CUSTOMER
WHERE is_current = TRUE;

-- Current products view
CREATE OR REPLACE VIEW V_CURRENT_PRODUCTS AS
SELECT 
    product_sk,
    product_id,
    product_name,
    category,
    subcategory,
    brand,
    unit_price,
    margin_percent
FROM DIM_PRODUCT
WHERE is_current = TRUE;

-- Sales summary view
CREATE OR REPLACE VIEW V_SALES_SUMMARY AS
SELECT 
    d.date_actual,
    d.day_name,
    d.month_name,
    d.year,
    c.full_name as customer_name,
    c.city as customer_city,
    c.customer_segment,
    p.product_name,
    p.category,
    p.brand,
    f.quantity,
    f.unit_price,
    f.line_total,
    f.line_margin,
    f.line_margin_percent
FROM FACT_SALES f
JOIN DIM_DATE d ON f.date_sk = d.date_sk
JOIN DIM_CUSTOMER c ON f.customer_sk = c.customer_sk
JOIN DIM_PRODUCT p ON f.product_sk = p.product_sk;

-- ============================================================================
-- CONFIRMATION
-- ============================================================================

-- Show what was created
SHOW DATABASES LIKE 'RETAIL_ANALYTICS_DB';
SHOW SCHEMAS IN DATABASE RETAIL_ANALYTICS_DB;

SELECT 'Database and schemas created successfully!' AS status;
SELECT 'Bronze layer: ' || COUNT(*) || ' tables' AS bronze_tables 
FROM RETAIL_ANALYTICS_DB.INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'BRONZE' AND TABLE_TYPE = 'BASE TABLE';

SELECT 'Silver layer: ' || COUNT(*) || ' tables' AS silver_tables 
FROM RETAIL_ANALYTICS_DB.INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'SILVER' AND TABLE_TYPE = 'BASE TABLE';

SELECT 'Gold layer: ' || COUNT(*) || ' tables' AS gold_tables 
FROM RETAIL_ANALYTICS_DB.INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'GOLD' AND TABLE_TYPE = 'BASE TABLE';

-- ============================================================================
-- SETUP COMPLETE!
-- Next steps:
-- 1. Create external stages pointing to S3
-- 2. Load sample data
-- 3. Set up Snowpipe for automated loading
-- ============================================================================

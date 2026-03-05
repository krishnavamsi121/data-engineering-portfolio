-- ============================================================================
-- POPULATE DATE DIMENSION
-- ============================================================================
-- This script populates the DIM_DATE table with dates from 2020-2030
-- Run this once after creating the tables
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE RETAIL_ANALYTICS_DB;
USE SCHEMA GOLD;
USE WAREHOUSE DATA_ENG_WH;

-- ============================================================================
-- GENERATE DATE DIMENSION
-- ============================================================================

-- Generate dates from 2020 to 2030
INSERT INTO DIM_DATE (
    date_sk,
    date_actual,
    day_of_week,
    day_name,
    day_of_month,
    day_of_year,
    week_of_year,
    month_number,
    month_name,
    quarter,
    year,
    is_weekend,
    is_holiday,
    fiscal_year,
    fiscal_quarter
)
WITH date_series AS (
    -- Generate a series of dates
    SELECT 
        DATEADD(day, SEQ4(), '2020-01-01'::DATE) AS date_actual
    FROM TABLE(GENERATOR(ROWCOUNT => 3653))  -- 10 years of dates (365 * 10 + leap days)
    WHERE date_actual <= '2030-12-31'
)
SELECT 
    -- date_sk: YYYYMMDD format
    TO_NUMBER(TO_CHAR(date_actual, 'YYYYMMDD')) AS date_sk,
    date_actual,
    DAYOFWEEK(date_actual) AS day_of_week,
    DAYNAME(date_actual) AS day_name,
    DAYOFMONTH(date_actual) AS day_of_month,
    DAYOFYEAR(date_actual) AS day_of_year,
    WEEKOFYEAR(date_actual) AS week_of_year,
    MONTH(date_actual) AS month_number,
    MONTHNAME(date_actual) AS month_name,
    QUARTER(date_actual) AS quarter,
    YEAR(date_actual) AS year,
    CASE 
        WHEN DAYOFWEEK(date_actual) IN (0, 6) THEN TRUE  -- Sunday = 0, Saturday = 6
        ELSE FALSE 
    END AS is_weekend,
    FALSE AS is_holiday,  -- You can update this later with actual holidays
    -- Fiscal year (assuming fiscal year starts in January)
    YEAR(date_actual) AS fiscal_year,
    QUARTER(date_actual) AS fiscal_quarter
FROM date_series
ORDER BY date_actual;

-- ============================================================================
-- ADD COMMON US HOLIDAYS
-- ============================================================================

-- Update New Year's Day
UPDATE DIM_DATE
SET is_holiday = TRUE, holiday_name = 'New Year''s Day'
WHERE month_number = 1 AND day_of_month = 1;

-- Update Independence Day (July 4th)
UPDATE DIM_DATE
SET is_holiday = TRUE, holiday_name = 'Independence Day'
WHERE month_number = 7 AND day_of_month = 4;

-- Update Christmas
UPDATE DIM_DATE
SET is_holiday = TRUE, holiday_name = 'Christmas'
WHERE month_number = 12 AND day_of_month = 25;

-- Update Thanksgiving (4th Thursday of November)
UPDATE DIM_DATE
SET is_holiday = TRUE, holiday_name = 'Thanksgiving'
WHERE month_number = 11
  AND day_name = 'Thu'
  AND day_of_month BETWEEN 22 AND 28;

-- Update Black Friday (day after Thanksgiving)
UPDATE DIM_DATE d1
SET is_holiday = TRUE, holiday_name = 'Black Friday'
FROM (
    SELECT date_actual
    FROM DIM_DATE
    WHERE holiday_name = 'Thanksgiving'
) d2
WHERE d1.date_actual = DATEADD(day, 1, d2.date_actual);

-- Update Cyber Monday (Monday after Thanksgiving)
UPDATE DIM_DATE d1
SET is_holiday = TRUE, holiday_name = 'Cyber Monday'
FROM (
    SELECT date_actual
    FROM DIM_DATE
    WHERE holiday_name = 'Thanksgiving'
) d2
WHERE d1.date_actual = DATEADD(day, 4, d2.date_actual)
  AND d1.day_name = 'Mon';

-- Update Memorial Day (last Monday of May)
UPDATE DIM_DATE
SET is_holiday = TRUE, holiday_name = 'Memorial Day'
WHERE month_number = 5
  AND day_name = 'Mon'
  AND day_of_month >= 25;

-- Update Labor Day (first Monday of September)
UPDATE DIM_DATE
SET is_holiday = TRUE, holiday_name = 'Labor Day'
WHERE month_number = 9
  AND day_name = 'Mon'
  AND day_of_month <= 7;

-- ============================================================================
-- VERIFY DATE DIMENSION
-- ============================================================================

-- Check row count
SELECT COUNT(*) AS total_dates FROM DIM_DATE;

-- Check date range
SELECT 
    MIN(date_actual) AS min_date,
    MAX(date_actual) AS max_date,
    DATEDIFF(day, MIN(date_actual), MAX(date_actual)) AS days_covered
FROM DIM_DATE;

-- Check holidays
SELECT 
    year,
    holiday_name,
    date_actual,
    day_name
FROM DIM_DATE
WHERE is_holiday = TRUE
ORDER BY date_actual;

-- Check weekend distribution
SELECT 
    is_weekend,
    COUNT(*) AS count_days
FROM DIM_DATE
GROUP BY is_weekend;

-- Sample of dates
SELECT * FROM DIM_DATE
WHERE year = 2024 AND month_number = 2
ORDER BY date_actual
LIMIT 10;

SELECT 'Date dimension populated successfully!' AS status;
SELECT 'Total dates loaded: ' || COUNT(*) FROM DIM_DATE;

-- ============================================================================
-- USEFUL QUERIES FOR DATE DIMENSION
-- ============================================================================

-- All holidays in 2024
-- SELECT * FROM DIM_DATE WHERE year = 2024 AND is_holiday = TRUE ORDER BY date_actual;

-- All weekends in a month
-- SELECT * FROM DIM_DATE WHERE year = 2024 AND month_number = 2 AND is_weekend = TRUE;

-- First day of each month in 2024
-- SELECT * FROM DIM_DATE WHERE year = 2024 AND day_of_month = 1 ORDER BY month_number;

-- Last day of each month
-- SELECT DISTINCT 
--     year, 
--     month_number, 
--     MAX(day_of_month) OVER (PARTITION BY year, month_number) AS last_day
-- FROM DIM_DATE 
-- WHERE year = 2024;

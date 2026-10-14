-- =====================================================================
-- 12_patches.sql
-- R05b: one StockCode had a trailing space.
-- Found when Power BI refused to create the dim_product -> fact_sales relationship
-- ("duplicate value 47503J"). MySQL treated '47503J' and '47503J ' as two different
-- keys; Power BI did not. Stock codes were upper-cased in staging (R05) but never trimmed.
-- Run order: 12, after 11_data_model.sql.
-- Reproducibility note: also add Text.Trim to StockCode in the Power Query Stg_Sales query,
-- so a rebuild from the raw files never produces the dirty row.
-- =====================================================================

USE ecommerce;

-- 1 fact row had a trailing space (the same code appeared twice in dim_product)
UPDATE stg_sales
SET stock_code = TRIM(stock_code)
WHERE line_id > 0
  AND stock_code <> TRIM(stock_code);

-- Remove the duplicate dimension row, matched by exact bytes ('47503J' + a space)
DELETE FROM dim_product
WHERE HEX(stock_code) = '34373530334A20';

-- Expected: products 5,131 | named 4,724 | unnamed 407
SELECT COUNT(*) AS products, SUM(has_sales) AS named, SUM(has_sales = 0) AS unnamed
FROM dim_product;

-- Expected: fact_rows 1,044,848 | fact_revenue 18,909,762.118 | stock_code_spaces 0
SELECT COUNT(*) AS fact_rows, ROUND(SUM(revenue), 3) AS fact_revenue,
       SUM(stock_code <> TRIM(stock_code)) AS stock_code_spaces
FROM fact_sales;

-- Expected: orphan_rows 0
SELECT COUNT(*) AS orphan_rows
FROM fact_sales f LEFT JOIN dim_product p ON p.stock_code = f.stock_code
WHERE p.stock_code IS NULL;

-- Same check on the other key columns. Expected: all 0
SELECT SUM(invoice <> TRIM(invoice))                    AS invoice_spaces,
       SUM(customer_id <> TRIM(customer_id))            AS customer_spaces,
       SUM(standard_country <> TRIM(standard_country))  AS country_spaces,
       SUM(row_type <> TRIM(row_type))                  AS row_type_spaces
FROM stg_sales;

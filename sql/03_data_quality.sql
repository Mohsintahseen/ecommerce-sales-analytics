-- =====================================================================
-- 03_data_quality.sql
-- Purpose  : Validate the load against the numbers verified in Power Query
--            (see Validation_Anchors sheet in Ecommerce_Documentation.xlsx).
-- Run order: 3 of 10
-- Rule     : never assume a result is right; every figure below was compared
--            with an independent calculation.
-- =====================================================================

USE ecommerce;

-- 3.1 Row count and total revenue
-- Expected: 1,044,848 rows; revenue 18,909,762.118 (about 18,909,762.12)
SELECT COUNT(*) AS total_rows, SUM(revenue) AS total_revenue FROM stg_sales;

-- 3.2 Rows per row_type (must match Power Query)
-- Expected: Sale 1,015,074 | Cancellation 17,972 | StockAdjustment 5,914 |
--           NonProductCharge 5,721 | GiftVoucher 100 | ZeroPriceItem 61 | AccountingEntry 6
SELECT row_type, COUNT(*) AS num_rows
FROM stg_sales
GROUP BY row_type
ORDER BY num_rows DESC;

-- 3.3 Column-level checks
-- Expected: total_rows 1,044,848 | null_customer 235,287 | null_description 4,275 |
--           distinct_stock_code 5,132 | distinct_country 43 | distinct_std_country 43 |
--           not_map_ready 2,518 | first_date 2009-12-01 07:45:00 | last_date 2011-12-09 12:50:00
-- Note: distinct_description is 5,631 here vs 5,655 in Power Query (see 3.5).
SELECT
  COUNT(*)                          AS total_rows,
  SUM(customer_id IS NULL)          AS null_customer,
  SUM(description IS NULL)          AS null_description,
  COUNT(DISTINCT stock_code)        AS distinct_stock_code,
  COUNT(DISTINCT description)       AS distinct_description,
  COUNT(DISTINCT country)           AS distinct_country,
  COUNT(DISTINCT standard_country)  AS distinct_std_country,
  SUM(map_ready = 0)                AS not_map_ready,
  MIN(invoice_date)                 AS first_date,
  MAX(invoice_date)                 AS last_date
FROM stg_sales;

-- 3.4 Purity of Sale rows. Expected: min_qty 1, min_price 0.001 (17 rows at 0.001, all code PADS)
SELECT MIN(quantity) AS min_qty, MIN(price) AS min_price
FROM stg_sales
WHERE row_type = 'Sale';

-- 3.5 Why distinct descriptions differ between tools.
-- MySQL's default collation is case-INsensitive, Power Query is case-sensitive.
-- COLLATE utf8mb4_bin forces a case-exact comparison.
-- Expected: extra_distinct = 24 (5,655 - 5,631)
SELECT SUM(case_variants - 1) AS extra_distinct
FROM (
  SELECT COUNT(DISTINCT description COLLATE utf8mb4_bin) AS case_variants
  FROM stg_sales
  WHERE description IS NOT NULL
  GROUP BY LOWER(description)
  HAVING case_variants > 1
) t;

-- 3.6 Is price a UNIT price? (assumption O3)
-- If price were a line total it would RISE with quantity. Instead the average falls:
--   85099B: 3.03 (1 unit) -> 2.84 (2-5) -> 2.10 (6-24) -> 1.83 (25+)
--   85123A: 3.97 -> 3.43 -> 3.00 -> 2.59
--   22423 : 15.52 -> 14.24 -> 12.67 -> 11.80
-- Consistent with a unit price and volume discounts. Verified on 3 products (13,720 Sale lines).
SELECT stock_code,
       CASE WHEN quantity = 1               THEN '1'
            WHEN quantity BETWEEN 2 AND 5   THEN '2-5'
            WHEN quantity BETWEEN 6 AND 24  THEN '6-24'
            ELSE '25+' END                  AS qty_band,
       COUNT(*)                             AS num_rows,
       ROUND(AVG(price), 2)                 AS avg_price,
       MIN(price)                           AS min_price,
       MAX(price)                           AS max_price
FROM stg_sales
WHERE row_type = 'Sale'
  AND stock_code IN ('85123A', '22423', '85099B')
GROUP BY stock_code, qty_band
ORDER BY stock_code, MIN(quantity);

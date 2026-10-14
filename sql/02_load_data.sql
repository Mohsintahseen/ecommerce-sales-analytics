-- =====================================================================
-- 02_load_data.sql
-- Purpose  : Bulk-load sales_clean.csv into stg_sales.
-- Run order: 2 of 10
-- HOW TO RUN (Windows Command Prompt, not the Workbench import wizard, which is slow):
--     set "PATH=%PATH%;C:\Program Files\MySQL\MySQL Server 8.0\bin"
--     mysql -u root -p --local-infile=1 ecommerce
--   Then paste the statement below.
-- REQUIREMENTS: SHOW VARIABLES LIKE 'local_infile';  must return ON.
-- EDIT THE PATH below to where sales_clean.csv is on YOUR machine (use forward slashes).
-- The CSV is not stored in the repository (about 124 MB); see the README for how to rebuild it
-- from the Power Query export.
-- If you must re-run the load, first run:  TRUNCATE TABLE stg_sales;
-- WARNING  : with LOCAL, MySQL turns many errors into warnings, so always check the
--            result line (Skipped / Warnings) and the validation queries in 03.
-- =====================================================================

USE ecommerce;

LOAD DATA LOCAL INFILE 'C:/path/to/sales_clean.csv'      -- <-- EDIT THIS PATH
INTO TABLE stg_sales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES                                            -- skip the header row
(line_id, invoice, stock_code, @description, quantity, invoice_date, price,
 @customer_id, country, revenue, row_type, standard_country, @map_ready)
SET description = NULLIF(@description, ''),               -- empty text -> real NULL
    customer_id = NULLIF(@customer_id, ''),
    map_ready   = (@map_ready = 'TRUE');                  -- TRUE/FALSE text -> 1/0

-- Expected: Records: 1044848  Deleted: 0  Skipped: 0  Warnings: 0

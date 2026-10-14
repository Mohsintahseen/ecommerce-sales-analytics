-- =====================================================================
-- 04_flags.sql
-- Purpose  : Add two flag columns. NOTHING IS DELETED. Each KPI chooses
--            which flagged rows to include or exclude.
--            R07 is_duplicate      : exact duplicate rows
--            R14 is_quick_reversal : a sale cancelled within 24 hours
-- Run order: 4 of 10
-- Practical : heavy self-joins and sorts on 1M rows hit Workbench's read timeout
--             (Error 2013). Run this file from the mysql command-line client.
--             If Error 1175 (safe update mode): SET SQL_SAFE_UPDATES = 0;
-- =====================================================================

USE ecommerce;

-- ---------------------------------------------------------------------
-- R07: exact duplicates over the 8 original columns (case-exact on description).
-- The first occurrence (lowest line_id) stays unflagged.
-- ---------------------------------------------------------------------
ALTER TABLE stg_sales ADD COLUMN is_duplicate TINYINT(1) NOT NULL DEFAULT 0;   -- run once

UPDATE stg_sales s
JOIN (
  SELECT line_id,
         ROW_NUMBER() OVER (
           PARTITION BY invoice, stock_code,
                        description COLLATE utf8mb4_bin,
                        quantity, invoice_date, price, customer_id, country
           ORDER BY line_id
         ) AS rn
  FROM stg_sales
) d ON d.line_id = s.line_id
SET s.is_duplicate = (d.rn > 1)
WHERE s.line_id > 0;

-- Expected: is_duplicate 0 = 1,033,036 | 1 = 11,812 (matches Power Query Remove Duplicates)
SELECT is_duplicate, COUNT(*) AS num_rows, ROUND(SUM(revenue), 2) AS revenue
FROM stg_sales
GROUP BY is_duplicate;
-- The 11,812 duplicate rows carry about 54,228.42 of revenue (0.29% of total) per the Power Query check.

-- ---------------------------------------------------------------------
-- R14: quick reversals.
-- Definition (ASSUMPTION): a cancellation line that has a sale line from the SAME customer,
-- SAME product, SAME price and the exactly OPPOSITE quantity within the previous 24 hours.
-- Lower bound: partial cancellations and other windows are not caught.
-- ---------------------------------------------------------------------

-- Step 1 (read-only): size the pattern.  Result: cancel_lines 1,351 | sale_lines 1,429
SELECT COUNT(DISTINCT c.line_id) AS cancel_lines,
       COUNT(DISTINCT s.line_id) AS sale_lines
FROM stg_sales c
JOIN stg_sales s
  ON  s.customer_id = c.customer_id
  AND s.stock_code  = c.stock_code
  AND s.price       = c.price
  AND s.quantity    = -c.quantity
  AND s.row_type    = 'Sale'
  AND s.invoice_date BETWEEN c.invoice_date - INTERVAL 1 DAY AND c.invoice_date
WHERE c.row_type = 'Cancellation';

-- Step 2 (read-only): the largest cases.
-- Top two: C581484 / 581483 (80,995 units at 2.08 = 168,469.60) and C541433 / 541431 (74,215 at 1.04 = 77,183.60)
SELECT c.invoice AS cancel_invoice, s.invoice AS sale_invoice, c.stock_code,
       c.quantity, c.price, s.invoice_date AS sale_time, c.invoice_date AS cancel_time
FROM stg_sales c
JOIN stg_sales s
  ON  s.customer_id = c.customer_id
  AND s.stock_code  = c.stock_code
  AND s.price       = c.price
  AND s.quantity    = -c.quantity
  AND s.row_type    = 'Sale'
  AND s.invoice_date BETWEEN c.invoice_date - INTERVAL 1 DAY AND c.invoice_date
WHERE c.row_type = 'Cancellation'
ORDER BY ABS(c.quantity) DESC
LIMIT 5;

-- Step 3: add the flag and set it on both sides of each matched pair.
ALTER TABLE stg_sales ADD COLUMN is_quick_reversal TINYINT(1) NOT NULL DEFAULT 0;   -- run once

UPDATE stg_sales t
JOIN (
  SELECT s.line_id
  FROM stg_sales c
  JOIN stg_sales s
    ON  s.customer_id = c.customer_id
    AND s.stock_code  = c.stock_code
    AND s.price       = c.price
    AND s.quantity    = -c.quantity
    AND s.row_type    = 'Sale'
    AND s.invoice_date BETWEEN c.invoice_date - INTERVAL 1 DAY AND c.invoice_date
  WHERE c.row_type = 'Cancellation'
  UNION
  SELECT c.line_id
  FROM stg_sales c
  JOIN stg_sales s
    ON  s.customer_id = c.customer_id
    AND s.stock_code  = c.stock_code
    AND s.price       = c.price
    AND s.quantity    = -c.quantity
    AND s.row_type    = 'Sale'
    AND s.invoice_date BETWEEN c.invoice_date - INTERVAL 1 DAY AND c.invoice_date
  WHERE c.row_type = 'Cancellation'
) m ON m.line_id = t.line_id          -- derived table avoids MySQL error 1093
SET t.is_quick_reversal = 1;

-- Expected: Sale 1,429 rows / 364,141.55 | Cancellation 1,351 rows / -354,615.04
SELECT row_type, COUNT(*) AS flagged_rows, ROUND(SUM(revenue), 2) AS revenue
FROM stg_sales
WHERE is_quick_reversal = 1
GROUP BY row_type;

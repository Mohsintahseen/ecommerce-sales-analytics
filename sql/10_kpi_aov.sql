-- =====================================================================
-- 10_kpi_aov.sql
-- KPI : Average Order Value (AOV)
-- Run order: 10 of 10
-- Definition : AOV = Gross Sales / number of orders. An order is a distinct invoice
--              with row_type = 'Sale' (cancellations, charges and adjustments are excluded).
-- Grain      : one row per invoice (collapsed from invoice lines).
-- =====================================================================

USE ecommerce;

-- Result : orders 39,516 | mean_aov 498.55 | median_aov 301.80 | mean_aov_excl_flagged 490.51
-- Reading: the mean is about 65% above the median, so a few very large (wholesale) orders
--          pull the mean up. Report the median as the typical order alongside the mean.
-- Note   : the last column drops every invoice that contains a flagged quick-reversal line
--          (a blunt approximation: the whole invoice is removed).
-- Heavy query: run from the mysql command-line client if Workbench times out.
WITH inv AS (
  SELECT invoice,
         SUM(revenue)             AS inv_value,
         MAX(is_quick_reversal)   AS has_qr
  FROM stg_sales
  WHERE row_type = 'Sale'
  GROUP BY invoice
),
ranked AS (
  SELECT inv_value,
         ROW_NUMBER() OVER (ORDER BY inv_value) AS rn,
         COUNT(*)     OVER ()                   AS cnt
  FROM inv
)
SELECT (SELECT COUNT(*) FROM inv)                                               AS orders,
       (SELECT ROUND(AVG(inv_value), 2) FROM inv)                               AS mean_aov,
       (SELECT ROUND(AVG(inv_value), 2) FROM ranked
         WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2)))               AS median_aov,
       (SELECT ROUND(AVG(inv_value), 2) FROM inv WHERE has_qr = 0)              AS mean_aov_excl_flagged;

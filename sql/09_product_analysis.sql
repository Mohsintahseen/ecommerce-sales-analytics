-- =====================================================================
-- 09_product_analysis.sql
-- Business question : Which products drive revenue, and how concentrated is it?
-- Run order: 9 of 10
-- Product = stock_code. There is no category field; any grouping would be an assumption.
-- Product name rule (R11): most frequent description among Sale rows, ties broken by most recent.
-- =====================================================================

USE ecommerce;

-- Top 10 products by net product revenue, with names chosen by the R11 rule.
-- Result: top 10 = 1,445,676.85 = 7.62% of net product revenue.
--   22423  REGENCY CAKESTAND 3 TIER          314,513.47 (1.66%)
--   85123A WHITE HANGING HEART T-LIGHT HOLDER 252,122.83 (1.33%)
--   85099B JUMBO BAG RED RETROSPOT           180,830.85 (0.95%)  ... (see Cleaning_Log / README)
-- Charges and vouchers are excluded because only Sale and Cancellation rows are used.
-- Caution: 85099B and 22386 (jumbo bags) are separate codes of one product family.
-- Heavy query: run from the mysql command-line client if Workbench times out.
WITH top AS (
  SELECT stock_code,
         ROUND(SUM(revenue), 2)                                       AS net_rev,
         SUM(CASE WHEN row_type = 'Sale' THEN quantity END)           AS units_sold,
         ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2)     AS pct_of_total
  FROM stg_sales
  WHERE row_type IN ('Sale', 'Cancellation')
  GROUP BY stock_code
  ORDER BY net_rev DESC
  LIMIT 10
),
names AS (
  SELECT s.stock_code, s.description,
         ROW_NUMBER() OVER (PARTITION BY s.stock_code
                            ORDER BY COUNT(*) DESC, MAX(s.invoice_date) DESC) AS rn
  FROM stg_sales s
  JOIN top t ON t.stock_code = s.stock_code
  WHERE s.row_type = 'Sale' AND s.description IS NOT NULL
  GROUP BY s.stock_code, s.description
)
SELECT t.stock_code, n.description, t.net_rev, t.units_sold, t.pct_of_total
FROM top t
JOIN names n ON n.stock_code = t.stock_code AND n.rn = 1
ORDER BY t.net_rev DESC;

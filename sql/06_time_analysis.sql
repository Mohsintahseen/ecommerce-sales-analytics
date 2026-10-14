-- =====================================================================
-- 06_time_analysis.sql
-- Business question : When does revenue peak, and how strong is the seasonality?
-- Run order: 6 of 10
-- Caution : December 2011 covers only 1-9 Dec. Do not compare it with other months.
-- =====================================================================

USE ecommerce;

-- Monthly gross sales, cancellations, net product revenue and orders.
-- Expected: 25 rows; sums = 19,700,849.46 / -719,677.94 / 18,981,171.52 (within a penny of rounding);
--           sum of orders = 39,516.
-- Findings: Sep-Nov 2010 = 36% of 2010 net revenue; November is the peak
--           (Nov 2010 1,400,559.24; Nov 2011 1,432,697.49); December is far lower.
--           Jan-Nov 2011 vs Jan-Nov 2010: about +2.2%.
-- Jan 2011 and Dec 2011 cancellations are inflated by two giant reversed orders (see 04_flags.sql).
SELECT DATE_FORMAT(invoice_date, '%Y-%m')                                             AS month,
       ROUND(SUM(CASE WHEN row_type = 'Sale' THEN revenue END), 2)                    AS gross_sales,
       ROUND(SUM(CASE WHEN row_type = 'Cancellation' THEN revenue END), 2)            AS cancellations,
       ROUND(SUM(CASE WHEN row_type IN ('Sale','Cancellation') THEN revenue END), 2)  AS net_product_revenue,
       COUNT(DISTINCT CASE WHEN row_type = 'Sale' THEN invoice END)                   AS orders
FROM stg_sales
GROUP BY DATE_FORMAT(invoice_date, '%Y-%m')
ORDER BY month;

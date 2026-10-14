-- =====================================================================
-- 08_customer_analysis.sql
-- Business questions : Who are the top customers and how dependent are we on them?
--                      What share of revenue has no customer ID?
--                      Do customers come back?
-- Run order: 8 of 10
-- Limits : customer KPIs cover only rows with a customer_id (about 77.5% of rows,
--          86.5% of net product revenue). Customer ids are text.
-- =====================================================================

USE ecommerce;

-- 8.1 Top 10 customers by net product revenue, with share of identified-customer revenue.
-- Result: top 10 = 2,660,456.26 = 16.21% of identified revenue (14.0% of all net product revenue).
--   18102 578,408.64 (3.52%) | 14646 523,202.74 | 14156 297,961.56 | 14911 258,601.47 | 17450 233,803.91 | ...
SELECT customer_id,
       ROUND(SUM(revenue), 2)                                          AS net_product_revenue,
       COUNT(DISTINCT CASE WHEN row_type = 'Sale' THEN invoice END)    AS orders,
       MIN(invoice_date)                                               AS first_purchase,
       MAX(invoice_date)                                               AS last_purchase,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2)        AS pct_of_identified
FROM stg_sales
WHERE row_type IN ('Sale', 'Cancellation')
  AND customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY net_product_revenue DESC
LIMIT 10;
-- Caution: the data starts on 1 Dec 2009, so "first_purchase" means "first seen in this data".

-- 8.2 Coverage: how much revenue has no customer id?
-- Result: customers 5,875 | identified 16,411,804.75 | unidentified 2,569,366.77 (13.5%) | total 18,981,171.52
SELECT COUNT(DISTINCT customer_id)                                                    AS customers,
       ROUND(SUM(CASE WHEN customer_id IS NOT NULL THEN revenue END), 2)              AS identified_revenue,
       ROUND(SUM(CASE WHEN customer_id IS NULL THEN revenue END), 2)                  AS unidentified_revenue,
       ROUND(SUM(revenue), 2)                                                         AS total_revenue
FROM stg_sales
WHERE row_type IN ('Sale', 'Cancellation');

-- 8.3 Repeat customers: customers grouped by number of distinct Sale invoices.
-- Result: 5,852 customers; 1 order 1,618 | 2-5 orders 2,448 | 6-10 orders 922 | 11+ orders 864.
--   Repeat rate (2+ orders) = 4,234 / 5,852 = 72.4%.
--   11+ orders: 14.8% of customers, 64.5% of Sale revenue (11,045,932.33 of 17,124,835.99).
-- Limits: not a retention rate; late-joining customers have had less time to reorder.
-- Heavy query: run from the mysql command-line client if Workbench times out.
SELECT CASE WHEN orders = 1   THEN '1 order'
            WHEN orders <= 5  THEN '2-5 orders'
            WHEN orders <= 10 THEN '6-10 orders'
            ELSE '11+ orders' END          AS order_bucket,
       COUNT(*)                            AS customers,
       ROUND(SUM(sale_revenue), 2)         AS sale_revenue
FROM (
  SELECT customer_id,
         COUNT(DISTINCT invoice) AS orders,
         SUM(revenue)            AS sale_revenue
  FROM stg_sales
  WHERE row_type = 'Sale'
    AND customer_id IS NOT NULL
  GROUP BY customer_id
) t
GROUP BY order_bucket
ORDER BY MIN(orders);

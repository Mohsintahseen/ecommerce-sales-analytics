-- =====================================================================
-- 07_country_analysis.sql
-- Business questions : Where does revenue come from? How dependent are we on the UK?
--                      How concentrated is each country on a single customer?
-- Run order: 7 of 10
-- Uses standard_country (EIRE shown as Ireland, etc.). Original Country is kept in the table.
-- =====================================================================

USE ecommerce;

-- 7.1 Net product revenue by country with share of total (window function over all countries).
-- Expected: 43 rows; sum of net_product_revenue = 18,981,171.52; sum of orders = 39,516.
-- Findings: UK 16,220,998.80 = 85.46%; Ireland 3.18%; Netherlands 2.88%; Germany 1.98%; France 1.55%.
-- The four non-country values (Unspecified, European Community, West Indies, Channel Islands)
-- total 54,452.88 = 0.29% of net revenue.
SELECT standard_country,
       ROUND(SUM(revenue), 2)                                          AS net_product_revenue,
       COUNT(DISTINCT CASE WHEN row_type = 'Sale' THEN invoice END)    AS orders,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 2)        AS pct_of_total
FROM stg_sales
WHERE row_type IN ('Sale', 'Cancellation')
GROUP BY standard_country
ORDER BY net_product_revenue DESC;

-- 7.2 Biggest customer in each of the 8 largest countries (CTE + ROW_NUMBER).
-- Percentage is of IDENTIFIED-customer revenue in that country.
-- Result: Netherlands 14646 = 95.8% | Australia 12415 = 86.0% | Ireland 14156 = 52.5% |
--         Switzerland 25.0% | Spain 22.6% | France 11.0% | Germany 8.9% | UK 18102 = 4.2%
-- Heavy query: run from the mysql command-line client if Workbench times out (Error 2013).
WITH cc AS (
  SELECT standard_country, customer_id, SUM(revenue) AS rev
  FROM stg_sales
  WHERE row_type IN ('Sale', 'Cancellation')
    AND customer_id IS NOT NULL
  GROUP BY standard_country, customer_id
),
ranked AS (
  SELECT standard_country, customer_id, rev,
         SUM(rev) OVER (PARTITION BY standard_country)                       AS country_rev,
         ROW_NUMBER() OVER (PARTITION BY standard_country ORDER BY rev DESC) AS rn
  FROM cc
)
SELECT standard_country,
       customer_id,
       ROUND(rev, 2)                       AS top_customer_rev,
       ROUND(country_rev, 2)               AS country_identified_rev,
       ROUND(100 * rev / country_rev, 1)   AS top_customer_pct
FROM ranked
WHERE rn = 1
ORDER BY country_rev DESC
LIMIT 8;

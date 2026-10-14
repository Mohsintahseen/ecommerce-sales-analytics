-- =====================================================================
-- 11_data_model.sql
-- Purpose  : Build the star schema used by Power BI.
--              fact_sales   (view)  : one row per invoice line
--              dim_product          : one row per stock code
--              dim_customer         : one row per customer
--              dim_country          : one row per standardized country
--              dim_row_type         : one row per row type (which KPI uses it)
--              dim_date             : built in Power BI with DAX (Phase 7)
-- Run order: 11 (after 04_flags.sql, which creates is_duplicate and is_quick_reversal)
-- Relationships (all one-to-many; filters flow from the dimension to the fact):
--   dim_product.stock_code       -> fact_sales.stock_code
--   dim_customer.customer_id     -> fact_sales.customer_id   (NULL customer_id = 22.5% of rows, no match)
--   dim_country.standard_country -> fact_sales.standard_country
--   dim_row_type.row_type        -> fact_sales.row_type
--   dim_date.date                -> fact_sales.invoice_day
-- Practical: the product and customer inserts group 1M rows; run from the mysql
--            command-line client if Workbench times out (Error 2013).
-- =====================================================================

USE ecommerce;

-- ---------------------------------------------------------------------
-- dim_product : product name rule R11 = most frequent description among Sale rows,
-- ties broken by the most recent. Staff notes on adjustment rows are never used as names.
-- ---------------------------------------------------------------------
CREATE TABLE dim_product (
  stock_code    VARCHAR(30)  NOT NULL,
  product_name  VARCHAR(255) NULL,
  PRIMARY KEY (stock_code)
);

INSERT INTO dim_product (stock_code, product_name)
SELECT c.stock_code, n.description
FROM (SELECT DISTINCT stock_code FROM stg_sales) c
LEFT JOIN (
  SELECT stock_code, description
  FROM (
    SELECT stock_code,
           description COLLATE utf8mb4_bin AS description,
           ROW_NUMBER() OVER (PARTITION BY stock_code
                              ORDER BY COUNT(*) DESC, MAX(invoice_date) DESC) AS rn
    FROM stg_sales
    WHERE row_type = 'Sale' AND description IS NOT NULL
    GROUP BY stock_code, description COLLATE utf8mb4_bin
  ) r
  WHERE rn = 1
) n ON n.stock_code = c.stock_code;

-- 407 codes have no name (R17): 379 appear only in stock-adjustment rows, 14 only in
-- cancellations, the rest are charges, vouchers or accounting entries.
-- product_label never shows (Blank) in a chart.
ALTER TABLE dim_product
  ADD COLUMN product_label VARCHAR(255) NULL,
  ADD COLUMN has_sales     TINYINT(1)   NOT NULL DEFAULT 0;      -- run once

UPDATE dim_product
SET product_label = COALESCE(product_name, stock_code),
    has_sales     = (product_name IS NOT NULL)
WHERE stock_code <> '';

-- Expected: products 5,132 | named 4,725 | unnamed 407 | null_labels 0
-- (After 12_patches.sql removes the trailing-space duplicate '47503J ' (R05b): products 5,131 | named 4,724.)
SELECT COUNT(*) AS products, SUM(has_sales) AS named, SUM(has_sales = 0) AS unnamed,
       SUM(product_label IS NULL) AS null_labels
FROM dim_product;

-- Expected: orphan_rows 0
SELECT COUNT(*) AS orphan_rows
FROM stg_sales s LEFT JOIN dim_product p ON p.stock_code = s.stock_code
WHERE p.stock_code IS NULL;

-- ---------------------------------------------------------------------
-- dim_customer : country rule R13 = most frequent standard_country per customer,
-- ties broken by the most recent. n_countries keeps the 13 multi-country customers visible.
-- Revenue by country still uses the country on each fact row.
-- ---------------------------------------------------------------------
CREATE TABLE dim_customer (
  customer_id       VARCHAR(10) NOT NULL,
  standard_country  VARCHAR(40) NOT NULL,
  n_countries       TINYINT     NOT NULL,
  PRIMARY KEY (customer_id)
);

INSERT INTO dim_customer (customer_id, standard_country, n_countries)
SELECT customer_id, standard_country, n_countries
FROM (
  SELECT customer_id,
         standard_country,
         ROW_NUMBER() OVER (PARTITION BY customer_id
                            ORDER BY COUNT(*) DESC, MAX(invoice_date) DESC) AS rn,
         COUNT(*)     OVER (PARTITION BY customer_id)                       AS n_countries
  FROM stg_sales
  WHERE customer_id IS NOT NULL
  GROUP BY customer_id, standard_country
) r
WHERE rn = 1;

-- Expected: customers 5,942 | multi_country 13 | distinct_in_fact 5,942 | orphan_rows 0
-- Spot check: 12422 -> Switzerland, 12455 -> Cyprus, 12394 -> Belgium
SELECT COUNT(*) AS customers, SUM(n_countries > 1) AS multi_country FROM dim_customer;
SELECT COUNT(DISTINCT customer_id) AS distinct_in_fact FROM stg_sales WHERE customer_id IS NOT NULL;
SELECT COUNT(*) AS orphan_rows
FROM stg_sales s LEFT JOIN dim_customer c ON c.customer_id = s.customer_id
WHERE s.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- ---------------------------------------------------------------------
-- dim_country : map_ready = 0 for Unspecified, European Community, West Indies,
-- Channel Islands (2,518 rows, 0.29% of net revenue) so a map can skip them.
-- ---------------------------------------------------------------------
CREATE TABLE dim_country (
  standard_country VARCHAR(40) NOT NULL,
  map_ready        TINYINT(1)  NOT NULL,
  PRIMARY KEY (standard_country)
);

INSERT INTO dim_country (standard_country, map_ready)
SELECT standard_country, MAX(map_ready)
FROM stg_sales
GROUP BY standard_country;

-- ---------------------------------------------------------------------
-- dim_row_type : records which row types count toward each KPI.
-- Net Product Revenue = Sale + Cancellation. Orders = Sale invoices only.
-- ---------------------------------------------------------------------
CREATE TABLE dim_row_type (
  row_type                VARCHAR(20)  NOT NULL,
  description             VARCHAR(100) NOT NULL,
  in_net_product_revenue  TINYINT(1)   NOT NULL,
  in_orders               TINYINT(1)   NOT NULL,
  PRIMARY KEY (row_type)
);

INSERT INTO dim_row_type VALUES
  ('Sale',             'Normal sale line',                                        1, 1),
  ('Cancellation',     'Cancellation (invoice starts with C)',                    1, 0),
  ('NonProductCharge', 'Postage, fees, manual, discount, samples, packing, tests', 0, 0),
  ('GiftVoucher',      'Gift voucher codes',                                      0, 0),
  ('AccountingEntry',  'Bad-debt adjustments (invoice starts with A)',            0, 0),
  ('StockAdjustment',  'Price 0 and no customer',                                 0, 0),
  ('ZeroPriceItem',    'Price 0 with a customer',                                 0, 0);

-- ---------------------------------------------------------------------
-- fact_sales : a view with only the columns Power BI needs.
-- description, country and map_ready now live in the dimensions.
-- invoice_day is a pure DATE so dim_date can relate to it.
-- ---------------------------------------------------------------------
CREATE VIEW fact_sales AS
SELECT line_id, invoice, stock_code, customer_id, standard_country, row_type,
       invoice_date, DATE(invoice_date) AS invoice_day,
       quantity, price, revenue, is_duplicate, is_quick_reversal
FROM stg_sales;

-- Expected: fact_rows 1,044,848 | fact_revenue 18,909,762.118 | countries 43 | row_types 7 |
--           orphan_country 0 | orphan_row_type 0 | orphan_product 0
SELECT
  (SELECT COUNT(*) FROM fact_sales)                                   AS fact_rows,
  (SELECT ROUND(SUM(revenue), 3) FROM fact_sales)                     AS fact_revenue,
  (SELECT COUNT(*) FROM dim_country)                                  AS countries,
  (SELECT COUNT(*) FROM dim_row_type)                                 AS row_types,
  (SELECT COUNT(*) FROM fact_sales f LEFT JOIN dim_country d
     ON d.standard_country = f.standard_country
     WHERE d.standard_country IS NULL)                                AS orphan_country,
  (SELECT COUNT(*) FROM fact_sales f LEFT JOIN dim_row_type d
     ON d.row_type = f.row_type
     WHERE d.row_type IS NULL)                                        AS orphan_row_type,
  (SELECT COUNT(*) FROM fact_sales f LEFT JOIN dim_product d
     ON d.stock_code = f.stock_code
     WHERE d.stock_code IS NULL)                                      AS orphan_product;

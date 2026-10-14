-- =====================================================================
-- 01_create_tables.sql
-- Project  : E-Commerce Data Analytics (UCI Online Retail II, CC BY 4.0)
-- Purpose  : Create the database and the staging table that receives the
--            cleaned CSV exported from Power Query (Export_Sales query).
-- Run order: 1 of 10
-- Notes    : * Identifiers are text (VARCHAR), never numbers.
--            * Money is DECIMAL, never FLOAT (avoids floating-point residue).
--            * Only description and customer_id may be NULL (real missing values).
--            * map_ready: 1 = TRUE, 0 = FALSE (MySQL has no true Boolean).
-- =====================================================================

CREATE DATABASE IF NOT EXISTS ecommerce
  CHARACTER SET utf8mb4;

USE ecommerce;

CREATE TABLE stg_sales (
  line_id           INT UNSIGNED  NOT NULL,   -- unique row id created in Power Query (1..1,044,848)
  invoice           VARCHAR(12)   NOT NULL,   -- order id; prefix C = cancellation, A = accounting adjustment
  stock_code        VARCHAR(30)   NOT NULL,   -- product code (upper-cased in Power Query)
  description       VARCHAR(255)  NULL,       -- product name OR staff note (trimmed)
  quantity          INT           NOT NULL,
  invoice_date      DATETIME      NOT NULL,
  price             DECIMAL(12,3) NOT NULL,   -- unit price in GBP (assumption, see Cleaning_Log O3)
  customer_id       VARCHAR(10)   NULL,       -- NULL for about 22.5% of rows
  country           VARCHAR(40)   NOT NULL,   -- original country value
  revenue           DECIMAL(14,3) NOT NULL,   -- quantity * price
  row_type          VARCHAR(20)   NOT NULL,   -- Sale, Cancellation, NonProductCharge, ...
  standard_country  VARCHAR(40)   NOT NULL,   -- EIRE -> Ireland, RSA -> South Africa, ...
  map_ready         TINYINT(1)    NOT NULL,   -- 0 for Unspecified, European Community, West Indies, Channel Islands
  PRIMARY KEY (line_id)
);

DESCRIBE stg_sales;   -- expect 13 rows; line_id = PRI; NULL allowed only on description and customer_id

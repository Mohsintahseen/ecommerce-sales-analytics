-- =====================================================================
-- 05_revenue_reconciliation.sql
-- Purpose  : Split total revenue by row_type and confirm the parts add up to the
--            total BEFORE any KPI is calculated. Every later KPI sits on this base.
-- Run order: 5 of 10
-- Definitions used in all later scripts:
--   Gross Sales         = SUM(revenue) where row_type = 'Sale'
--   Net Product Revenue = SUM(revenue) where row_type IN ('Sale','Cancellation')
-- =====================================================================

USE ecommerce;

-- Expected (num_rows / invoices / revenue):
--   Sale             1,015,074 / 39,516 / 19,700,849.46
--   Cancellation        17,972 /  7,405 /   -719,677.94
--   NonProductCharge     5,721 /  5,452 /     74,518.07
--   GiftVoucher            100 /     93 /      1,686.61
--   AccountingEntry          6 /      6 /   -147,614.08
--   StockAdjustment      5,914 /  5,280 /          0.00
--   ZeroPriceItem           61 /     52 /          0.00
--   TOTAL            1,044,848 / 53,628 / 18,909,762.12
-- (Invoices cannot be added down the column: one invoice can hold lines of several types.)
-- Net Product Revenue = 19,700,849.46 - 719,677.94 = 18,981,171.52.
-- Cancellations remove about 3.65% of Gross Sales.
SELECT COALESCE(row_type, 'TOTAL')    AS row_type,
       COUNT(*)                        AS num_rows,
       COUNT(DISTINCT invoice)         AS invoices,
       ROUND(SUM(revenue), 2)          AS revenue
FROM stg_sales
GROUP BY row_type WITH ROLLUP;

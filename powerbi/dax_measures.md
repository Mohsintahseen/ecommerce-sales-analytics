# DAX measures: E-commerce analytics model

Model: `fact_sales` (view, 1,044,848 invoice lines) filtered by `dim_product`, `dim_customer`, `dim_country`, `dim_row_type` and `dim_date`. All relationships are one-to-many with single-direction filtering (dimension to fact).
Every measure below was validated against an independent MySQL result before being kept (see the "Validated" column).

## Supporting tables

```DAX
_Measures = { BLANK () }          -- holder table for measures; its Value column is hidden
```

```DAX
dim_date =
VAR _last = MAX ( fact_sales[invoice_day] )
RETURN
ADDCOLUMNS (
    CALENDAR ( DATE ( 2009, 12, 1 ), DATE ( 2011, 12, 31 ) ),
    "Year", YEAR ( [Date] ),
    "Month number", MONTH ( [Date] ),
    "Month name", FORMAT ( [Date], "mmm" ),
    "Year-month", FORMAT ( [Date], "yyyy-MM" ),
    "Complete month", IF ( EOMONTH ( [Date], 0 ) <= _last, "Complete", "Partial" )
)
```
Marked as the date table (761 rows); `Month name` sorted by `Month number`. December 2011 is a partial month (data ends 9 Dec 2011).

## Measures

```DAX
Gross Sales =
CALCULATE ( SUM ( fact_sales[revenue] ), fact_sales[row_type] = "Sale" )

Cancellations =
CALCULATE ( SUM ( fact_sales[revenue] ), fact_sales[row_type] = "Cancellation" )

Net Product Revenue =
CALCULATE ( SUM ( fact_sales[revenue] ), dim_row_type[in_net_product_revenue] = TRUE () )

Orders =
CALCULATE ( DISTINCTCOUNT ( fact_sales[invoice] ), dim_row_type[in_orders] = TRUE () )

AOV =
DIVIDE ( [Gross Sales], [Orders] )

Median AOV =
MEDIANX (
    FILTER ( VALUES ( fact_sales[invoice] ), NOT ISBLANK ( [Gross Sales] ) ),
    [Gross Sales]
)

Cancellation Rate =
DIVIDE ( -[Cancellations], [Gross Sales] )

Customers =
CALCULATE (
    DISTINCTCOUNTNOBLANK ( fact_sales[customer_id] ),
    dim_row_type[in_net_product_revenue] = TRUE ()
)

Net Product Revenue PY =
CALCULATE ( [Net Product Revenue], SAMEPERIODLASTYEAR ( dim_date[Date] ) )

Net Revenue YoY % =
DIVIDE ( [Net Product Revenue] - [Net Product Revenue PY], [Net Product Revenue PY] )

Net Revenue YoY % (like-for-like) =
VAR _y = SELECTEDVALUE ( dim_date[Year] )
VAR _months =
    CALCULATETABLE ( VALUES ( dim_date[Month number] ), dim_date[Complete month] = "Complete" )
VAR _n = COUNTROWS ( _months )
VAR _cur = CALCULATE ( [Net Product Revenue], dim_date[Complete month] = "Complete" )
VAR _py_n =
    CALCULATE (
        DISTINCTCOUNT ( dim_date[Month number] ),
        REMOVEFILTERS ( dim_date ),
        dim_date[Year] = _y - 1,
        TREATAS ( _months, dim_date[Month number] )
    )
VAR _py =
    CALCULATE (
        [Net Product Revenue],
        REMOVEFILTERS ( dim_date ),
        dim_date[Year] = _y - 1,
        TREATAS ( _months, dim_date[Month number] )
    )
RETURN
    IF ( NOT ISBLANK ( _y ) && _n > 0 && _n = _py_n, DIVIDE ( _cur - _py, _py ) )

Net Revenue % of Total =
DIVIDE ( [Net Product Revenue], CALCULATE ( [Net Product Revenue], ALLSELECTED () ) )

Country Rank =
RANKX ( ALLSELECTED ( dim_country[standard_country] ), [Net Product Revenue] )

Top 10 Customers Revenue =
SUMX ( TOPN ( 10, DISTINCT ( dim_customer[customer_id] ), [Net Product Revenue] ), [Net Product Revenue] )

Top 10 Customer Share =
DIVIDE (
    [Top 10 Customers Revenue],
    CALCULATE ( [Net Product Revenue], NOT ISBLANK ( fact_sales[customer_id] ) )
)

Customers with Orders =
COUNTROWS (
    FILTER (
        DISTINCT ( dim_customer[customer_id] ),
        CALCULATE ( DISTINCTCOUNT ( fact_sales[invoice] ), dim_row_type[in_orders] = TRUE () ) >= 1
    )
)

Repeat Customers =
COUNTROWS (
    FILTER (
        DISTINCT ( dim_customer[customer_id] ),
        CALCULATE ( DISTINCTCOUNT ( fact_sales[invoice] ), dim_row_type[in_orders] = TRUE () ) >= 2
    )
)

Repeat Customer Rate =
DIVIDE ( [Repeat Customers], [Customers with Orders] )
```

## Validated against MySQL

| Measure | Power BI | MySQL script |
|---|---|---|
| Gross Sales | £19,700,849.46 | 05_revenue_reconciliation.sql |
| Cancellations | -£719,677.94 | 05 |
| Net Product Revenue | £18,981,171.52 | 05 |
| Orders | 39,516 | 05 / 10 |
| AOV | £498.55 | 10_kpi_aov.sql |
| Median AOV | £301.80 | 10 |
| Cancellation Rate | 3.65% | 05 |
| Customers | 5,875 | 08_customer_analysis.sql |
| Net Revenue YoY % (like-for-like), 2011 | +2.19% | 06_time_analysis.sql (Jan-Nov 2011 vs Jan-Nov 2010) |
| UK share of Net Product Revenue | 85.46% | 07_country_analysis.sql |
| Top 10 Customer Share | 16.21% | 08 |
| Repeat Customer Rate | 72.35% (4,234 of 5,852) | 08 |

Monthly totals also matched the SQL monthly table for all 25 months.

## Lessons recorded while building

1. **An iterator works on the set you give it.** `MEDIANX ( VALUES ( fact_sales[invoice] ), ... )` first returned £188.25 because it also included the invoices with no Sale line. Filtering to invoices that have Sale revenue gave the SQL answer, £301.80.
2. **`DISTINCTCOUNT` counts a blank as a value.** Fact rows with no customer id produce a blank member, so `DISTINCTCOUNT` returned 5,876; `DISTINCTCOUNTNOBLANK` returned 5,875.
3. **Growth figures must compare like with like.** December 2011 (9 days) and the Total row give misleading YoY values; the like-for-like measure returns blank for them. An earlier draft that compared month counts across the whole shifted period would have blanked 2011, so the final version matches month numbers explicitly.
4. **Relationship keys must be exactly unique.** A trailing space in one stock code was accepted by MySQL but rejected by Power BI (see sql/12_patches.sql, rule R05b).

## Measures and columns added while building the dashboard

```DAX
Net Product Revenue (complete months) =
CALCULATE ( [Net Product Revenue], dim_date[Complete month] = "Complete" )

-- Text measures for KPI cards only (the newer Card visual has no "Display units" setting).
Net Product Revenue (card) = FORMAT ( [Net Product Revenue], "£#,##0.00" )
Orders (card) = FORMAT ( [Orders], "#,##0" )
Customers with Orders (card) = FORMAT ( [Customers with Orders], "#,##0" )

Country Share % =
DIVIDE ( [Net Product Revenue], CALCULATE ( [Net Product Revenue], ALL ( dim_country ) ) )

Gross Sales % of identified =
DIVIDE (
    [Gross Sales],
    CALCULATE ( [Gross Sales], ALL ( dim_customer ), NOT ISBLANK ( fact_sales[customer_id] ) )
)

Net Revenue (identified customers) =
CALCULATE ( [Net Product Revenue], NOT ISBLANK ( fact_sales[customer_id] ) )

Unidentified Revenue =
CALCULATE ( [Net Product Revenue], ISBLANK ( fact_sales[customer_id] ) )

Unidentified Share =
DIVIDE ( [Unidentified Revenue], [Net Product Revenue] )
```

Calculated columns in `dim_customer` (a customer attribute on a 5,942-row table, so a column is appropriate; it ignores the year slicer):

```DAX
Order Bucket =
VAR _orders =
    CALCULATE ( DISTINCTCOUNT ( fact_sales[invoice] ), dim_row_type[in_orders] = TRUE () )
RETURN
    SWITCH (
        TRUE (),
        _orders = 0, "No sale orders",
        _orders = 1, "1 order",
        _orders <= 5, "2-5 orders",
        _orders <= 10, "6-10 orders",
        "11+ orders"
    )

Order Bucket Sort =
VAR _orders =
    CALCULATE ( DISTINCTCOUNT ( fact_sales[invoice] ), dim_row_type[in_orders] = TRUE () )
RETURN
    SWITCH ( TRUE (), _orders = 0, 0, _orders = 1, 1, _orders <= 5, 2, _orders <= 10, 3, 4 )
```
`Order Bucket` is sorted by `Order Bucket Sort`.

Validated on the dashboard: Country Share % (UK 85.46%, Ireland 3.18%, Netherlands 2.88%); customers per order bucket 1,618 / 2,448 / 922 / 864 (total 5,852) with Sale revenue shares 3.26% / 17.06% / 15.17% / 64.50%; top 10 customers £2,660,456.26; unidentified revenue £2,569,366.77 (13.54%).

## More lessons recorded

5. **`ALLSELECTED` keeps visual-level filters.** On a table filtered to the top 10 countries, `Net Revenue % of Total` showed the UK as 87.53% (a share of the ten visible countries). `ALL ( dim_country )` ignores the Top N filter and gives 85.46%.
6. **A column sorted by another column carries a hidden grouping.** `ALL ( dim_customer[Order Bucket] )` still left the sort column filtering each row, so every bucket showed 100%. `ALL ( dim_customer )` clears both (this fits the symptom, and the fix worked).
7. **A text axis sorts by value unless told otherwise.** The monthly line chart first came out in revenue order, which made a seasonal business look like a steady decline. Sort the axis by the date column.
8. **Format each measure separately.** Two currency measures displayed as percentages (14310702.00%) because the wrong format was applied; the value was correct.

# Quality review

A review of the project as a senior analyst would do it, with the outcome of each point.

## Defects found by validation, and fixed

Every result was compared with an independent calculation (Power Query, MySQL, Power BI, or Excel). The comparisons found these defects:

| # | Defect | How it was found | Fix |
|---|---|---|---|
| 1 | The overlap test used a midnight cut-off, so it silently dropped the whole of 9 December. The two sheets matched each other because both were cut the same way | A filtered row count disagreed with the count expected from subtraction | Half-open date range (before the start of the next day); test repeated (22,523 rows, 1,088 invoices) |
| 2 | A leftover descending sort scrambled `LineID` order | The first row of the export was not the first date | Removed the step; added a "check first and last row" rule |
| 3 | One stock code had a trailing space, so two product rows existed for one product | Power BI rejected the relationship (duplicate key); MySQL and Power Query had accepted both | `TRIM` in MySQL and in Power Query (distinct stock codes 5,131 in both) |
| 4 | `MEDIANX` over all invoices gave £188.25 instead of £301.80 | Compared with the SQL median | Filtered the iterated set to invoices that have sale revenue |
| 5 | `DISTINCTCOUNT` returned 5,876 customers instead of 5,875 | Compared with SQL | `DISTINCTCOUNTNOBLANK` |
| 6 | "% of total" on a Top 10 table showed the UK as 87.53% instead of 85.46% | Compared with the SQL country table | `ALL ( dim_country )` for the denominator |
| 7 | Every customer bucket showed 100% of revenue | Compared with SQL | `ALL ( dim_customer )` instead of `ALL` on one column |
| 8 | The monthly line chart sorted by revenue and made a seasonal business look like a steady decline | Visual check | Sorted the axis by date |
| 9 | MySQL counted 5,631 distinct descriptions against 5,655 in Power Query | Compared tools | MySQL's default collation is case-insensitive; the 24 difference is case variants (confirmed with a case-exact query) |

## Outcome of the audit

| Level | Issue | Outcome |
|---|---|---|
| Critical | Price assumed to be a unit price | **Closed.** Average price falls as quantity rises for three products (13,720 sale lines). Verified on three products, not all |
| Critical | Power Query logic not saved as code | **Closed.** `power_query/` holds the pipeline with the expected numbers in each header |
| Critical | Dashboard file not backed up | **Closed** |
| Critical | Excel skills not evidenced | **Closed.** `IFS` rebuild of `RowType` on an 18,137-row sample gave 0 mismatches against Power Query; a PivotTable matched three row types to the penny; conditional formatting found 6,029 zero or negative prices; data validation found no invalid row types |
| Medium | Gross Sales and AOV include flagged duplicates and quick reversals | **Accepted and documented.** AOV is £498.55 including them, £490.51 excluding invoices with a quick reversal. No toggle built |
| Medium | SQL not rebuilt from an empty database in one run | **Not done.** Each script was run and validated in order; a clean full rebuild is listed as a future step |
| Medium | Open items (5 unclassified rows, "Korea", discount treatment) | **Closed or documented** (see the Cleaning_Log) |
| Minor | Query groups, scratch query, hidden technical columns, display folders | Housekeeping, done with the dashboard design pass |
| Optional | Tooltips, drill-through, bookmarks, ABC analysis, cohort retention | Future work |

## Known limits

- Two years of data cannot separate a trend from noise, and December 2011 is only nine days.
- No cost, delivery, review, category, wholesale flag, or channel data exists, so profit, delivery, satisfaction, product categories, and wholesale versus retail cannot be analysed.
- 13.5% of net product revenue has no customer ID, so customer measures cover 86.5% of revenue.
- Product names come from a rule (most frequent description among sale rows). 407 stock codes have no name.
- The 24-hour window for "quick reversals" and "Korea" meaning South Korea are assumptions.

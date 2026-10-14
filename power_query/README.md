# Power Query pipeline

Order of the queries (each file's header lists the rules it implements and the numbers it must reproduce):

| File | Query | Output rows |
|---|---|---|
| `00_SourceFilePath.pq` | parameter: path to `online_retail_II.xlsx` | n/a |
| `01_Sheet1_Clean.pq` | Sheet 1, filtered to before 1 Dec 2010 | 502,938 |
| `02_Sheet2_Clean.pq` | Sheet 2, all rows | 541,910 |
| `03_Sales_Combined.pq` | both sheets stacked, Revenue added | 1,044,848 |
| `04_Stg_Sales.pq` | cleaned staging table with `RowType`, `StandardCountry`, `MapReady`, `LineID` | 1,044,848 |
| `05_Export_Sales.pq` | 13-column table exported to `sales_clean.csv` for MySQL | 1,044,848 |

How to rebuild: create the parameter, create each query with **Home > Advanced Editor** (paste the file, without the comment header if you prefer), keep every query set to "Connection only" except when exporting `Export_Sales`, then follow `sql/01` to `sql/12`.

Download the raw data yourself from the UCI Machine Learning Repository (Online Retail II, CC BY 4.0). The raw file and the CSV are not stored in this repository.

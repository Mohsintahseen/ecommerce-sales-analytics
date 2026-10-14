// =====================================================================
// 05_Export_Sales.pq   (the table exported to sales_clean.csv for MySQL)
// Rules   : InvoiceDate becomes ISO text (yyyy-MM-dd HH:mm:ss). A CSV written from Excel uses
//           the machine's DD/MM/YYYY format, which MySQL would read the wrong way without an error.
//           Revenue is rounded to 3 decimals (prices have 3 decimals, e.g. 0.001) to remove
//           floating-point residue such as 324956.32000000688.
// Validate: 1,044,848 rows | 13 columns in this order: LineID, Invoice, StockCode, Description,
//           Quantity, InvoiceDate, Price, CustomerID, Country, Revenue, RowType,
//           StandardCountry, MapReady | row 1 InvoiceDate 2009-12-01 07:45:00 |
//           Revenue sum 18,909,762.12
// Export  : load to a worksheet, then File > Save As > CSV UTF-8. Set the query back to
//           "Connection only" afterwards. The CSV is not stored in the repository (about 124 MB).
// =====================================================================
let
    Source = Stg_Sales,
    #"Added Custom" = Table.AddColumn(Source, "InvoiceDateText", each DateTime.ToText([InvoiceDate], "yyyy-MM-dd HH:mm:ss")),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom",{"InvoiceDate"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Columns",{{"InvoiceDateText", "InvoiceDate"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns",{{"InvoiceDate", type text}}),
    #"Reordered Columns" = Table.ReorderColumns(#"Changed Type",{"LineID", "Invoice", "StockCode", "Description", "Quantity", "InvoiceDate", "Price", "CustomerID", "Country", "Revenue", "RowType", "StandardCountry", "MapReady"}),
    #"Rounded Off" = Table.TransformColumns(#"Reordered Columns",{{"Revenue", each Number.Round(_, 3), type number}})
in
    #"Rounded Off"

// =====================================================================
// 01_Sheet1_Clean.pq
// Source  : sheet "Year 2009-2010" of the UCI Online Retail II workbook (CC BY 4.0)
// Rules   : R01  Sheet 1 and Sheet 2 overlap for 1-9 Dec 2010 (identical at invoice level),
//                so Sheet 1 stops BEFORE 1 Dec 2010 and Sheet 2 supplies that window.
//                The cut-off is midnight (half-open range) because InvoiceDate has a time;
//                "up to 09/12/2010" would have dropped the whole of 9 December.
//         IDs (Invoice, StockCode, Customer ID) are TEXT: they are labels, not quantities.
//         "Customer ID" is renamed CustomerID (no spaces in column names).
// Validate: 502,938 rows (525,461 source data rows - 22,523 overlap rows).
// =====================================================================
let
    Source = Excel.Workbook(File.Contents(SourceFilePath), null, true),
    #"Year 2009-2010_Sheet" = Source{[Item="Year 2009-2010",Kind="Sheet"]}[Data],
    #"Promoted Headers" = Table.PromoteHeaders(#"Year 2009-2010_Sheet", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"Invoice", type text}, {"StockCode", type text}, {"Description", type text}, {"Quantity", Int64.Type}, {"InvoiceDate", type datetime}, {"Price", type number}, {"Customer ID", type text}, {"Country", type text}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"Customer ID", "CustomerID"}}),
    #"Filtered Rows" = Table.SelectRows(#"Renamed Columns", each [InvoiceDate] < #datetime(2010, 12, 1, 0, 0, 0))
in
    #"Filtered Rows"

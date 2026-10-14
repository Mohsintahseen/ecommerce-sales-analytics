// =====================================================================
// 02_Sheet2_Clean.pq
// Source  : sheet "Year 2010-2011" of the UCI Online Retail II workbook (CC BY 4.0)
// Rules   : R01  keeps ALL rows, including the 1-9 Dec 2010 window that Sheet 1 also contains.
//         Same type and rename rules as 01_Sheet1_Clean.pq (both queries must match exactly,
//         or the append in 03 silently creates extra columns).
// Validate: 541,910 rows.
// =====================================================================
let
    Source = Excel.Workbook(File.Contents(SourceFilePath), null, true),
    #"Year 2010-2011_Sheet" = Source{[Item="Year 2010-2011",Kind="Sheet"]}[Data],
    #"Promoted Headers" = Table.PromoteHeaders(#"Year 2010-2011_Sheet", [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"Invoice", type text}, {"StockCode", type text}, {"Description", type text}, {"Quantity", Int64.Type}, {"InvoiceDate", type datetime}, {"Price", type number}, {"Customer ID", type text}, {"Country", type text}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"Customer ID", "CustomerID"}})
in
    #"Renamed Columns"

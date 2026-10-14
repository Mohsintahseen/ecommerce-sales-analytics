// =====================================================================
// 04_Stg_Sales.pq   (the staging table)
// Rules   : R10   trim Description (null stays null)
//           R05   upper-case StockCode (173 codes existed in two letter cases)
//           R05b  trim StockCode (one code had a trailing space; Power BI rejected the
//                 duplicate key. Trim BEFORE upper-casing and before the RowType rules)
//           LineID unique row id in source order
//           R02-R09 RowType, first matching rule wins:
//             1 AccountingEntry  invoice starts with A
//             2 NonProductCharge code in the charge list, or code 23574 with price > 0
//             3 GiftVoucher      code starts with GIFT_
//             4 Cancellation     invoice starts with C
//             5 StockAdjustment  price 0 and no customer
//             6 ZeroPriceItem    price 0 with a customer
//             7 Sale
//           R12   StandardCountry (EIRE, RSA, USA, Korea) and MapReady
// Validate: 1,044,848 rows | StockCode distinct 5,131 | Description distinct 5,655 |
//           LineID max 1,044,848 | RowType counts: Sale 1,015,074, Cancellation 17,972,
//           StockAdjustment 5,914, NonProductCharge 5,721, GiftVoucher 100,
//           ZeroPriceItem 61, AccountingEntry 6 | StandardCountry distinct 43 |
//           MapReady = false on 2,518 rows
// =====================================================================
let
    Source = Sales_Combined,
    #"Trimmed Description" = Table.TransformColumns(Source,{{"Description", Text.Trim, type text}}),
    #"Cleaned StockCode" = Table.TransformColumns(#"Trimmed Description",{{"StockCode", each Text.Upper(Text.Trim(_)), type text}}),
    #"Added Index" = Table.AddIndexColumn(#"Cleaned StockCode", "Index", 1, 1, Int64.Type),
    #"Renamed Columns" = Table.RenameColumns(#"Added Index",{{"Index", "LineID"}}),
    #"Reordered Columns" = Table.ReorderColumns(#"Renamed Columns",{"LineID", "Invoice", "StockCode", "Description", "Quantity", "InvoiceDate", "Price", "CustomerID", "Country", "Revenue"}),
    #"Added Custom" = Table.AddColumn(#"Reordered Columns", "RowType", each if Text.StartsWith([Invoice], "A") then "AccountingEntry"
else if List.Contains({"POST","DOT","C2","M","D","S","BANK CHARGES","AMAZONFEE","CRUK","ADJUST","ADJUST2","TEST001","TEST002"}, [StockCode]) or ([StockCode] = "23574" and [Price] > 0) then "NonProductCharge"
else if Text.StartsWith([StockCode], "GIFT_") then "GiftVoucher"
else if Text.StartsWith([Invoice], "C") then "Cancellation"
else if [Price] = 0 and [CustomerID] = null then "StockAdjustment"
else if [Price] = 0 then "ZeroPriceItem"
else "Sale"),
    #"Changed Type" = Table.TransformColumnTypes(#"Added Custom",{{"RowType", type text}}),
    #"Added Custom1" = Table.AddColumn(#"Changed Type", "StandardCountry", each if [Country] = "EIRE" then "Ireland"
else if [Country] = "RSA" then "South Africa"
else if [Country] = "USA" then "United States"
else if [Country] = "Korea" then "South Korea"
else [Country]),
    #"Changed Type1" = Table.TransformColumnTypes(#"Added Custom1",{{"StandardCountry", type text}}),
    #"Added Custom2" = Table.AddColumn(#"Changed Type1", "MapReady", each not List.Contains({"Unspecified","European Community","West Indies","Channel Islands"}, [Country])),
    #"Changed Type2" = Table.TransformColumnTypes(#"Added Custom2",{{"MapReady", type logical}})
in
    #"Changed Type2"

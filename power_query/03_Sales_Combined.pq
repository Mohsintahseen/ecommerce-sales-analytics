// =====================================================================
// 03_Sales_Combined.pq
// NOTE    : this query's code was not exported with the others. It is RECONSTRUCTED from the
//           steps followed (append the two clean sheets, add Revenue). Compare it with the
//           Advanced Editor of your Sales_Combined query and keep the real one if they differ.
// Purpose : stack the two sheets (Sheet 1 first, so source order is chronological) and add
//           Revenue = Quantity x Price (Price is a UNIT price; see Cleaning_Log O3).
// Validate: 1,044,848 rows (502,938 + 541,910) and 9 columns; Revenue sum 18,909,762.12;
//           the 1-9 Dec 2010 window must hold 22,523 rows, not 45,046.
// IMPORTANT: do not leave any Sorted Rows step in this chain. LineID (04) follows row order,
//           and a leftover descending sort once scrambled it (Cleaning_Log R16).
// =====================================================================
let
    Source = Table.Combine({Sheet1_Clean, Sheet2_Clean}),
    #"Added Revenue" = Table.AddColumn(Source, "Revenue", each [Quantity] * [Price], type number)
in
    #"Added Revenue"

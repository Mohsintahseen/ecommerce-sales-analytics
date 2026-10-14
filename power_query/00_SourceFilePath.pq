// =====================================================================
// 00_SourceFilePath.pq   (a Power Query PARAMETER, not a table)
// Purpose : one place to set where the raw Excel file is, so no personal
//           path is hard-coded in the queries.
// How     : Power Query Editor > Home > Manage Parameters > New Parameter
//           Name: SourceFilePath, Type: Text, Required, Current Value: your path.
// =====================================================================
"C:\path\to\online_retail_II.xlsx" meta [IsParameterQuery = true, Type = "Text", IsParameterQueryRequired = true]

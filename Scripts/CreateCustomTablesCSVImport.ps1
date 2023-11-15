Connect-AzAccount

# PowerShell script to ingest CSV data into Azure Log Analytics

# Define the path to the CSV file
$csvFilePath = "C:\Users\path\exportedSchema.csv"

# Read the CSV file to get schema information
$csvData = Import-Csv -Path $csvFilePath


# Define the custom log table schema based on the CSV file
$TableSchema = $csvData | ForEach-Object {
    if ($_.DataType -match "String") { $azType = "string" }
    elseif ($_.DataType -match "Int" -or $_.DataType -match "Long") { $azType = "long" }
    elseif ($_.DataType -match "DateTime") { $azType = "datetime" }
    elseif ($_.DataType -match "Double" -or $_.DataType -match "Single") { $azType = "real" }
    elseif ($_.DataType -match "Boolean") { $azType = "bool" }
    else { $azType = "string" }

    return @{
        Name = $_.ColumnName
        Type = $azType
    }
}

# Construct the JSON properties for the table
$tableParams = @{
    properties = @{
        schema = @{
            name = "Fortinet_CL" # or use your desired table name
            columns = $TableSchema
        }
    }
} | ConvertTo-Json -Depth 4

Invoke-AzRestMethod -Path "/subscriptions/{SUBID}/resourcegroups/{ResourcegroupName}/providers/microsoft.operationalinsights/workspaces/{SentinelInstanceName}/tables/Fortinet_CL?api-version=2021-12-01-preview" -Method PUT -payload $tableParams -Verbose
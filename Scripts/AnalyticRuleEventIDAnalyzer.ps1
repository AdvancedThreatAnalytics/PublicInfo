# Import the necessary module
Import-Module Az.Accounts 

Connect-AzAccount -TenantId "Add Tenant ID HERE"

# Authenticate and get the access token
$accessToken = (Get-AzAccessToken).Token  

# Import the CSV file
$resourceIds = Import-Csv -Path .\analyticruleID.csv

# Create an ArrayList to store results
[System.Collections.ArrayList]$results = @()
$processedRules = 0
$totalRules = $resourceIds.Count

foreach ($resourceId in $resourceIds) {
    $processedRules++
    Write-Host "Processing rule $processedRules of $totalRules : $($resourceId.SentinelResourceId)" -ForegroundColor Cyan
    
    try {
        # Make individual GET request for each rule with updated API version
        $apiUrl = "https://management.azure.com$($resourceId.SentinelResourceId)?api-version=2023-02-01-preview"
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{ "Authorization" = "Bearer $accessToken" }
        
        $query = $response.properties.query
        if ($query) {
            # Process each line that might contain EventID
            $queryLines = $query -split '\r?\n' | Where-Object { 
                $_ -match 'EventID' -or $_ -match 'Event ID' -or $_ -match 'EventId'
            }
            
            foreach ($line in $queryLines) {
                if ($line -match 'EventID\s*[=!<>]+\s*(\d+)' -or 
                    $line -match 'EventID\s+in\s*\(([^)]+)\)' -or
                    $line -match 'where.*EventID.*?(\d+)' -or
                    $line -match 'Event ID.*?(\d+)' -or
                    $line -match 'EventId.*?(\d+)') {
                    
                    # Handle comma-separated EventIDs
                    if ($matches[1] -match ',') {
                        $eventIds = $matches[1] -split ',' | ForEach-Object { $_.Trim() }
                    } else {
                        $eventIds = @($matches[1])
                    }
                    
                    foreach ($eventId in $eventIds) {
                        if ($eventId -match '^\d+$') {
                            $null = $results.Add([PSCustomObject]@{
                                RuleName = $response.name
                                DisplayName = $response.properties.displayName
                                EventID = $eventId
                                Query = $line.Trim()
                            })
                            Write-Host "  Found EventID: $eventId" -ForegroundColor Green
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Host "Error processing rule $($resourceId.SentinelResourceId): $_" -ForegroundColor Red
    }
}

# Export results and show summary
$results | Export-Csv -Path ".\EventIDs.csv" -NoTypeInformation
Write-Host "`nProcessing complete!" -ForegroundColor Green
Write-Host "Total rules processed: $totalRules" -ForegroundColor Green
Write-Host "Total unique rules with EventIDs: $($results.RuleName | Select-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Green
Write-Host "Total EventIDs found: $($results.Count)" -ForegroundColor Green

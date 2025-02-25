#Run the following Query in Sentinel to get the Analytic Rule ID Export and name it analyticruleID.csv in the scripts working directory

#SentinelHealth
#| where TimeGenerated > ago(1d)
#| where OperationName in~ ("Scheduled analytics rule run","NRT analytics rule run") 
#| distinct SentinelResourceId

# Import the necessary module
Import-Module Az.Accounts 

Connect-AzAccount -TenantId "Add Tenant ID HERE"

# Authenticate and get the access token
$accessToken = (Get-AzAccessToken).Token  

# Import the CSV file
$resourceIds = Import-Csv -Path .\analyticruleID.csv

# Create ArrayLists to store results
[System.Collections.ArrayList]$results = @()
[System.Collections.ArrayList]$noEventIdRules = @()
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
        $eventIdFound = $false
        
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
                    
                    $eventIdFound = $true
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
        
        # If no EventIDs were found, add to noEventIdRules
        if (!$eventIdFound) {
            $null = $noEventIdRules.Add([PSCustomObject]@{
                RuleName = $response.name
                DisplayName = $response.properties.displayName
                Query = $query
            })
        }
    }
    catch {
        Write-Host "Error processing rule $($resourceId.SentinelResourceId): $_" -ForegroundColor Red
    }
}

# Export both results
$results | Export-Csv -Path ".\EventIDs.csv" -NoTypeInformation
$noEventIdRules | Export-Csv -Path ".\NoEventIDs.csv" -NoTypeInformation

# Modified summary to include rules without EventIDs
Write-Host "`nProcessing complete!" -ForegroundColor Green
Write-Host "Total rules processed: $totalRules" -ForegroundColor Green
Write-Host "Total unique rules with EventIDs: $($results.RuleName | Select-Object -Unique | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Green
Write-Host "Total EventIDs found: $($results.Count)" -ForegroundColor Green
Write-Host "Rules without EventIDs: $($noEventIdRules.Count)" -ForegroundColor Yellow
Write-Host "Results exported to EventIDs.csv and NoEventIDs.csv" -ForegroundColor Green

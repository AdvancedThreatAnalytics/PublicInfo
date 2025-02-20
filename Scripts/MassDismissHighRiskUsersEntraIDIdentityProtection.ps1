Import-Module Microsoft.Graph.Identity.SignIns
 
# Connect to Microsoft Graph with the necessary permissions
Connect-MgGraph -Scopes "IdentityRiskyUser.Read.All", "IdentityRiskyUser.ReadWrite.All"
 
# Define risk levels to process
$riskLevels = @('high', 'medium')
$processedCount = 0

foreach ($riskLevel in $riskLevels) {
    Write-Host "Processing $riskLevel risk users..." -ForegroundColor Cyan
    $riskyUsers = Get-MgRiskyUser -Filter "RiskLevel eq '$riskLevel'"
    
    if ($riskyUsers) {
        foreach ($user in $riskyUsers) {
            Write-Host "Processing user: $($user.Id)" -ForegroundColor Yellow
            
            # Create params object for single user
            $params = @{
                userIds = @($user.Id)
            }

            # Dismiss risk for single user
            try {
                Invoke-MgDismissRiskyUser -BodyParameter $params -WhatIf
                Write-Host "Successfully dismissed risk for user: $($user.Id)" -ForegroundColor Green
                $processedCount++
            }
            catch {
                Write-Host "Failed to dismiss risk for user: $($user.Id)" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
            }
            
            # Optional: Add slight delay between requests if needed
            Start-Sleep -Seconds 1
        }
    } else {
        Write-Host "No users found with $riskLevel risk level" -ForegroundColor Yellow
    }
}

Write-Host "`nRisk dismissal process complete!" -ForegroundColor Green
Write-Host "Successfully processed $processedCount users" -ForegroundColor Green

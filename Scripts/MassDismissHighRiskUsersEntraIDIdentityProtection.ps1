
Import-Module Microsoft.Graph.Identity.SignIns

# Connect to Microsoft Graph with the necessary permissions
Connect-MgGraph -Scopes "IdentityRiskyUser.Read.All", "IdentityRiskyUser.ReadWrite.All"

# Retrieve all high-risk users
$riskyUsers = Get-MgRiskyUser -Filter "RiskLevel eq 'high'"

# Extract the user IDs
$userIds = $riskyUsers.Id

# Dismiss the risk for these users
Invoke-MgDismissRiskyUser -UserIds $userIds

# Confirm the dismissal
Write-Output "Dismissed risk for the following users: $($userIds -join ', ')"

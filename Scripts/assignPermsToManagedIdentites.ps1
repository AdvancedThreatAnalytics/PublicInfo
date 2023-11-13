# Check if the Microsoft.Graph module version 2.5.0 is installed
$module = Get-Module -Name  Microsoft.Graph.Applications -ListAvailable | Where-Object { $_.Version -eq '2.5.0' }

if ($module -eq $null) {
    # Module is not installed, install it
    Write-Host "Microsoft.Graph 2.5.0 is not installed. Installing..." -ForegroundColor Red -BackgroundColor Blue
    Install-Module -Name  Microsoft.Graph.Applications -RequiredVersion 2.5.0 -Force -Scope CurrentUser
    Write-Host "Installation complete."
}
else {
    # Module is already installed
    Write-Host "Microsoft.Graph Applications 2.5.0 is already installed." -ForegroundColor Green -BackgroundColor Blue
}



Import-Module Microsoft.Graph.Applications -RequiredVersion 2.5.0



Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All", "Application.Read.All" -ContextScope Process

#Get Managed Identity
$ManagedIdentityApp = (Get-MgServicePrincipal -all | Where-Object -FilterScript {$_.ServicePrincipalType -EQ 'ManagedIdentity'} ) |  Out-GridView -PassThru -Title "Choose Managed Identity"


#Get App ID

$AppID = Get-MgServicePrincipal -all | Where-Object -FilterScript {$_.ServicePrincipalType -EQ 'Application'}  | Out-GridView -PassThru -Title "Choose App ID"

$arrayOfAppRoles = @()

#Get App Roles
$arrayOfAppRoles += ($AppID.AppRoles | Select-Object DisplayName, Value) |   Out-GridView -PassThru -Title "You Can Choose Multiple App Roles Just Hold CTRL and Right Click Multiple Values"


#Loop Through chosen App Roles and apply to Managed Identity
foreach ($appRole in $arrayOfAppRoles.DisplayName){

$AppPermission = $AppID.AppRoles | Where-Object {$_.DisplayName -eq $appRole}

$AppRoleAssignment = @{
"PrincipalId" = $ManagedIdentityApp.Id
"ResourceId" = $AppID.Id
"AppRoleId" = $AppPermission.Id
}

Write-Host "Applying" $AppPermission.Description "To The Managed Identity" $ManagedIdentityApp.DisplayName
New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityApp.Id -BodyParameter $AppRoleAssignment

}

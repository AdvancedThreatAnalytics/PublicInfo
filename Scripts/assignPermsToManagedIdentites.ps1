
 Write-Host "Uninstall old Microsoft.Graph Modules that cause conflicts"
 $Modules = Get-Module Microsoft.Graph* -ListAvailable 
    Foreach ($Module in $Modules)
    {
        $ModuleName = $Module.Name
        $Versions = Get-Module $ModuleName -ListAvailable
        Foreach ($Version in $Versions)
        {
            $ModuleVersion = $Version.Version
            Write-Host "Uninstall-Module $ModuleName $ModuleVersion"
            Uninstall-Module $ModuleName -RequiredVersion $ModuleVersion
        }
    }

Write-Host "Installing Microsoft.Graph.Applications 2.5.0"
Install-Module Microsoft.Graph.Applications -Scope CurrentUser -RequiredVersion 2.5.0 -Force -Verbose




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

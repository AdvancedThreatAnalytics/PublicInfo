#Bypass Execution Policy
Set-ExecutionPolicy -ExecutionPolicy Bypass
#Install Graph
if(Get-Module -ListAvailable -Name Microsoft.Graph) {
    Write-Host "Uninstall old Graph Modules and installing new ones!"
    
    $Modules = Get-Module Microsoft.Graph* -ListAvailable | Where {$_.Name -ne "Microsoft.Graph.Authentication"} | Select-Object Name -Unique
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
    #Uninstall Microsoft.Graph.Authentication
    $ModuleName = "Microsoft.Graph.Authentication"
    $Versions = Get-Module $ModuleName -ListAvailable
    Foreach ($Version in $Versions)
    {
        $ModuleVersion = $Version.Version
        Write-Host "Uninstall-Module $ModuleName $ModuleVersion"
        Uninstall-Module $ModuleName -RequiredVersion $ModuleVersion
    }

}
else {
    Write-Host "Microsoft.Graph Does Not Exist Installing!!"
    Install-Module Microsoft.Graph -Scope CurrentUser -Force -Verbose
}

#Connect
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All", "Application.Read.All" -ContextScope Process
#Select-MgProfile Beta

#Get Managed Identity
$ManagedIdentityApp = (Get-MgServicePrincipal | Where-Object -FilterScript {$_.ServicePrincipalType -EQ 'ManagedIdentity'} ) |  Out-GridView -PassThru -Title "Choose Managed Identity"


#Get App ID
#$AppID = Get-MgServicePrincipal -all | Where-Object -FilterScript {$_.PublisherName -EQ 'Microsoft Services'} | Out-GridView -PassThru -Title "Choose App ID"

$AppID = Get-MgServicePrincipal -all | Out-GridView -PassThru -Title "Choose App ID"

$arrayOfAppRoles = @()

#Get App Roles
$arrayOfAppRoles += ($AppID.AppRoles | Select-Object DisplayName, Value) |  Out-GridView -PassThru -Title "You Can Choose Multiple App Roles Just Hold CTRL and Right Click Multiple Values"


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

Set-ExecutionPolicy -ExecutionPolicy Bypass

 

#Install AZ
if(Get-Module -ListAvailable -Name Az.Accounts) {
    Write-Host "AZ Module Exists Moving On!"
}
else {
    Write-Host "Microsoft.Graph Does Not Exist Installing!!"
    Install-Module Az.Accounts -Scope CurrentUser -Force -Verbose
}

 

 

#Install AZ.Resource
if(Get-Module -ListAvailable -Name Az.Resources) {
    Write-Host "Az.Resources Module Exists Moving On!"
}
else {
    Write-Host "Az.Resources Does Not Exist Installing!!"
    Install-Module Az.Resources -Scope CurrentUser -Force -Verbose
}

 

 

Import-Module Az.Resources
Import-Module Az.Accounts

 

Connect-AzAccount

 

#Let user choose the sentinel instance
$sentinelResource = Get-AzResource -ResourceType "Microsoft.OperationalInsights/workspaces" | Out-GridView -PassThru -Title "Choose Sentinel Resource"

 

 

#Parse needed variables for HTTP Call
$subscriptionId = $sentinelResource.ResourceId -split '/' | Select-Object -Index 2 
$sentinelInstance = $sentinelResource.Name
$sentinelResourceGroup = $sentinelResource.ResourceGroupName

 

 

#Parse Bearer token to be added to http header
$aadToken = Get-AzAccessToken -ResourceUrl "https://management.azure.com" | Select-Object -ExpandProperty Token

 

 

#HTTP Header used for Get and Put below
$headers = @{ 
   'Content-Type' = "application/json"
    Authorization = "Bearer $aadToken"
    Accept = 'application/json'
}

 

 

#Concat variables to create get URI
$getURI = "https://management.azure.com/subscriptions/"+$subscriptionId+"/resourceGroups/"+$sentinelResourceGroup+"/providers/Microsoft.OperationalInsights/workspaces/"+$sentinelInstance+"/providers/Microsoft.SecurityInsights/alertRuleTemplates?api-version=2023-02-01"

 

 

#Get all avlaiable sentinel templates
$response = Invoke-RestMethod -Method Get -uri $getURI -Headers $headers

 

$response = $response | Select-Object -ExpandProperty value

 

 

#Loop through and enable all of them
foreach ($template in $response){

 

#create variables for the Body of the http request 
$kindOfRule = ($template | Select-Object -ExpandProperty kind)

 

$analyticRuleTemplateID = ($template).name

 

$tactics = ($template | Select-Object -ExpandProperty properties) | Select-Object tactics

 

$displayName = ($template | Select-Object -ExpandProperty properties) | Select-Object displayName

 

$description = ($template | Select-Object -ExpandProperty properties) | Select-Object description

 

$queryFrequency = ($template | Select-Object -ExpandProperty properties)| Select-Object queryFrequency

 

$queryPeriod = ($template | Select-Object -ExpandProperty properties) | Select-Object queryPeriod

 

$severity = ($template | Select-Object -ExpandProperty properties) | Select-Object severity

 

$techniques = ($template | Select-Object -ExpandProperty properties) | Select-Object techniques

 

$query = ($template | Select-Object -ExpandProperty properties) | Select-Object query

 

    $Body = @{
        kind = $kindOfRule
        properties = @{
        enabled = $true
        alertRuleTemplateName = $analyticRuleTemplateID
        queryFrequency = $queryFrequency.queryFrequency
        queryPeriod = $queryPeriod.queryPeriod
        triggerOperator = "GreaterThan"
        triggerThreshold = 0
        severity = $severity.severity
        query = $query.query
        suppressionDuration = "PT5M"
        suppressionEnabled = $false
        displayName = $displayName.displayName
        description = $description.description
        tactics = $tactics.tactics
        techniques = $techniques.techniques

 

      }
    }

 


    Write-Host ($Body).kind
    Write-Host "enabled: $($Body.properties.enabled)"
    Write-Host "alertRuleTemplateName: $($Body.properties.alertRuleTemplateName)"
    Write-Host "queryFrequency: $($Body.properties.queryFrequency)"
    Write-Host "queryPeriod: $($Body.properties.queryPeriod)"
    Write-Host "triggerOperator: $($Body.properties.triggerOperator)"
    Write-Host "triggerThreshold: $($Body.properties.triggerThreshold)"
    Write-Host "severity: $($Body.properties.severity)"
    Write-Host "query: $($Body.properties.query)"
    Write-Host "suppressionDuration: $($Body.properties.suppressionDuration)"
    Write-Host "suppressionEnabled: $($Body.properties.suppressionEnabled)"
    Write-Host "displayName: $($Body.properties.displayName)"
    Write-Host "description: $($Body.properties.description)"

 

$jsonBody = $Body | ConvertTo-Json

 

#create put URI
$putURI = "https://management.azure.com/subscriptions/"+$subscriptionId+"/resourceGroups/"+$sentinelResourceGroup+"/providers/Microsoft.OperationalInsights/workspaces/"+$sentinelInstance+"/providers/Microsoft.SecurityInsights/alertRules/" + $displayName.displayName + '?api-version=2023-02-01'

 

$encodedUrl = [System.Uri]::EscapeUriString($putURI) #Fix whitespace Issue on Analytic Rule Display Name

 

Invoke-RestMethod -uri $encodedUrl -Method Put -Headers $headers -Body $jsonBody

 

 

}

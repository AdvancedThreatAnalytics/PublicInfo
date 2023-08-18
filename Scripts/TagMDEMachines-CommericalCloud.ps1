$tenantId = '00000000-0000-0000-0000-0000000000' ### Paste your tenant ID here
$appId = '00000000-0000-0000-0000-0000000000' ### Paste your Application ID here
$appSecret = 'AppSecretValueNotSecretID' ### Paste your Secret Value here

Write-Host "Register a new azure AD app with the application permissions Machine.Read.All and Machine.ReadWrite.All `nThen input the Tenant ID, AppID, and App Secret in the Above Varibles" -ForegroundColor cyan


#Get the Access token for API calls below
$resourceAppIdUri = 'https://api.securitycenter.microsoft.com'
$oAuthUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$body = [Ordered] @{
    resource = "$resourceAppIdUri"
    client_id = "$appId"
    client_secret = "$appSecret"
    grant_type = 'client_credentials'
}
$response = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $body -ErrorAction Stop
$aadToken = $response.access_token
#$aadToken

#Grab CSV Data
$csvPath = "ENTER PATH HERE"
Write-Host "Parsing Machine Names from" $csvPath -ForegroundColor Green "`n"

#Grab Tag Name for MDE
$tagName = "ENTER TAG NAME HERE"
Write-Host "Using this tag name" $tagName "`n" -ForegroundColor Green

$devices = Import-Csv -Path $csvPath


#URI and Header to Get Machine ID
$deviceIdUri = "https://api.securitycenter.microsoft.com/api/machines/"

$headers = @{ 
    'Content-Type' = 'application/json'
    Accept = 'application/json'
    Authorization = "Bearer $aadToken" 
}

foreach ($device in $devices) {

    $deviceNameURI =  $deviceIdUri+$device.DeviceName
    
    #Create web request then store machine ID in $machineID
    $webResponse = Invoke-WebRequest -Method Get -Uri $deviceNameURI -Headers $headers  -ErrorAction Stop 
    $response = $webResponse | Select-Object -ExpandProperty content |   ConvertFrom-Json 
    $machineID =  ($response).id
    Write-Host "The Machine Named"  $device.DeviceName  " has the Machine ID "  $machineID "`n" -ForegroundColor Yellow

    #Craft Tag for the machine ID stored Above
    $tagURI = 'https://api.securitycenter.microsoft.com/api/machines/'+$machineID+'/tags'
    Write-Host "Applying Tag with this URI"  $tagURI "`n"
    $body = '{
      "Value" : "'+$tagName+'",
      "Action": "Add"

    }'
    #Apply Tag to Machine in MDE
    $webResponse2 = Invoke-WebRequest -Method Post -Uri $tagURI -Headers $headers -Body $body  -ErrorAction Stop 
    write-host "API Request Status is"  $webResponse.StatusDescription "`n"

}

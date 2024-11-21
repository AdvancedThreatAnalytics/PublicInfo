# Function to display the menu and get user input
function Show-Menu {
    param (
        [string]$prompt
    )
    Write-Host $prompt
    Write-Host "1: Enter the path manually"
    Write-Host "2: Browse for the file"
    Write-Host "0: Exit"
    $choice = Read-Host "Enter your choice"
    return $choice
}

# Function to get the file path from the user
function Get-FilePath {
    $choice = Show-Menu -prompt "Please choose an option to provide the CSV file path:"
    switch ($choice) {
        1 {
            $filePath = Read-Host "Enter the full path to the CSV file"
        }
        2 {
            Add-Type -AssemblyName System.Windows.Forms
            $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $fileDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
            $fileDialog.ShowDialog() | Out-Null
            $filePath = $fileDialog.FileName
        }
        0 {
            Write-Host "Exiting..."
            exit
        }
        default {
            Write-Host "Invalid choice. Please try again."
            Get-FilePath
        }
    }
    return $filePath
}

# Get the CSV file path from the user
$csvPath = Get-FilePath

# Check if the file exists
if (-not (Test-Path -Path $csvPath)) {
    Write-Host "The file path provided does not exist. Please run the script again and provide a valid path."
    exit
}

# Function to check if a module is installed
function Check-Module {
    param (
        [string]$ModuleName
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "Module $ModuleName is not installed. Installing..."
        Install-Module -Name $ModuleName -Scope CurrentUser -Force
    } else {
        Write-Host "Module $ModuleName is already installed. Proceeding..."
    }
}

# Check and install necessary modules if not already installed
Check-Module -ModuleName "Microsoft.Graph"
Check-Module -ModuleName "MSAL.PS"

# Authenticate with Microsoft Graph
# This will open a sign-in window where you can enter your credentials
Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All"

# Get the context to retrieve tenant and client ID
$context = Get-MgContext
$tenantId = $context.TenantId
$clientId = $context.ClientId

# Define the parameters for the token request
$params = @{
    TenantId    = $tenantId
    ClientId    = $clientId
    Interactive = $true
}

# Get the access token
$tokenResponse = Get-MsalToken @params
$token = $tokenResponse.AccessToken

# Import the CSV file
$csvData = Import-Csv -Path $csvPath

# Extract paths, processes, and extensions from the CSV file
$paths = $csvData | Select-Object -ExpandProperty path
$processes = $csvData | Select-Object -ExpandProperty process
$extensions = $csvData | Select-Object -ExpandProperty extensions

$exclusionPolicyName = Read-Host -Prompt "Enter the name of the exclusion policy"

# Define the exclusion policy details
$policy = @{
    "name" = $exclusionPolicyName
    "description" = "Policy to exclude specific processes, paths, and extensions"
    "platforms" = "windows10"
    "technologies" = "mdm,microsoftSense"
    "settings" = @(
        @{
            "id" = "0"
            "settingInstance" = @{
                "@odata.type" = "#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance"
                "settingDefinitionId" = "device_vendor_msft_policy_config_defender_excludedpaths"
                "settingInstanceTemplateReference" = @{
                    "settingInstanceTemplateId" = "aaf04adc-c639-464f-b4a7-152e784092e8"
                }
                "simpleSettingCollectionValue" = $paths | ForEach-Object {
                    @{
                        "@odata.type" = "#microsoft.graph.deviceManagementConfigurationStringSettingValue"
                        "settingValueTemplateReference" = $null
                        "value" = $_
                    }
                }
            }
        },
        @{
            "id" = "1"
            "settingInstance" = @{
                "@odata.type" = "#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance"
                "settingDefinitionId" = "device_vendor_msft_policy_config_defender_excludedprocesses"
                "settingInstanceTemplateReference" = @{
                    "settingInstanceTemplateId" = "96b046ed-f138-4250-9ae0-b0772a93d16f"
                }
                "simpleSettingCollectionValue" = $processes | ForEach-Object {
                    @{
                        "@odata.type" = "#microsoft.graph.deviceManagementConfigurationStringSettingValue"
                        "settingValueTemplateReference" = $null
                        "value" = $_
                    }
                }
            }
        },
        @{
            "id" = "2"
            "settingInstance" = @{
                "@odata.type" = "#microsoft.graph.deviceManagementConfigurationSimpleSettingCollectionInstance"
                "settingDefinitionId" = "device_vendor_msft_policy_config_defender_excludedextensions"
                "settingInstanceTemplateReference" = @{
                    "settingInstanceTemplateId" = "c203725b-17dc-427b-9470-673a2ce9cd5e"
                }
                "simpleSettingCollectionValue" = $extensions | ForEach-Object {
                    @{
                        "@odata.type" = "#microsoft.graph.deviceManagementConfigurationStringSettingValue"
                        "settingValueTemplateReference" = $null
                        "value" = $_
                    }
                }
            }
        }
    )
    "templateReference" = @{
        "templateId" = "45fea5e9-280d-4da1-9792-fb5736da0ca9_1"
        "templateFamily" = "endpointSecurityAntivirus"
        "templateDisplayName" = "Microsoft Defender Antivirus exclusions"
        "templateDisplayVersion" = "Version 1"
    }
}

# Convert the policy to JSON
$policyJson = $policy | ConvertTo-Json -Depth 10

# Create the policy
Invoke-RestMethod -Method POST -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies" -Body $policyJson -ContentType "application/json" -Headers @{
    Authorization = "Bearer $token"
}

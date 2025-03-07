<#
.SYNOPSIS
    Creates Microsoft Sentinel Analytics Rules from templates that don't have any rules created from them.

.DESCRIPTION
    This script allows you to:
    - List and export templates that don't have any rules created from them
    - Create rules from specific templates listed in an input file
    - Create rules of a specific severity
    - Create all rules that don't have any rules created from them

.PARAMETER WorkspaceName
    The name of the Log Analytics workspace where Sentinel is enabled

.PARAMETER ResourceGroupName
    The name of the resource group containing the Log Analytics workspace

.PARAMETER InputFile
    Path to a csv file containing template names(identity, not display name) to create rules from, in a column named 'Name'.

.PARAMETER ExportOnly
    Switch to export templates without rules to CSV without creating any rules

.PARAMETER OutputPath
    Path where the CSV file will be saved when using ExportOnly
    Default: .\SentinelTemplatesWithoutRules.csv

.PARAMETER Severity
    Create rules only of the specified severity (High, Medium, Low, or Informational)

.EXAMPLE
    # Export templates to CSV
    .\Create-SentinelAnalyticsRules.ps1 -WorkspaceName "workspace" -ResourceGroupName "rg" -ExportOnly

.EXAMPLE
    # Create rules from input file
    .\Create-SentinelAnalyticsRules.ps1 -WorkspaceName "workspace" -ResourceGroupName "rg" -InputFile "templates.txt"

.EXAMPLE
    # Create all High severity rules
    .\Create-SentinelAnalyticsRules.ps1 -WorkspaceName "workspace" -ResourceGroupName "rg" -Severity High

.EXAMPLE
    # Create all rules without filters
    .\Create-SentinelAnalyticsRules.ps1 -WorkspaceName "workspace" -ResourceGroupName "rg"

.NOTES
    Version:        0.1
    Author:         Hudson Bush (Critical Start)
    Creation Date:  December 17, 2024
    Requires:       Az.SecurityInsights module version 3.1.2 or higher
#>

[CmdletBinding(DefaultParameterSetName = 'Default')]
param (
    [Parameter(Mandatory = $true)][string]$WorkspaceName,
    [Parameter(Mandatory = $true)][string]$ResourceGroupName,
    [Parameter(ParameterSetName = 'FromFile')][string]$InputFile,
    [Parameter(ParameterSetName = 'ExportOnly')][switch]$ExportOnly,
    [Parameter(ParameterSetName = 'BySeverity')][ValidateSet('High', 'Medium', 'Low', 'Informational')][string]$Severity,
    [Parameter(ParameterSetName = 'ExportOnly')][string]$OutputPath = ".\SentinelTemplatesWithoutRules.csv"
)

#Verify at least 1 required parameter specified
if ($PSCmdlet.ParameterSetName -eq 'None') {
    Write-Host "You must specify one of: -InputFile, -ExportOnly, or -Severity" -ForegroundColor Red
    return
}

# Verify module is available
if (-not (Get-Module -ListAvailable Az.SecurityInsights))
{
    throw "Az.SecurityInsights module is not installed. Please install it using: Install-Module Az.SecurityInsights -Force"
}

Write-Host "Getting templates without existing rules..." -ForegroundColor Cyan
$templates = Get-AzSentinelAlertRuleTemplate -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName | Where-Object {$_.AlertRulesCreatedByTemplateCount -eq 0 -and -not $_.DisplayName.StartsWith("[Deprecated]")}

if (-not $templates)
{
    Write-Warning "No templates found without existing rules"
    return
}

Write-Host "Found $($templates.Count) templates without rules" -ForegroundColor Green

# Handle export-only mode
if ($ExportOnly)
{
    Write-Host "Exporting templates to $OutputPath" -ForegroundColor Cyan
    $templates | Select-Object AlertRuleTemplateName, DisplayName, Description, Severity | 
        Export-Csv -Path $OutputPath -NoTypeInformation
    Write-Host "Export complete" -ForegroundColor Green
    return
}

# Filter templates based on parameters
if ($InputFile)
{
    if (-not (Test-Path $InputFile)) {
        throw "Input file not found: $InputFile"
    }
    Write-Host "Reading template IDs from $InputFile" -ForegroundColor Cyan
    $templateIds = (Get-Content $InputFile).Name
    $templates = $templates | Where-Object { $templateIds -contains $_.AlertRuleTemplateName }
    Write-Host "Found $($templates.Count) matching templates from input file" -ForegroundColor Green
}
elseif ($Severity)
{
    Write-Host "Filtering templates by severity: $Severity" -ForegroundColor Cyan
    $templates = $templates | Where-Object { $_.Severity -eq $Severity }
    Write-Host "Found $($templates.Count) templates with $Severity severity" -ForegroundColor Green
}

if ($templates.Count -eq 0)
{
    Write-Warning "No templates match the specified criteria"
    return
}

$successes = 0
$failures = 0
$skipped = 0
Write-Host "Starting rule creation process..." -ForegroundColor Cyan
foreach ($template in $templates)
{
    try {
        $params = @{
            ResourceGroupName = $ResourceGroupName
            WorkspaceName = $WorkspaceName
            DisplayName = $Template.DisplayName
            Enabled = $true
			Kind = $Template.kind
        }

        switch ($Template.Kind)
		{
            "Scheduled"
			{
                $params += @{
                    AlertRuleTemplateName = $Template.Name
                    Query = $Template.Query
                    QueryFrequency = $Template.QueryFrequency
                    QueryPeriod = $Template.QueryPeriod
                    Severity = $Template.Severity
                    TriggerOperator = $Template.TriggerOperator
                    TriggerThreshold = $Template.TriggerThreshold
                }
            }
            "MLBehaviorAnalytics"
			{
                if ($Template.Status -eq "Available")
				{
                    $params += @{
                        AlertRuleTemplateName = $Template.Name
                    }
                }
                else
				{
                    Write-Host "Skipping ML Behavior Analytics rule '$($Template.DisplayName)' - Not available" -ForegroundColor Yellow
                    return
                }
            }
            "Fusion"
			{
                if ($Template.Status -eq "Available")
				{
                    $params += @{
                        AlertRuleTemplateName = $Template.Name
                    }
                }
                else
				{
                    Write-Host "Skipping Fusion rule '$($Template.DisplayName)' - Not available" -ForegroundColor Yellow
                    return
                }
            }
            "MicrosoftSecurityIncidentCreation"
			{
                $params += @{
                    ProductFilter = $Template.ProductFilter
                }
            }
            Default
			{
                Write-Host "Skipping unsupported rule kind: $($Template.Kind) for template '$($Template.DisplayName)'" -ForegroundColor Yellow
                return
            }
        }

        Write-Host "Creating rule: $($Template.DisplayName)"
        New-AzSentinelAlertRule @params -ErrorAction Stop | Out-Null 
        Write-Host "Successfully created rule: $($Template.DisplayName)" -ForegroundColor Green
		$successes++
    }
    catch
	{
		# Check if the error is about missing tables
		if ($_.Exception.Message -like "*Failed to run the analytics rule query. One of the tables does not exist.*")
		{
			Write-Host "Skipping rule '$($Template.DisplayName)' - Missing table/data connector" -ForegroundColor Yellow
			$skipped++
		}
		else
		{
		   Write-Host "Failed to create rule '$($Template.DisplayName)'" -ForegroundColor Red
		   $failures++
		}
    }
    Start-Sleep -Seconds 2  # Prevent throttling
}

if ($i -eq 0)
{
	Write-Host "Rule creation process complete - no rules created" -ForegroundColor Green
}
if ($i -eq 1)
{
	Write-Host "Rule creation process complete - $successes rule created" -ForegroundColor Green
}
else
{
	Write-Host "Rule creation process complete - $successes rules created" -ForegroundColor Green
}

# SIG # Begin signature block
# MIIFjAYJKoZIhvcNAQcCoIIFfTCCBXkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBJwp497fwkYHY8
# z8uXeTV9yf30JPwRjDKwwFC5uiHi6aCCAwQwggMAMIIB6KADAgECAhAvEM3bWyLh
# uUj8jbKbaGzhMA0GCSqGSIb3DQEBCwUAMBgxFjAUBgNVBAMMDUNyaXRpY2FsU3Rh
# cnQwHhcNMjUwMzA3MTYzMjA0WhcNMjYwMzA3MTY1MjA0WjAYMRYwFAYDVQQDDA1D
# cml0aWNhbFN0YXJ0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3jI/
# apFVOSXI/fHDPO88tN35UiTPUhlrv/yzoCkljaH8R/EFThrAVp+dGS3v9Xi5C40y
# 6Jg0m0x/b9AKVn/l19SAqPejE085aLG1rdFCnm7UL4xkWW210woiRwFoG0tEfotp
# 3vIwH8AJ9dkEAkazDkDHDovT+HQJ4lucHbrpeYgsEfSSb2lXilMeN4OdYHvUr7Vn
# zKXvUFLlQXcQ9kqmxFtEVBf1NFJoQivawPnii8vl9Bd2ChkNLIRA4Hco/kQGgQBu
# Ys/ilAvk0At5hOSJlvzmK+nxvLMsFQ8LAp8pry5DAo2m4dynkLfux2BaRXc66Pjx
# A6SRbYUyUGWfB4wFGQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAww
# CgYIKwYBBQUHAwMwHQYDVR0OBBYEFEZhjH8d8UvdbPGXO8bSrUaWzRsfMA0GCSqG
# SIb3DQEBCwUAA4IBAQCwadSIIBhmv1wlirVZdm37akHneYy93lP10zr0gLbQy1YO
# rec/QN45B218BkDO7anzwhIvx9VtgbKL+RoLy+x+xP1nrYEtQ3eOs/Fl+rf4T/ls
# sIVdQ8pxMolUVGNTiSnCITEebgsKIK/GjBOt94vX/78df4h0iD2egMYi8SMeoDeS
# Pj0HGsecgQsqxkRYhaiPzTN3mu5Jn3OJnHdd/g7nQg12aZ1gAJzn/INQpOXoATy2
# apugiIIQRCLsNZrvqaukYFF5hhwUwj9c6TgvdEfcIT7n/spctR5F2dDrlGp4VODN
# afkR+w6wZ/ESViwk5UboH9zlttXYqdPF/BofKtbRMYIB3jCCAdoCAQEwLDAYMRYw
# FAYDVQQDDA1Dcml0aWNhbFN0YXJ0AhAvEM3bWyLhuUj8jbKbaGzhMA0GCWCGSAFl
# AwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJ
# KoZIhvcNAQkEMSIEIIPDaBkKAeuGbhAqZOnZ5PdBRVRhhMgoCJ+APwhSYQjBMA0G
# CSqGSIb3DQEBAQUABIIBAFXHtGB7fS35G9+zgqVAbaNw8eFxtBW1bFAy9ym78/fp
# TRwHQUYtSxQwoARdkpqpJHyk+7UKNVCuZysLMQ5LLeyNd0XyXVElnm3kfiz4FLFx
# yZWsR1wJiCq4xwrZgAVbX7AkcJ3zvzfq8aelh6tV1hzVAG4ZFnAfYeAhIa2CUcQI
# Et28NLJu5YF6/edlIP+W6ehwnWWBs3nuvRp6+0SvZKDI3DYHtstGSwHCNh4SQj4X
# iWrdJeU8dzEDjxMNjZ5ge4HVoKwFLmjAB93tcq3rstjnwhCZKszq5atQtbsdV2LC
# DvzhVL2CgRBviQmmBdUfvk+4OWHSdDwtGElDIhl9BlU=
# SIG # End signature block

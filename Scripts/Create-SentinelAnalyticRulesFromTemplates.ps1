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

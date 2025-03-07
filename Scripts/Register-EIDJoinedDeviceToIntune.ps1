<#
.SYNOPSIS
    Registers Entra ID joined devices to Microsoft Intune.

.DESCRIPTION
    Register-EIDJoinedDeviceToIntune configures MDM (Mobile Device Management) enrollment settings in the registry 
    for devices joined to Entra ID (formerly Azure AD). It verifies tenant ID existence, creates required
    MDM registry properties, and triggers auto-enrollment.

.PARAMETER Verbose
    Enables detailed console output.

.PARAMETER WhatIf
    Shows what would happen if the script runs without making changes.

.PARAMETER LogPath
    Specifies path for log file output.

.PARAMETER ErrorAction
    Sets error handling behavior. Default is 'Stop'.

.EXAMPLE
    Register-EIDJoinedDeviceToIntune
    Performs MDM enrollment with default settings.

.EXAMPLE
    Register-EIDJoinedDeviceToIntune -LogPath "C:\logs\mdm_enrollment.log" -WhatIf
    Shows what changes would be made and logs to specified file.

.NOTES
    Version:        0.1
    Author:         Hudson Bush (Critical Start)
    Creation Date:  January 15, 2025
    Requires:
    - Administrative privileges
    - Device joined to Entra ID (formerly Azure AD)
#>

[CmdletBinding()]
param(
    [switch]$WhatIf,
    [string]$LogPath
)

$RegPath = 'SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo'
$DeviceEnroller = 'C:\Windows\system32\deviceenroller.exe'

if (!$ErrorAction)
{
	$ErrorAction = "Stop"
}

function Write-LogMessage {
    param([string]$Message)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "$timestamp`: $Message"
    
    Write-Verbose $logMessage
    if ($LogPath) {
        Add-Content -Path $LogPath -Value $logMessage
    }
}

if ($LogPath) {
    Write-LogMessage "=== Starting MDM Enrollment Process ==="
}

try {
    # Get Tenant ID
    $tenantKey = Get-Item "HKLM:\$RegPath\*" -ErrorAction $ErrorAction
    if (!$tenantKey) {
        throw "No tenant ID found in registry"
    }
    $tenantId = $tenantKey.Name.Split('\')[-1]
    $fullPath = "HKLM:\$RegPath\$tenantId"
    Write-LogMessage "Found Tenant ID: $tenantId"

    # Verify path and set MDM properties if needed 
    if (!(Test-Path $fullPath)) {
        throw "Tenant path not found: $fullPath"
		exit 1001
    }

    try {
        $null = Get-ItemProperty $fullPath -Name MdmEnrollmentUrl -ErrorAction $ErrorAction
        Write-LogMessage "MDM properties already configured"
    }
    catch {
        Write-LogMessage "Configuring MDM properties..."
        $mdmProperties = @{
            'MdmEnrollmentUrl' = 'https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc'
            'MdmTermsOfUseUrl' = 'https://portal.manage.microsoft.com/TermsofUse.aspx'
            'MdmComplianceUrl' = 'https://portal.manage.microsoft.com/?portalAction=Compliance'
        }

        foreach ($prop in $mdmProperties.GetEnumerator()) {
            if ($WhatIf) {
                Write-LogMessage "WhatIf: Would create property $($prop.Key) with value $($prop.Value)"
                continue
            }
            try {
                New-ItemProperty -LiteralPath $fullPath -Name $prop.Key -Value $prop.Value -PropertyType String -Force -ErrorAction $ErrorAction
                Write-LogMessage "Created property: $($prop.Key)"
            }
            catch {
                Write-LogMessage "Error creating $($prop.Key): $($_.Exception.Message)"
                throw
            }
        }
    }

    # Trigger auto-enrollment
    if (Test-Path $DeviceEnroller) {
        Write-LogMessage "Starting MDM enrollment..."
        if ($WhatIf) {
            Write-LogMessage "WhatIf: Would execute $DeviceEnroller /c /AutoEnrollMDM"
            exit 0
        }
        $result = Start-Process $DeviceEnroller -ArgumentList "/c /AutoEnrollMDM" -Wait -PassThru
        
        if ($result.ExitCode -eq 0) {
            Write-LogMessage "MDM enrollment initiated successfully"
            if ($LogPath) {
                Write-LogMessage "=== MDM Enrollment Process Completed Successfully ==="
            }
            exit 0
        }
        else {
            throw "DeviceEnroller failed with exit code: $($result.ExitCode)"
        }
    }
    else {
        throw "DeviceEnroller not found at: $DeviceEnroller"
    }
}
catch {
    Write-LogMessage "ERROR: $($_.Exception.Message)"
    if ($LogPath) {
        Write-LogMessage "=== MDM Enrollment Process Failed ==="
    }
    exit 1001
}

#FIN

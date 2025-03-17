#Requires -Modules ExchangeOnlineManagement

# Check if running in PowerShell 7
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "PowerShell 7 is required. Checking if it's installed..."

    # Check if winget is available
    try {
        $null = Get-Command winget -ErrorAction Stop

        # Check if PowerShell 7 is already installed but not being used
        $psPath = "${env:ProgramFiles}\PowerShell\7\pwsh.exe"
        if (-not (Test-Path $psPath)) {
            Write-Host "Installing PowerShell 7..."
            winget install --id Microsoft.PowerShell --source winget --accept-source-agreements

            if ($LASTEXITCODE -eq 0) {
                Write-Host "PowerShell 7 installed successfully. Please restart this script using PowerShell 7."
            } else {
                Write-Error "Failed to install PowerShell 7. Please install it manually. https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5"
            }
        } else {
            Write-Host "PowerShell 7 is installed but not being used. Please run this script using PowerShell 7."
        }
    } catch {
        Write-Error "Winget is not available. Please install PowerShell 7 manually. https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5"
    }
    exit 1
}

# Check if ExchangeOnlineManagement module is installed
$exchangeModule = Get-Module -ListAvailable -Name ExchangeOnlineManagement
if (-not $exchangeModule) {
    Write-Host "ExchangeOnlineManagement module not found. Installing latest version..."
    try {
        Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
        Write-Host "ExchangeOnlineManagement module installed successfully."
    }
    catch {
        Write-Error "Failed to install ExchangeOnlineManagement module: $_"
        exit 1
    }
} else {
    $latestVersion = (Find-Module -Name ExchangeOnlineManagement).Version
    $currentVersion = $exchangeModule.Version
    if ($currentVersion -lt $latestVersion) {
        $updateChoice = Read-Host "A newer version of ExchangeOnlineManagement is available ($latestVersion). Do you want to update? (Y/N)"
        if ($updateChoice -eq 'Y') {
            try {
                # Check if running as administrator
                $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                if (-not $isAdmin) {
                    Write-Error "Administrator privileges required for module update. Please restart PowerShell as Administrator."
                    exit 1
                }

                # Check if module was installed via PowerShellGet
                $modulePath = $exchangeModule.Path
                if ($modulePath -like "*\WindowsPowerShell\Modules\*" -or $modulePath -like "*\PowerShell\Modules\*") {
                    Update-Module -Name ExchangeOnlineManagement -Force
                } else {
                    # Alternative: Uninstall and reinstall if not installed via PowerShellGet
                    Write-Host "Module not installed via PowerShellGet. Performing fresh installation..."
                    Uninstall-Module -Name ExchangeOnlineManagement -AllVersions -Force -ErrorAction SilentlyContinue
                    Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber
                }
                Write-Host "ExchangeOnlineManagement module updated successfully."
            }
            catch {
                Write-Error "Failed to update ExchangeOnlineManagement module: $_"
                exit 1
            }
        }
    }
}

# Connect to Exchange Online
Connect-ExchangeOnline

# Define audit parameters
$auditParams = @{
    AuditEnabled = $true
    AuditLogAgeLimit = 365
    AuditAdmin = @{add='Update, Copy, Move, MoveToDeletedItems, SoftDelete, HardDelete, FolderBind, SendAs, SendOnBehalf, MessageBind, Create, UpdateFolderPermissions, AddFolderPermissions, ModifyFolderPermissions, RemoveFolderPermissions, UpdateInboxRules, UpdateCalendarDelegation, RecordDelete, ApplyRecord, MailItemsAccessed, UpdateComplianceTag, Send, AttachmentAccess, PriorityCleanupDelete, ApplyPriorityCleanup, PreservedMailItemProactively'}
    AuditDelegate = @{add='Update, Move, MoveToDeletedItems, SoftDelete, HardDelete, FolderBind, SendAs, SendOnBehalf, Create, UpdateFolderPermissions, AddFolderPermissions, ModifyFolderPermissions, RemoveFolderPermissions, UpdateInboxRules, RecordDelete, ApplyRecord, MailItemsAccessed, UpdateComplianceTag, AttachmentAccess, PriorityCleanupDelete, ApplyPriorityCleanup, PreservedMailItemProactively'}
    AuditOwner = @{add='Update, Move, MoveToDeletedItems, SoftDelete, HardDelete, Create, MailboxLogin, UpdateFolderPermissions, AddFolderPermissions, ModifyFolderPermissions, RemoveFolderPermissions, UpdateInboxRules, UpdateCalendarDelegation, RecordDelete, ApplyRecord, MailItemsAccessed, UpdateComplianceTag, Send, SearchQueryInitiated, AttachmentAccess, PriorityCleanupDelete, ApplyPriorityCleanup, PreservedMailItemProactively'}
}

# Get mailboxes that need updating
Write-Host "Retrieving mailboxes that need auditing updates..."
$mailboxesToUpdate = Get-Mailbox -ResultSize Unlimited -Filter {
    RecipientType -eq "UserMailbox" -and 
    RecipientTypeDetails -ne "DiscoveryMailbox" -and
    (AuditEnabled -eq $false -or AuditLogAgeLimit -ne 365)
}

$total = $mailboxesToUpdate.Count
if ($total -eq 0) {
    Write-Host "No mailboxes require auditing updates."
    exit 0
}

Write-Host "Found $total mailboxes that need updating."

# Process mailboxes in batches of 10
$batchSize = 10
$processed = 0
$errors = @()

$mailboxesToUpdate | ForEach-Object -Begin {
    $batch = @()
} -Process {
    $batch += $_
    $processed++

    if ($batch.Count -eq $batchSize -or $processed -eq $total) {
        Write-Progress -Activity "Updating mailbox auditing" -Status "Processing batch" -PercentComplete (($processed / $total) * 100)

        foreach ($mailbox in $batch) {
            try {
                Set-Mailbox -Identity $mailbox.PrimarySmtpAddress @auditParams -ErrorAction Stop
                Write-Host "Updated: $($mailbox.PrimarySmtpAddress)" -ForegroundColor Green
            }
            catch {
                $errors += "Failed to update $($mailbox.PrimarySmtpAddress): $_"
                Write-Host "Failed: $($mailbox.PrimarySmtpAddress)" -ForegroundColor Red
            }
        }
        $batch = @()
    }
} -End {
    Write-Progress -Activity "Updating mailbox auditing" -Completed
}

# Report results
Write-Host "`nProcessing complete:"
Write-Host "Total processed: $processed"
Write-Host "Successful: $($processed - $errors.Count)"
Write-Host "Failed: $($errors.Count)"

if ($errors.Count -gt 0) {
    Write-Host "`nErrors:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
}

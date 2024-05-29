# Configure Microsoft Defender preferences

# Threat Severity Default Action (Remediation action for High severity threats)
Set-MpPreference -HighThreatDefaultAction Quarantine

# Remediation action for Severe threats
Set-MpPreference -SevereThreatDefaultAction Quarantine

# Remediation action for Low severity threats
Set-MpPreference -LowThreatDefaultAction Quarantine

# Remediation action for Moderate severity threats
Set-MpPreference -ModerateThreatDefaultAction Quarantine

# Allow Behavior Monitoring
Set-MpPreference -DisableBehaviorMonitoring $false

# Allow Cloud Protection
Set-MpPreference -CloudBlockLevel 2

# Allow Full Scan On Mapped Network Drives
Set-MpPreference -DisableScanningMappedNetworkDrives $true

# Allow Full Scan Removable Drive Scanning
Set-MpPreference -DisableRemovableDriveScanning $false

# Allow Realtime Monitoring
Set-MpPreference -DisableRealtimeMonitoring $false

# Cloud Block Level (High)
Set-MpPreference -CloudBlockLevel 2

# Cloud Extended Timeout (50 secs)
Set-MpPreference -CloudExtendedTimeout 50

# Days To Retain Cleaned Malware (60 days)
Set-MpPreference -QuarantinePurgeItemsAfterDelay 60

# Disable Catchup Full Scan
Set-MpPreference -DisableCatchupFullScan $true

# Disable Catchup Quick Scan
Set-MpPreference -DisableCatchupQuickScan $true

# Enable Network Protection (audit mode)
Set-MpPreference -EnableNetworkProtection AuditMode

# PUA Protection (Audit mode)
Set-MpPreference -PUAProtection AuditMode

# Real Time Scan Direction (Monitor all files - bi-directional)
Set-MpPreference -RealTimeScanDirection 0

# Schedule Scan Time (Every Day at 2 AM)
Set-MpPreference -ScanScheduleDay 0 -ScanScheduleTime 120

# Allow scanning of all downloaded files and attachments
Set-MpPreference -DisableIOAVProtection $false

# Disable Scanning Network Files
Set-MpPreference -DisableScanningNetworkFiles $true

# Allow Script Scanning
Set-MpPreference -DisableScriptScanning $false

# Allow User UI Access
Set-MpPreference -UILockdown $True

# Avg CPU Load Factor (50%)
Set-MpPreference -ScanAvgCPULoadFactor 50

# Check For Signatures Before Running Scan
Set-MpPreference -CheckForSignaturesBeforeRunningScan $true

# Submit Samples Consent (Send safe samples automatically)
Set-MpPreference -SubmitSamplesConsent 3

# Allow Archive Scanning
Set-MpPreference -DisableArchiveScanning $false

# Set Quick Scans for Scheduled Scans
Set-MpPreference -ScanParameters QuickScan
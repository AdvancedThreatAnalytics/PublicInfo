# Define the output file path
$outputFile = "$PSScriptRoot\DefenderFeatureCheck.txt"

# Get the Windows version
$windowsVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId

# Initialize output variable
$output = ""

# Run additional DISM and SFC commands first
$output += "Running DISM and SFC commands`n"
$output += (Dism /Online /Cleanup-Image /CheckHealth) + "`n"
$output += (Dism /Online /Cleanup-Image /ScanHealth) + "`n"
$output += (Dism /Online /Cleanup-Image /RestoreHealth) + "`n"
$output += (sfc /SCANNOW) + "`n"

if ($windowsVersion -eq "1607") {
    # For Windows Server 2016
    $output += "Installing Windows Defender feature for Windows Server 2016`n"
    Install-WindowsFeature -Name Windows-Defender
    $output += "Enabling Windows Defender using MpCmdRun.exe`n"
    & "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -wdenable
    $output += "Running DISM commands for Windows Server 2016`n"
    $output += (Dism /Online /Enable-Feature /FeatureName:Windows-Defender-Features /NoRestart) + "`n"
    $output += (Dism /Online /Enable-Feature /FeatureName:Windows-Defender /NoRestart) + "`n"
    $output += (Dism /Online /Enable-Feature /FeatureName:Windows-Defender-Gui /NoRestart) + "`n"
} elseif ($windowsVersion -ge "1803") {
    # For Windows Server 1803 and later
    $output += "Installing Windows Defender feature for Windows Server 1803 and later`n"
    Install-WindowsFeature -Name Windows-Defender
    $output += "Running DISM commands for Windows Server 1803 and later`n"
    $output += (Dism /Online /Enable-Feature /FeatureName:Windows-Defender /NoRestart) + "`n"
} else {
    $output += "Unsupported Windows Server version`n"
}

$output += "Windows Defender feature has been installed.`n"

# Download and run updateplatform.exe
$output += "Downloading updateplatform.exe`n"
$downloadUrl = "https://go.microsoft.com/fwlink/?linkid=870379&arch=x64"
$outputFilePath = "$PSScriptRoot\updateplatform.exe"
Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFilePath
$output += "Running updateplatform.exe with administrator privileges`n"
Start-Process -FilePath $outputFilePath -ArgumentList "/quiet" -Verb RunAs

# Write the output to the file
$output | Out-File -FilePath $outputFile -Encoding utf8

# Optional: Display a message indicating the output file location
Write-Output "Output has been written to $outputFile"

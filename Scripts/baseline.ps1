### Initial Accesss######################################################################################################################################

# Set default behavior for 'AutoRun' to 'Enabled: Do not execute any autorun commands'
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\" -Name NoAutorun -Value 1 -PropertyType DWORD  -Force

#Disable 'Autoplay' for all drives
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\" -Name NoDriveTypeAutoRun -Value 255 -PropertyType DWORD  -Force

#Disable 'Autoplay for non-volume devices'
if (-Not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer\")){
    New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\" -Name Explorer  -Force 
    New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer\" -Name NoAutoplayfornonVolume -Value 1 -PropertyType DWORD  -Force
}
else {
    New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer\" -Name NoAutoplayfornonVolume -Value 1 -PropertyType DWORD  -Force
    
}

#Block outdated ActiveX controls for Internet Explorer

New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Ext\" -Name VersionCheckEnabled -Value 1 -PropertyType DWORD  -Force    

#Disable Flash on Adobe Reader DC

New-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\" -Name bEnableFlash -Value 0 -PropertyType DWORD  -Force

#Disable Flash on Adobe Acrobat Pro XI

if (Test-Path "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\11.0\FeatureLockDown\"){
    New-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\11.0\FeatureLockDown\" -Name bEnableFlash -Value 0 -PropertyType DWORD -Force
}

#Disable Javascript on Adobe Reader DC

New-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\" -Name bDisableJavaScript -Value 1 -PropertyType DWORD  -Force

#Disable Javascript on Adobe Acrobat Pro XI
if (Test-Path "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\11.0\FeatureLockDown\"){
    New-ItemProperty "HKLM:\SOFTWARE\Policies\Adobe\Adobe Acrobat\11.0\FeatureLockDown\" -Name bDisableJavaScript -Value 1 -PropertyType DWORD -Force
}

#Enable Scan Removable Drives During Full Scan
if (-Not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan")){
    New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan" -Name Explorer  -Force 
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan" -Name DisableRemovableDriveScanning -Value 0 -PropertyType DWORD -Force
}
else {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan" -Name DisableRemovableDriveScanning -Value 0 -PropertyType DWORD -Force
    
}


#Disable 'Always install with elevated privileges'
if (-Not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer\")){
    New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer\" -Name Explorer  -Force 
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer\" -Name AlwaysInstallElevated -Value 0 -PropertyType DWORD -Force
}
else {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer\" -Name AlwaysInstallElevated -Value 0 -PropertyType DWORD -Force
    
}

#########################################################################################################################################################
### Execution ########################################################################################################################################

#########################################################################################################################################################

### Persistance ########################################################################################################################################

#Disable Continue running Background Apps when Google Chrome is closed

New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome\" -Name BackgroundModeEnabled -Value 0 -PropertyType DWORD -Force
    
#########################################################################################################################################################

### Defense Evasion #####################################################################################################################################

#Disable IP Source Routing IPV4
New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\" -Name DisableIPSourceRouting -Value 2 -PropertyType DWORD  -Force

#Disable Layer 2 Mac Bridge

New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections\" -Name NC_AllowNetBridge_NLA -Value 0 -PropertyType DWORD  -Force

#Enable 'Hide Option to Enable or Disable Updates in Office'
New-ItemProperty "HKLM:\SOFTWARE\policies\Microsoft\office\16.0\common\officeupdate\" -Name hideenabledisableupdates -Value 1 -PropertyType DWORD  -Force

#Set IPv6 source routing to highest protection
New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\" -Name DisableIPSourceRouting -Value 2 -PropertyType DWORD  -Force

##########################################################################################################################################################



### Credential Access######################################################################################################################
# Disable NetBios on Interface
$netBios = Get-WmiObject win32_NetworkAdapterConfiguration
foreach ($NIC in $netBios){
        $NIC.SetTcpipNetbios(2) 
    }

# Disable Host File on Interface
<# 
$netBios = Get-WmiObject -List win32_NetworkAdapterConfiguration
foreach ($NIC in $netBios){
        $NIC.ENABLEWINS($false,$false) 
    }

#>

# Set LAN Manager authentication level to 'Send NTLMv2 response only. Refuse LM & NTLM'
New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" -Name LmCompatibilityLevel -Value 5 -PropertyType DWORD  -Force

# Disable LLMNR

if (-Not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient")){
    New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT" -Name DNSClient  -Force 
    New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name EnableMultiCast -Value 0 -PropertyType DWORD  -Force
}

#LSA Protected Process

Try {
((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -ea 1).RunAsPPL -ne $null)
    # It's There Do Nothing
  
}
catch{
    if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -ea 0).RunAsPPL -eq 0){
        #We got a problem Boss looks like malware flip it back
        Set-ItemProperty  "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -Value 1 -Force
    }
    else{
        # Never Existed Put it in
    New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name RunAsPPL -Value 1 -PropertyType DWORD  -Force
   }
}

#Disable 'Allow Basic authentication' for WinRM Client

if (-Not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client")){
    New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client" -Name Explorer  -Force 
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client" -Name AllowBasic -Value 1 -PropertyType DWORD -Force
}
else {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client" -Name AllowBasic -Value 1 -PropertyType DWORD -Force
    
}

#Remote Desktop Services must Always prompt a client for passwords upon connection

New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name fPromptForPassword -Value 1 -PropertyType DWORD -Force



# Passwords must not be saved in the Remote Desktop Client
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name DisablePasswordSaving -Value 1 -PropertyType DWORD -Force

#Disable the local storage of passwords and credentials ## I Rolled this back to a zero value because it breaks cached mapped drive with AD Creds

Set-ItemProperty  "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "disabledomaincreds" -Value 0 -Force


#############################################################################################################################################

###Discovery#######################################################################################################################################

#Disable 'Enumerate administrator accounts on elevation'

if (-Not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI")){
    New-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\" -Name CredUI  -Force 
    New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI" -Name EnumerateAdministrators -Value 0 -PropertyType DWORD  -Force
}

#Disable Anonymous enumeration of shares

New-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\" -Name RestrictAnonymous -Value 1 -PropertyType DWORD  -Force

####################################################################################################################################################


######### Lateral Movements #################################################################################################################


#Enable 'Apply UAC restrictions to local accounts on network logons'

New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name LocalAccountTokenFilterPolicy -Value 0 -PropertyType DWORD  -Force

#Prohibit use of Internet Connection Sharing on your DNS domain network

New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections\" -Name NC_ShowSharedAccessUI -Value 0 -PropertyType DWORD  -Force

#Do not allow Clipboard redirection RDP
New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Terminal Server Client" -Name DisableClipboardRedirection -Value 1 -PropertyType DWORD  -Force

#Set Idle Time for RDP Session to 1 Hour

New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name MaxIdleTime -Value 3600000 -PropertyType DWORD -Force



######################################################################################################################################################



######### Deprecated and Exploitable Windows Features###################################################################################################################

# Disable Powershell V2
if ((Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root).State -eq "Enabled"){
    Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root 
}
# Disable SMB V1    
if ((Get-WindowsOptionalFeature -Online -FeatureName smb1protocol).State -eq "Enabled"){
    Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol 
}


####################################################################################################################################################################


#######Enable ATP Requried Auditing For Telementary Data ###########################################################################################################
auditpol /set /category:"Account Management","Account Logon","Logon/Logoff","Policy Change","System" /failure:enable /success:enable

#authorized policy change, Audit PNP Activity, Audit File System, Audit Filtering Platform Connection, Other Object Access  
auditpol /set /subcategory:"{0CCE9231-69AE-11D9-BED3-505054503030}","{0cce9248-69ae-11d9-bed3-505054503030}","{0CCE921D-69AE-11D9-BED3-505054503030}","{0CCE9226-69AE-11D9-BED3-505054503030}","{0CCE9227-69AE-11D9-BED3-505054503030}" /failure:enable /success:enable

Limit-Eventlog -Logname "Security" -MaximumSize 1.0Gb -OverflowAction OverwriteAsNeeded 


#################################################

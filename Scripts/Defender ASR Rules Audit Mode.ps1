# Configure Microsoft Defender preferences

# Block abuse of exploited vulnerable signed drivers
Add-MpPreference -AttackSurfaceReductionRules_Ids "56a863a9-875e-4185-98a7-b882c64b5ce5" -AttackSurfaceReductionRules_Actions Audit

# Block Adobe Reader from creating child processes
Add-MpPreference -AttackSurfaceReductionRules_Ids "7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c" -AttackSurfaceReductionRules_Actions Audit

# Block all Office applications from creating child processes
Add-MpPreference -AttackSurfaceReductionRules_Ids "d4f940ab-401b-4efc-aadc-ad5f3c50688a" -AttackSurfaceReductionRules_Actions Audit

# Block credential stealing from lsass.exe
Add-MpPreference -AttackSurfaceReductionRules_Ids "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2" -AttackSurfaceReductionRules_Actions Audit

# Block executable content from email client and webmail
Add-MpPreference -AttackSurfaceReductionRules_Ids "be9ba2d9-53ea-4cdc-84e5-9b1eeee46550" -AttackSurfaceReductionRules_Actions Audit

# Block executable files from running unless they meet criteria
Add-MpPreference -AttackSurfaceReductionRules_Ids "01443614-cd74-433a-b99e-2ecdc07bfc25" -AttackSurfaceReductionRules_Actions Audit

# Block execution of potentially obfuscated scripts
Add-MpPreference -AttackSurfaceReductionRules_Ids "5beb7efe-fd9a-4556-801d-275e5ffc04cc" -AttackSurfaceReductionRules_Actions Audit

# Block JavaScript or VBScript from launching downloaded executable content
Add-MpPreference -AttackSurfaceReductionRules_Ids "d3e037e1-3eb8-44c8-a917-57927947596d" -AttackSurfaceReductionRules_Actions Audit

# Block Office applications from creating executable content
Add-MpPreference -AttackSurfaceReductionRules_Ids "3b576869-a4ec-4529-8536-b80a7769e899" -AttackSurfaceReductionRules_Actions Audit

# Block Office applications from injecting code into other processes
Add-MpPreference -AttackSurfaceReductionRules_Ids "75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84" -AttackSurfaceReductionRules_Actions Audit

# Block Office communication application from creating child processes
Add-MpPreference -AttackSurfaceReductionRules_Ids "26190899-1602-49e8-8b27-eb1d0a1ce869" -AttackSurfaceReductionRules_Actions Audit

# Block persistence through WMI event subscription (file and folder exclusions not supported)
Add-MpPreference -AttackSurfaceReductionRules_Ids "e6db77e5-3df2-4cf1-b95a-636979351e5b" -AttackSurfaceReductionRules_Actions Audit

# Block process creations originating from PSExec and WMI commands
Add-MpPreference -AttackSurfaceReductionRules_Ids "d1e49aac-8f56-4280-b9ba-993a6d77406c" -AttackSurfaceReductionRules_Actions Audit

# Block rebooting machine in Safe Mode (preview)
Add-MpPreference -AttackSurfaceReductionRules_Ids "33ddedf1-c6e0-47cb-833e-de6133960387" -AttackSurfaceReductionRules_Actions Audit

# Block untrusted and unsigned processes that run from USB
Add-MpPreference -AttackSurfaceReductionRules_Ids "b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4" -AttackSurfaceReductionRules_Actions Audit

# Block use of copied or impersonated system tools (preview)
Add-MpPreference -AttackSurfaceReductionRules_Ids "c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb" -AttackSurfaceReductionRules_Actions Audit

# Block Webshell creation for Servers
Add-MpPreference -AttackSurfaceReductionRules_Ids "a8f5898e-1dc8-49a9-9878-85004b8a61" -AttackSurfaceReductionRules_Actions Audit

#######Enable ATP Requried Auditing For Telementary Data ###########################################################################################################
auditpol /set /category:"Account Management","Account Logon","Logon/Logoff","Policy Change","System" /failure:enable /success:enable

 

#authorized policy change, Audit PNP Activity, Audit File System, Audit Filtering Platform Connection, Other Object Access  
auditpol /set /subcategory:"{0CCE9231-69AE-11D9-BED3-505054503030}","{0cce9248-69ae-11d9-bed3-505054503030}","{0CCE921D-69AE-11D9-BED3-505054503030}","{0CCE9226-69AE-11D9-BED3-505054503030}","{0CCE9227-69AE-11D9-BED3-505054503030}" /failure:enable /success:enable

 

Limit-Eventlog -Logname "Security" -MaximumSize 1.0Gb -OverflowAction OverwriteAsNeeded

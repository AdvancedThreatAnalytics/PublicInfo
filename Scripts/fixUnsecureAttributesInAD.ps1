$noPwdRequired = Get-ADUser -LDAPFilter "(&(objectClass=user)(objectCategory=person)(userAccountControl:1.2.840.113556.1.4.803:=32))" -SearchBase "DC=MyOrg,DC=tld"
if ($noPwdRequired -ne $null){
    foreach($user in $noPwdRequired ){
     write-host $user.sAMAccountName "Has PASSWD_NOTREQD Value Enabled" -ForegroundColor Red -BackgroundColor Black
     Write-Host "Located Under.."$user.DistinguishedName -ForegroundColor Cyan -BackgroundColor black
     Set-ADAccountControl $user -PasswordNotRequired $false   
    }
}

$preAuth = Get-ADUser -LDAPFilter "(&(objectClass=user)(objectCategory=person)(userAccountControl:1.2.840.113556.1.4.803:=4194304))" -SearchBase "DC=MyOrg,DC=tld"  
if ($preAuth -ne $null){
    foreach($user in $preAuth ){
     write-host $user.sAMAccountName "Does Not Req Kerberos PRE-AUTH" -ForegroundColor Red -BackgroundColor Black
     Write-Host "Located Under.."$user.DistinguishedName -ForegroundColor Cyan -BackgroundColor black
     Set-ADAccountControl $user -DoesNotRequirePreAuth $false
     }
}


$reverse = Get-ADUser -LDAPFilter "(&(objectClass=user)(objectCategory=person)(userAccountControl:1.2.840.113556.1.4.803:=128))" -SearchBase "DC=MyOrg,DC=tld"  
if ($reverse -ne $null){
    
    foreach($user in $reverse ){
     write-host $user.sAMAccountName "Password Is Stored In Reversible Encryption" -ForegroundColor Red -BackgroundColor Black
     Write-Host "Located Under.."$user.DistinguishedName -ForegroundColor Cyan -BackgroundColor black
     Set-ADAccountControl $user -AllowReversiblePasswordEncryption $false
    }
}


$des = Get-ADUser -LDAPFilter "(&(objectClass=user)(objectCategory=person)(userAccountControl:1.2.840.113556.1.4.803:=2097152))" -SearchBase "DC=MyOrg,DC=tld" 

if ($des -ne $null){

    foreach($user in $des ){
     write-host $user.sAMAccountName "Password Is Using DES Encryption" -ForegroundColor Red -BackgroundColor Black
     Write-Host "Located Under.."$user.DistinguishedName -ForegroundColor Cyan -BackgroundColor black
     Set-ADAccountControl $user -UseDESKeyOnly $false
    }
}

$AES128 = 0x8

$AES256 = 0x10


$users = Get-ADUser -Filter * -SearchBase "DC=MyOrg,DC=tld" -Properties "msDS-SupportedEncryptionTypes"

foreach($user in $users){

    $encTypes = $user."msDS-SupportedEncryptionTypes"

    #if both types not supported, Enabled AES25
    if (($encTypes -band $AES128) -ne $AES128 -and ($encTypes -band $AES256) -ne $AES256){
        write-host $user.sAMAccountName "Applying 256 AES Encryption" -ForegroundColor Red -BackgroundColor Black
        Write-Host "Located Under.."$user.DistinguishedName -ForegroundColor Cyan -BackgroundColor black
        Set-ADUser $User -Replace @{"msDS-SupportedEncryptionTypes"=($encTypes -bor $AES256)}
    }

}

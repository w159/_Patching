
$SecureBootState = Get-ItemPropertyValue HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State -Name UEFISecureBootEnabled

if ($SecureBootState -notlike "1") {
    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -Name UEFISecureBootEnabled -Value 1
}

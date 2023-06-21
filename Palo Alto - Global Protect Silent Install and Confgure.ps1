
# Install latest Global Protect silently
$GlobalProtectVersion = (Get-CimInstance -ClassName win32_product | Where-Object Name -Like "GlobalProtect").Version
if ($GlobalProtectVersion -ne "6.2.0") {
    Start-Process -FilePath ".\GlobalProtect64-6.2.0.msi" -ArgumentList '/quiet /L*V "C:\Utils\PAGlobalProtectInstaller.log"' -WindowStyle Hidden -Wait
}


# Configure Global Protect Portals
New-PSDrive -PSProvider 'Registry' -Name 'HKU' -Root 'HKEY_USERS'
$users = Get-ChildItem 'HKU:\'
$portalNames = @('vpn3.henssler.com', 'vpn2.henssler.com', 'vpn.henssler.com')

foreach ($user in $users) {
    $LocalUser = $user.PSChildName

    foreach ($portalName in $portalNames) {
        $registryPath = "HKU:\$LocalUser\Software\Palo Alto Networks\GlobalProtect\Settings\$portalName"
        if (!(Test-Path -Path $registryPath)) {
            New-Item -Path $registryPath -Force
        }
    }
}

Restart-Service -Name 'PanGPS' -Force

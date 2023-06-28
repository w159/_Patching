# Create C:\Utils folder if it does not exist
if (!(Test-Path -Path 'C:\Utils'))
{
    New-Item -Path 'C:\Utils' -ItemType Directory
}

# Download the latest Global Protect installer
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -UseBasicParsing 'https://onedrive.live.com/download?resid=af928892ebcfb343%21197755&authkey=!AGxsrzC_GLRHM4o' -OutFile 'C:\Utils\GlobalProtect64-6.2.0.msi'

# Install latest Global Protect silently
$GlobalProtectVersion = (Get-CimInstance -ClassName win32_product | Where-Object Name -Like 'GlobalProtect').Version
if ($GlobalProtectVersion -ne '6.2.0')
{
    Start-Process -FilePath 'C:\Utils\GlobalProtect64-6.2.0.msi' -ArgumentList '/quiet /L*V "C:\Utils\PAGlobalProtectInstaller.log"' -WindowStyle Hidden -Wait
}

# Configure Global Protect Portals
New-PSDrive -PSProvider 'Registry' -Name 'HKU' -Root 'HKEY_USERS'
$users = Get-ChildItem 'HKU:\'
$portalNames = @('vpn3.henssler.com', 'vpn2.henssler.com', 'vpn.henssler.com')

foreach ($user in $users)
{
    $LocalUser = $user.PSChildName

    foreach ($portalName in $portalNames)
    {
        $registryPath = "HKU:\$LocalUser\Software\Palo Alto Networks\GlobalProtect\Settings\$portalName"
        if (!(Test-Path -Path $registryPath))
        {
            New-Item -Path $registryPath -Force
        }
    }
}

Restart-Service -Name 'PanGPS' -Force

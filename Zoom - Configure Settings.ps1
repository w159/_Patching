# Zoom Desktop System Settings
New-Item -Path "HKLM:\SOFTWARE\ZoomUMX\PerInstall" -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\ZoomUMX\PerInstall" -Name 'enableupdate' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path "HKLM:\SOFTWARE\ZoomUMX\PerInstall" -Name 'nodesktopshortcut' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path "HKLM:\SOFTWARE\ZoomUMX\PerInstall" -Name 'silentstart' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue

# Configure Zoom Desktop Per User Settings
New-PSDrive -PSProvider 'Registry' -Name 'HKU' -Root 'HKEY_USERS'
$users = Get-ChildItem 'HKU:\'

foreach ($user in $users){

$LocalUser = $user.name
New-Item -Path "HKU:\$LocalUser\SOFTWARE\ZoomUMX" -Force
New-ItemProperty -Path "HKU:\$LocalUser\SOFTWARE\ZoomUMX" -Name 'enableupdate' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path "HKU:\$LocalUser\SOFTWARE\ZoomUMX" -Name 'nodesktopshortcut' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue
New-ItemProperty -Path "HKU:\$LocalUser\SOFTWARE\ZoomUMX" -Name 'silentstart' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue

                         }
# Remove Palo Alto GlobalProtect software
$PaloAltoGlobalProtect = Get-WmiObject -ClassName Win32_Product | Where-Object Name -Like 'GlobalProtect'
if ($PaloAltoGlobalProtect) {
     $PaloAltoGlobalProtect.Uninstall()
}

# Remove GlobalProtect installer log file
$PAGlobalProtectLog = Test-Path 'C:\Utils\PAGlobalProtectInstaller.log'
if ($PAGlobalProtectLog) {
     Remove-Item -Path 'C:\Utils\PAGlobalProtectInstaller.log' -Force -Recurse
}

# Remove registry entries for Palo Alto Networks from all user profiles
New-PSDrive -PSProvider 'Registry' -Name 'HKU' -Root 'HKEY_USERS'
$users = Get-ChildItem 'HKU:\'
foreach ($user in $users) {
     $LocalUser = $user.PSChildName
     $registryPath = "HKU:\$LocalUser\Software\Palo Alto Networks"
     if (Test-Path -Path $registryPath) {
          Remove-Item -Path $registryPath -Force -Recurse
     }
}

# Remove Palo Alto Networks folder from each user's AppData directory
$UserFolders = Get-ChildItem -Path 'C:\Users'
foreach ($UserFolder in $UserFolders) {
     $LocalUser = $UserFolder.Name
     $GlobalProtectUserFolder = "C:\Users\$LocalUser\AppData\Local\Palo Alto Networks"
     if (Test-Path -Path $GlobalProtectUserFolder) {
          Remove-Item -Path $GlobalProtectUserFolder -Force -Recurse
     }
}

# Remove specified paths related to Palo Alto Networks
$PathsToDelete = @(
     'C:\Program Files\Palo Alto Networks',
     'HKLM:\SOFTWARE\Palo Alto Networks'
)

foreach ($Path in $PathsToDelete) {
     if (Test-Path -Path $Path) {
          Remove-Item -Path $Path -Force -Recurse
     }
}

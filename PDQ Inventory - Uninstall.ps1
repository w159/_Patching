$AppName = 'PDQ Inventory Agent'
$Publisher = 'PDQ.com'
foreach ($Architecture in 'SOFTWARE', 'SOFTWARE\Wow6432Node') {
     $UninstallKeys = "HKLM:\$Architecture\Microsoft\Windows\CurrentVersion\Uninstall"
     if (Test-Path $UninstallKeys) {
          Write-Output "Checking for $AppName in $UninstallKeys"
          $AgentInstallation = Get-ItemProperty -Path "$UninstallKeys\*" |
               Where-Object { $_.DisplayName -eq $AppName -and $_.Publisher -eq $Publisher }
          $AgentInstallations += $AgentInstallation
     }
}If ($AgentInstallations) {
     $AgentInstallations | ForEach-Object { Stop-Service 'PDQ Inventory Agent' -Force Start-Sleep 5 Write-Output "Uninstalling $($_.DisplayName) - $($_.PSChildName)"
          Start-Process -Wait -FilePath 'MsiExec.exe' -ArgumentList "/X $($_.PSChildName) /qn /norestart" }
}
Else { Write-Output "No installations of $AppName found." }
$AgentPaths = "$env:ProgramData\Admin Arsenal\PDQ Inventory Agent", "$env:ProgramFiles\Admin Arsenal\PDQ Inventory Agent", "${env:ProgramFiles(x86)}\Admin Arsenal\PDQ Inventory Agent", "$env:windir\AdminArsenal\InstallAgentStep"
foreach ($Path in $AgentPaths) {
     if (Test-Path $Path) {
          Write-Output "Removing directory $Path" Remove-Item -Path $Path -Recurse
     }
}
$RegistryPath = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\PDQInventoryAgent'
if (Test-Path $RegistryPath) {
     Write-Output "Removing registry key $RegistryPath" Remove-Item -Path $RegistryPath -Recurse
}
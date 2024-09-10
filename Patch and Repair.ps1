#!ps
#maxlength=500000
#timeout=90000000
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Set-ExecutionPolicy Bypass -Scope Process -Force

$WingetLocation = Get-ChildItem -Recurse -Path "$Env:Programfiles\WindowsApps\Microsoft.DesktopAppInstaller*" | Where-Object Name -Like 'winget.exe' | Sort-Object LastWriteTime -Descending | Select-Object -First 1


if ($null -eq $WingetLocation) {
     Install-Script -Name winget-install -Force
     winget-install
     $WingetLocation = Get-ChildItem -Recurse -Path "$Env:Programfiles\WindowsApps\Microsoft.DesktopAppInstaller*" | Where-Object Name -Like 'winget.exe' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
     $WingetCLI = $WingetLocation.FullName
     Set-Alias -Name winget -Value $WingetCLI
     winget-install -CheckForUpdate
} else {
     $WingetCLI = $WingetLocation.FullName
     Set-Alias -Name winget -Value $WingetCLI
     Write-Output "winget.exe found at: $WingetCLI"
}
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements

Stop-Service -Name wuauserv -Force
Stop-Service -Name bits -Force
if (Test-Path -Path 'C:\Windows\SoftwareDistribution.bak') {
     Remove-Item -Path 'C:\Windows\SoftwareDistribution.bak' -Recurse -Force
}
if (Test-Path -Path 'C:\Windows\SoftwareDistribution') {
     Rename-Item -Path 'C:\Windows\SoftwareDistribution' -NewName 'SoftwareDistribution.bak' -Recurse -Force
}

Start-Service -Name wuauserv
Start-Service -Name bits
Stop-Service -Name cryptsvc -Force
New-Item -ItemType Directory -Path "$env:SystemRoot\system32\catroot2.old" -Force
Copy-Item -Path "$env:SystemRoot\system32\catroot2" -Destination "$env:SystemRoot\system32\catroot2.old" -Recurse -Force
Start-Service -Name cryptsvc


Invoke-Command -ScriptBlock { sfc /scannow }
Invoke-Command -ScriptBlock { DISM /Online /Cleanup-Image /RestoreHealth }

Install-Module -Name 'LSUClient'
Import-Module -Name 'LSUClient'
$updates = Get-LSUpdate -All | Where-Object { $_.IsApplicable -eq 'True' -and $_.IsInstalled -eq 'False' }
$updates | Save-LSUpdate -Verbose
$updates | Install-LSUpdate -Verbose

# Check for and uninstall applications using WMI
$Names = @('Teams', 'McAfee')
$InstalledProducts = Get-WmiObject -Class Win32_Product | Select-Object -ExpandProperty Name
foreach ($Name in $Names) {
     if ($InstalledProducts -contains $Name) {
          $Name.Uninstall()
          Write-Output "Uninstalling: $Name"
     } else {
          Write-Output "No matching application found: $Name"
     }
}

foreach ($Name in $Names) {
     $ConfirmUninstall = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $Name }
     if (!$ConfirmUninstall) {
          Write-Output "Confirmed: $Name has been uninstalled"
     } else {
          Write-Output "Failed to uninstall: $Name"
     }
}

# Check for and uninstall applications using winget
$Names = @('Teams Machine-Wide Installer', 'McAfee', 'Microsoft.OutlookForWindows')
foreach ($Name in $Names) {
     winget uninstall $Name --silent
     Write-Output "Uninstalling: $Name"
}

# Update Microsoft Store Apps
$namespaceName = 'root\cimv2\mdm\dmmap'
$className = 'MDM_EnterpriseModernAppManagement_AppManagement01'
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()
$result

# Update Office Apps
Start-Process -FilePath 'C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe' -ArgumentList '/update user displaylevel=false forceappshutdown=true Updatepromptuser=true' -Wait -NoNewWindow

# Install required modules
foreach ($RequiredModule in $RequiredModules) {
     if (-not (Get-Module $RequiredModule -ListAvailable)) {
          "Installing $RequiredModule now, please wait...."
          Install-Module $RequiredModule -Scope AllUsers -Force
     }
}

foreach ($RequiredModule in $RequiredModules) {
     "Importing $RequiredModule now, please wait...."
     Import-Module $RequiredModule
}

Install-WindowsUpdate -AcceptAll -Install -IgnoreReboot
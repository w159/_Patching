##

$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()
$result

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$WinGetUpdater_CHECK = Test-Path -Path C:\utils\Winget-AutoUpdate-main

If ($WinGetUpdater_CHECK -eq $false) {
    New-Item -Path C:\ -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue
    Invoke-WebRequest -UseBasicParsing 'https://github.com/w159/Winget-AutoUpdate/archive/refs/heads/main.zip' -OutFile 'C:\Utils\WinGetModule.zip'
    Expand-Archive -Path 'C:\Utils\WinGetModule.zip' -DestinationPath 'C:\Utils'
    Get-ChildItem C:\Utils\Winget-AutoUpdate-main -Recurse | Unblock-File -Confirm:$false
}

& ("C:\utils\Winget-AutoUpdate-main\Winget-AutoUpdate-Install.ps1") -Silent -NotificationLevel None -RunOnMetered -MaxLogFiles 10 -InstallUserContext -UpdatesAtLogon

& ("C:\utils\Winget-AutoUpdate-main\Winget-AutoUpdate\Winget-Upgrade.ps1")


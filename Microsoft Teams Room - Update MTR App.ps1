<#
Microsoft Teams Room - Update MTR App KB

https://learn.microsoft.com/en-us/MicrosoftTeams/rooms/manual-update#step-1-download-the-offline-app-update-script

#>

#!ps
#maxlength=500000
#timeout=90000000
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

$DownloadURL = 'https://go.microsoft.com/fwlink/?linkid=2151817'
$DownloadUpdateScript = 'C:\Temp\Update-MTRApp.ps1'
$TempFolder = 'C:\Temp'

if (-not (Test-Path -Path $TempFolder)) {
     New-Item -Path $TempFolder -ItemType Directory
}

if (Test-Path -Path $DownloadUpdateScript) {
     Remove-Item -Path $DownloadUpdateScript
}

Invoke-WebRequest -UseBasicParsing $DownloadURL -OutFile $DownloadUpdateScript
PowerShell -ExecutionPolicy Unrestricted $DownloadUpdateScript

C:\Users\Skype\AppData\Local\Packages\Microsoft.SkypeRoomSystem_8wekyb3d8bbwe\LocalState\Tracing\MTR-Update
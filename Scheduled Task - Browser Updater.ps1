
<#

.DESCRIPTION
This script creates additional PowerShell scripts that are used in a new Scheduled task to update Web Browsers

To mitigate unintended elevation attempts, the scripts are placed in C:\Windows\Utils

These scripts are currently working for Chrome, Edge, FireFox, and Brave as of 5-31-23

#>

Get-ScheduledTask | Where-Object TaskName -EQ 'Chromium Browser Updates' | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
Get-ScheduledTask | Where-Object TaskName -EQ '- Browser Updater' | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
Get-ScheduledTask | Where-Object TaskName -EQ 'S5 - Browser *' | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

$ProgressPreference = 'SilentlyContinue'
$PowerShellVersion = (Get-Host).Version.Major
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

If ($PowerShellVersion -lt '5')
{
  Invoke-WebRequest -UseBasicParsing 'https://github.com/PowerShell/PowerShell/releases/download/v7.3.3/PowerShell-7.3.3-win-x64.msi' -OutFile 'C:\Utils\PowerShell.msi' -Wait
  Start-Process -FilePath 'C:\Utils\PowerShell.msi' -ArgumentList '/qn'
}

New-Item -Path 'C:\Windows' -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue

$ChromeBrowserUpdatesScript = @"
`$ProgressPreference = 'SilentlyContinue'
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
`$ChromiumTeamGitAPI = Invoke-RestMethod -UseBasicParsing "https://omahaproxy.appspot.com/json"
`$ChromeMSI = "C:\Utils\googlechromestandaloneenterprise.msi"
`$ChromeCurrentVersion = `$ChromiumTeamGitAPI.Versions | Where-Object { `$_.OS -like 'win' -and `$_.Channel -eq 'Stable' } | Select-Object -ExpandProperty current_version
`$ChromeDownloadMSILink_x64 = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
`$InstallArgs = "/qn /norestart /L*V C:\Utils\ChromeUpdater.log"
`$ChromeVersion = Get-WmiObject win32_product | Where-Object Name -Like *Chrome* | Select-Object -ExpandProperty Version -ErrorAction SilentlyContinue
`$ChromeInstalledVersionX86 = (Get-Item "C:\Program Files (x86)\Google\Chrome\Application\Chrome.exe" -ErrorAction SilentlyContinue).VersionInfo | Select-Object -ExpandProperty ProductVersion
`$ChromeInstalledVersion = (Get-Item "C:\Program Files\Google\Chrome\Application\Chrome.exe" -ErrorAction SilentlyContinue).VersionInfo | Select-Object -ExpandProperty ProductVersion
`$Versions = @(
  @{Name = "Chrome WMI"; Version = `$ChromeVersion },
  @{Name = "Chrome 64-bit"; Version = `$ChromeInstalledVersion },
  @{Name = "Chrome 32-bit"; Version = `$ChromeInstalledVersionX86 }
)

`$VersionsToUpdate = `$Versions | Where-Object { !([string]::IsNullOrEmpty(`$_.Version) -or `$_.Version -eq `$ChromeCurrentVersion) }

if (`$VersionsToUpdate) {
  Write-Host "Updating Chrome to the latest version `$ChromeCurrentVersion." -ForegroundColor Yellow -BackgroundColor Red
  Invoke-WebRequest -UseBasicParsing `$ChromeDownloadMSILink_x64 -OutFile `$ChromeMSI
  Unblock-File `$ChromeMSI
  Start-Process `$ChromeMSI -ArgumentList `$InstallArgs -Wait -ErrorAction SilentlyContinue -Verbose
  Get-Process | Where-Object Name -Like *CHROME* | Stop-Process -Force -ErrorAction SilentlyContinue
}
else {
  Write-Host "All versions of Chrome installed on this computer match the latest version of `$ChromeCurrentVersion."
}
"@

$EdgeBrowserUpdatesScript = @"
`$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
`$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36 Edg/112.0.1722.71"
`$download_api_url = "https://edgeupdates.microsoft.com/api/products"
`$release_branch = "Stable"

`$download_api_content = (Invoke-WebRequest -UserAgent `$userAgent -UseBasicParsing `$download_api_url).Content
`$json_data = `$download_api_content | ConvertFrom-Json
`$releases = `$json_data | Where-Object -Property Product -eq `$release_branch | Select-Object Releases

`$download_url_64 = (`$releases.Releases | Where-Object { `$_.Platform -eq 'Windows' } | Where-Object {`$_.Architecture -eq 'x64'}).Artifacts.Location
`$download_hash_64 = (`$releases.Releases | Where-Object { `$_.Platform -eq 'Windows' } | Where-Object {`$_.Architecture -eq 'x64'}).Artifacts.Hash
`$version_number = (`$releases.Releases | Where-Object { `$_.Platform -eq 'Windows' } | Where-Object {`$_.Architecture -eq 'x64'}).ProductVersion.Trim()
`$Latest = @{URL64 = `$download_url_64; Version = `$version_number; Checksum64 = `$download_hash_64}

`$LatestVersion = `$Latest.Version
`$LatestDownload = `$Latest.URL64
`$EdgeMSI = "C:\Utils\EdgeEnterpriseX64.msi"

if (`$InstalledVersions -notcontains `$LatestVersion) {

        Write-Host "Updating Microsoft Edge"
        Write-Host "Found Edge Version `$InstalledVersions, updating to `$LatestVersion." -ForegroundColor Yellow -BackgroundColor Red
        New-Item -Path "C:\" -Name "Utils" -ItemType Directory -Force -ErrorAction SilentlyContinue
        Invoke-WebRequest -UserAgent `$userAgent -UseBasicParsing `$LatestDownload -OutFile `$EdgeMSI
        Start-Process `$EdgeMSI -ArgumentList "/silent /install /closeapplications /forceappshutdown /norestart /logs c:\Utils\EdgeUpdater.log" -Wait
        Get-Process | Where-Object Name -Like *EDGE* | Stop-Process -Force -ErrorAction SilentlyContinue

    }
else {

    Write-Host "All versions of Microsoft Edge installed on this computer match the latest version of `$LatestVersion."

}
"@

$FirefoxBrowserUpdatesScript = @"
`$ProgressPreference = 'SilentlyContinue'

`$firefoxVersions = (Invoke-RestMethod -UseBasicParsing 'https://product-details.mozilla.org/1.0/firefox_versions.json')
`$firefoxLatestVersion = `$firefoxVersions.latest_firefox_version
`$firefoxPaths = "C:\Program Files (x86)\Mozilla Firefox\firefox.exe", "C:\Program Files\Mozilla Firefox\firefox.exe"
`$installedVersions = `$firefoxPaths | Where-Object { Test-Path `$_ } | ForEach-Object { (Get-Item `$_).VersionInfo.ProductVersion }

if (`$installedVersions.Count -eq 0) {
  Write-Host "Firefox is not installed." -ForegroundColor Yellow -BackgroundColor Red
} elseif (`$installedVersions -eq `$firefoxLatestVersion) {
  Write-Host "All versions of Firefox installed on this computer match the latest version of `$firefoxLatestVersion."
} else {
  `$versionsToUpdate = `$installedVersions | Where-Object { `$_ -ne `$firefoxLatestVersion }
  `$versionsToUpdate | ForEach-Object {
    `$firefoxPath = `$firefoxPaths[`$installedVersions.IndexOf(`$_)]
    Write-Host "Found Firefox `$(`$firefoxPath.Split('\')[-3]) Version `$_. Updating to latest version `$firefoxLatestVersion." -ForegroundColor Yellow -BackgroundColor Red
    New-Item -Path "C:\" -Name "Utils" -ItemType Directory -Force
    `$firefoxDownloadLink = "https://download.mozilla.org/?product=firefox-latest-ssl&os=`$(if (`$firefoxPath -match 'x86') { 'win' } else { 'win64' })&lang=en-US"
    Invoke-WebRequest -UseBasicParsing `$firefoxDownloadLink -OutFile "C:\Utils\Firefox`$(`$firefoxPath.Split('\')[-3])LatestSetup.exe"
    Start-Process "C:\Utils\Firefox`$(`$firefoxPath.Split('\')[-3])LatestSetup.exe" -ArgumentList "/S /DesktopShortcut=false /TaskbarShortcut=false /StartMenuShortcut=false" -Wait
    Get-Process | Where-Object Name -Like *FIREFOX* | Stop-Process -Force -ErrorAction SilentlyContinue
  }
}
"@

New-Item -Path 'C:\Windows\Utils' -Name ChromeBrowserUpdates.ps1 -ItemType File -Value $ChromeBrowserUpdatesScript -Force
New-Item -Path 'C:\Windows\Utils' -Name EdgeBrowserUpdates.ps1 -ItemType File -Value $EdgeBrowserUpdatesScript -Force
New-Item -Path 'C:\Windows\Utils' -Name FirefoxBrowserUpdates.ps1 -ItemType File -Value $FirefoxBrowserUpdatesScript -Force

$Hours = 1, 2, 3, 4, 5, 5, 21, 22, 23 | Get-Random -Count 1
$Minutes = Get-Random -Minimum 00 -Maximum 59
$Time = Get-Date -Hour $Hours -Minute $Minutes -UFormat %r
$Trigger = (New-ScheduledTaskTrigger -Daily -At $Time)
$User = 'NT AUTHORITY\SYSTEM'

$Action = (New-ScheduledTaskAction -Execute 'POWERSHELL' -Argument '-ExecutionPolicy Bypass -File "C:\Windows\Utils\ChromeBrowserUpdates.ps1"'),
          (New-ScheduledTaskAction -Execute 'POWERSHELL' -Argument '-ExecutionPolicy Bypass -File "C:\Windows\Utils\EdgeBrowserUpdates.ps1"'),
          (New-ScheduledTaskAction -Execute 'POWERSHELL' -Argument '-ExecutionPolicy Bypass -File "C:\Windows\Utils\FirefoxBrowserUpdates.ps1"'),
          (New-ScheduledTaskAction -Execute 'C:\Program Files (x86)\BraveSoftware\Update\BraveUpdate.exe' -Argument '/ua /installsource scheduler'),
          (New-ScheduledTaskAction -Execute 'C:\Program Files\BraveSoftware\Update\BraveUpdate.exe' -Argument '/ua /installsource scheduler')

$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

$TaskName = 'Browser Updater v3.12.24'
$Description = 'This task should ensure that the popular web browsers are updated to the latest version available according to the browser developer. Created by JM; Last updated 5-31-23'

Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -User $User -Action $Action -Settings $Settings -RunLevel Highest -Force -Description $Description

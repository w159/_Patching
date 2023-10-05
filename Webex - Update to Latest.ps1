$ProgressPreference = 'SilentlyContinue'
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12


$Version = Get-Version -Uri 'https://help.webex.com/en-us/mqkve8/Webex-Release-Notes' -Pattern 'Version:\s((?:\d+\.)+(?:\d+))</p>'
$URL64 = Get-Link -Uri 'https://help.webex.com/en-us/nw5p67g/Webex-Installation-and-Automatic-Upgrade' -MatchProperty href -Pattern 'Webex\.msi'
Get-Version -Uri 'https://help.webex.com/en-us/8zi8ve/Webex-Release-Notes' -MaximumRedirection 5 -Pattern 'Version:\s((?:\d+\.)+(?:\d+))</p>'

$WebexMSI = 'C:\Utils\googleWebexstandaloneenterprise.msi'
$WebexCurrentVersion = $ChromiumTeamGitAPI.Versions | Where-Object { $_.OS -like 'win' -and $_.Channel -eq 'Stable' } | Select-Object -ExpandProperty current_version
$WebexDownloadMSILink_x64 = 'https://dl.google.com/dl/Webex/install/googleWebexstandaloneenterprise64.msi'
$InstallArgs = '/qn /norestart /L*V C:\Utils\WebexUpdater.log'
$WebexVersion = Get-WmiObject win32_product | Where-Object Name -Like *Webex* | Select-Object -ExpandProperty Version -ErrorAction SilentlyContinue
$WebexInstalledVersionX86 = (Get-Item 'C:\Program Files (x86)\Google\Webex\Application\Webex.exe' -ErrorAction SilentlyContinue).VersionInfo | Select-Object -ExpandProperty ProductVersion
$WebexInstalledVersion = (Get-Item 'C:\Program Files\Google\Webex\Application\Webex.exe' -ErrorAction SilentlyContinue).VersionInfo | Select-Object -ExpandProperty ProductVersion
$Versions = @(
  @{Name = 'Webex WMI'; Version = $WebexVersion },
  @{Name = 'Webex 64-bit'; Version = $WebexInstalledVersion },
  @{Name = 'Webex 32-bit'; Version = $WebexInstalledVersionX86 }
)

$VersionsToUpdate = $Versions | Where-Object { !([string]::IsNullOrEmpty($_.Version) -or $_.Version -eq $WebexCurrentVersion) }

if ($VersionsToUpdate) {
  Write-Host "Updating Webex to the latest version $WebexCurrentVersion." -ForegroundColor Yellow -BackgroundColor Red
  Invoke-WebRequest -UseBasicParsing $WebexDownloadMSILink_x64 -OutFile $WebexMSI
  Unblock-File $WebexMSI
  Start-Process $WebexMSI -ArgumentList $InstallArgs -Wait -ErrorAction SilentlyContinue -Verbose
  Get-Process | Where-Object Name -Like *Webex* | Stop-Process -Force -ErrorAction SilentlyContinue
}
else {
  Write-Host "All versions of Webex installed on this computer match the latest version of $WebexCurrentVersion."
}

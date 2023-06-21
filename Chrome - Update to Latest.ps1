$ProgressPreference = 'SilentlyContinue'
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$ChromiumTeamGitAPI = Invoke-RestMethod -UseBasicParsing 'https://omahaproxy.appspot.com/json'
$ChromeMSI = 'C:\Utils\googlechromestandaloneenterprise.msi'
$ChromeCurrentVersion = $ChromiumTeamGitAPI.Versions | Where-Object { $_.OS -like 'win' -and $_.Channel -eq 'Stable' } | Select-Object -ExpandProperty current_version
$ChromeDownloadMSILink_x64 = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'
$InstallArgs = '/qn /norestart /L*V C:\Utils\ChromeUpdater.log'
$ChromeVersion = Get-WmiObject win32_product | Where-Object Name -Like *Chrome* | Select-Object -ExpandProperty Version -ErrorAction SilentlyContinue
$ChromeInstalledVersionX86 = (Get-Item 'C:\Program Files (x86)\Google\Chrome\Application\Chrome.exe' -ErrorAction SilentlyContinue).VersionInfo | Select-Object -ExpandProperty ProductVersion
$ChromeInstalledVersion = (Get-Item 'C:\Program Files\Google\Chrome\Application\Chrome.exe' -ErrorAction SilentlyContinue).VersionInfo | Select-Object -ExpandProperty ProductVersion
$Versions = @(
  @{Name = 'Chrome WMI'; Version = $ChromeVersion },
  @{Name = 'Chrome 64-bit'; Version = $ChromeInstalledVersion },
  @{Name = 'Chrome 32-bit'; Version = $ChromeInstalledVersionX86 }
)

$VersionsToUpdate = $Versions | Where-Object { !([string]::IsNullOrEmpty($_.Version) -or $_.Version -eq $ChromeCurrentVersion) }

if ($VersionsToUpdate)
{
  Write-Host "Updating Chrome to the latest version $ChromeCurrentVersion." -ForegroundColor Yellow -BackgroundColor Red
  Invoke-WebRequest -UseBasicParsing $ChromeDownloadMSILink_x64 -OutFile $ChromeMSI
  Unblock-File $ChromeMSI
  Start-Process $ChromeMSI -ArgumentList $InstallArgs -Wait -ErrorAction SilentlyContinue -Verbose
  Get-Process | Where-Object Name -Like *CHROME* | Stop-Process -Force -ErrorAction SilentlyContinue
}
else
{
  Write-Host "All versions of Chrome installed on this computer match the latest version of $ChromeCurrentVersion."
}

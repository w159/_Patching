

$ProgressPreference = 'SilentlyContinue'
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$ScanSnapUpdater = Invoke-RestMethod -UseBasicParsing 'https://origin.pfultd.com/downloads/ss/xml/WinSSHDownloadInstaller.xml'

# convert $ScanSnapUpdater from xml
$ScanSnapHomeDownload = 'https://origin.pfultd.com/downloads/IMAGE/driver/ss/inst2/ix1500/w-software/WinSSHomeInstaller_2_10_1.exe'
$ScanSnapHomeMSI = 'C:\Utils\ScanSnapHomeUpdater.exe'
$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36 Edg/112.0.1722.71'

    Invoke-WebRequest -UseBasicParsing $ScanSnapHomeDownload -OutFile $ScanSnapHomeMSI -UserAgent $UserAgent
    Unblock-File $ScanSnapHomeMSI
    Start-Process $ScanSnapHomeMSI -Wait -ErrorAction SilentlyContinue -Verbose









$ScanSnapHomeCurrentVersion = $ChromiumTeamGitAPI.Versions | Where-Object { $_.OS -like 'win' -and $_.Channel -eq 'Stable' } | Select-Object -ExpandProperty current_version
$ScanSnapHomeDownloadMSILink_x64 = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'
$InstallArgs = '/qn /norestart /L*V C:\Utils\ChromeUpdater.log'
$ScanSnapHomeVersion = Get-WmiObject win32_product | Where-Object Name -Like *Chrome* | Select-Object -ExpandProperty Version -ErrorAction SilentlyContinue
$ScanSnapHomeInstalledVersionX86 = (Get-Item 'C:\Program Files (x86)\Google\Chrome\Application\Chrome.exe' -ErrorAction SilentlyContinue).VersionInfo | Select-Object -ExpandProperty ProductVersion
$ScanSnapHomeInstalledVersion = (Get-Item 'C:\Program Files\Google\Chrome\Application\Chrome.exe' -ErrorAction SilentlyContinue).VersionInfo | Select-Object -ExpandProperty ProductVersion
$Versions = @(
    @{Name = 'Chrome WMI'; Version = $ScanSnapHomeVersion },
    @{Name = 'Chrome 64-bit'; Version = $ScanSnapHomeInstalledVersion },
    @{Name = 'Chrome 32-bit'; Version = $ScanSnapHomeInstalledVersionX86 }
)

$VersionsToUpdate = $Versions | Where-Object { !([string]::IsNullOrEmpty($_.Version) -or $_.Version -eq $ScanSnapHomeCurrentVersion) }

if ($VersionsToUpdate)
{
    Write-Host "Updating Chrome to the latest version $ScanSnapHomeCurrentVersion." -ForegroundColor Yellow -BackgroundColor Red
    Invoke-WebRequest -UseBasicParsing $ScanSnapHomeDownloadMSILink_x64 -OutFile $ScanSnapHomeMSI
    Unblock-File $ScanSnapHomeMSI
    Start-Process $ScanSnapHomeMSI -ArgumentList $InstallArgs -Wait -ErrorAction SilentlyContinue -Verbose
    Get-Process | Where-Object Name -Like *CHROME* | Stop-Process -Force -ErrorAction SilentlyContinue
}
else
{
    Write-Host "All versions of Chrome installed on this computer match the latest version of $ScanSnapHomeCurrentVersion."
}

$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36 Edg/112.0.1722.71'
$download_api_url = 'https://edgeupdates.microsoft.com/api/products'
$release_branch = 'Stable'

$download_api_content = (Invoke-WebRequest -UserAgent $userAgent -UseBasicParsing $download_api_url).Content
$json_data = $download_api_content | ConvertFrom-Json
$releases = $json_data | Where-Object -Property Product -EQ $release_branch | Select-Object Releases

$download_url_64 = ($releases.Releases | Where-Object { $_.Platform -eq 'Windows' } | Where-Object { $_.Architecture -eq 'x64' }).Artifacts.Location
$download_hash_64 = ($releases.Releases | Where-Object { $_.Platform -eq 'Windows' } | Where-Object { $_.Architecture -eq 'x64' }).Artifacts.Hash
$version_number = ($releases.Releases | Where-Object { $_.Platform -eq 'Windows' } | Where-Object { $_.Architecture -eq 'x64' }).ProductVersion.Trim()
$Latest = @{URL64 = $download_url_64; Version = $version_number; Checksum64 = $download_hash_64 }

$LatestVersion = $Latest.Version
$LatestDownload = $Latest.URL64
$EdgeMSI = 'C:\Utils\EdgeEnterpriseX64.msi'

if ($InstalledVersions -notcontains $LatestVersion)
{

    Write-Host 'Updating Microsoft Edge'
    Write-Host "Found Edge Version $InstalledVersions, updating to $LatestVersion." -ForegroundColor Yellow -BackgroundColor Red
    New-Item -Path 'C:\' -Name 'Utils' -ItemType Directory -Force -ErrorAction SilentlyContinue
    Invoke-WebRequest -UserAgent $userAgent -UseBasicParsing $LatestDownload -OutFile $EdgeMSI
    Start-Process $EdgeMSI -ArgumentList '/silent /install /closeapplications /forceappshutdown /norestart /logs c:\Utils\EdgeUpdater.log' -Wait
    Get-Process | Where-Object Name -Like *EDGE* | Stop-Process -Force -ErrorAction SilentlyContinue

}
else
{

    Write-Host "All versions of Microsoft Edge installed on this computer match the latest version of $LatestVersion."

}

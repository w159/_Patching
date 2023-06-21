$ProgressPreference = 'SilentlyContinue'

$firefoxVersions = (Invoke-RestMethod -UseBasicParsing 'https://product-details.mozilla.org/1.0/firefox_versions.json')
$firefoxLatestVersion = $firefoxVersions.latest_firefox_version
$firefoxPaths = 'C:\Program Files (x86)\Mozilla Firefox\firefox.exe', 'C:\Program Files\Mozilla Firefox\firefox.exe'
$installedVersions = $firefoxPaths | Where-Object { Test-Path $_ } | ForEach-Object { (Get-Item $_).VersionInfo.ProductVersion }

if ($installedVersions.Count -eq 0)
{
  Write-Host 'Firefox is not installed.' -ForegroundColor Yellow -BackgroundColor Red
}
elseif ($installedVersions -eq $firefoxLatestVersion)
{
  Write-Host "All versions of Firefox installed on this computer match the latest version of $firefoxLatestVersion."
}
else
{
  $versionsToUpdate = $installedVersions | Where-Object { $_ -ne $firefoxLatestVersion }
  $versionsToUpdate | ForEach-Object {
    $firefoxPath = $firefoxPaths[$installedVersions.IndexOf($_)]
    Write-Host "Found Firefox $($firefoxPath.Split('\')[-3]) Version $_. Updating to latest version $firefoxLatestVersion." -ForegroundColor Yellow -BackgroundColor Red
    New-Item -Path 'C:\' -Name 'Utils' -ItemType Directory -Force
    $firefoxDownloadLink = "https://download.mozilla.org/?product=firefox-latest-ssl&os=$(if ($firefoxPath -match 'x86') { 'win' } else { 'win64' })&lang=en-US"
    Invoke-WebRequest -UseBasicParsing $firefoxDownloadLink -OutFile "C:\Utils\Firefox$($firefoxPath.Split('\')[-3])LatestSetup.exe"
    Start-Process "C:\Utils\Firefox$($firefoxPath.Split('\')[-3])LatestSetup.exe" -ArgumentList '/S /DesktopShortcut=false /TaskbarShortcut=false /StartMenuShortcut=false' -Wait
    Get-Process | Where-Object Name -Like *FIREFOX* | Stop-Process -Force -ErrorAction SilentlyContinue
  }
}

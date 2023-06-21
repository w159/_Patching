<#
.DESCRIPTION
This script uses the Adobe Remote Update Manager tool to update ALL modern installed Adobe Apps

Legacy Reader apps and those not part of Creative Cloud are not patched as part of this

#>

# Setting download settings
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

# Check for the Adobe Remote Update Manager
$AdobeRemoteUpdateManager_CHECK = Test-Path -Path 'C:\Utils\AdobeRUM\RemoteUpdateManager.exe'

if ($AdobeRemoteUpdateManager_CHECK -eq $false)
{
    Write-Host 'Downloading Adobe Remote Update Manager'
    $UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.67 Safari/537.36'
    Invoke-WebRequest -UseBasicParsing 'https://onedrive.live.com/download?cid=AF928892EBCFB343&resid=AF928892EBCFB343%21198740&authkey=APGjFRM5LgIBCHg' `
        -OutFile 'C:\Utils\AdobeRemoteUpdateManager.zip' `
        -UserAgent $UserAgent

    New-Item C:\Utils -Name AdobeRUM -ItemType Directory -Force -ErrorAction SilentlyContinue
    Expand-Archive -Path 'C:\Utils\AdobeRemoteUpdateManager.zip' -DestinationPath C:\Utils\AdobeRUM
    Get-ChildItem -Path C:\Utils\AdobeRUM -Recurse | Unblock-File

    Start-Process -FilePath 'C:\Utils\AdobeRUM\RemoteUpdateManager.exe' -NoNewWindow -Wait

}
else
{
    Write-Host 'Adobe Remote Update Manager Found - Checking for updates'
    Start-Process -FilePath 'C:\Utils\AdobeRUM\RemoteUpdateManager.exe' -NoNewWindow -Wait
}

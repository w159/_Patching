
<#
.DESCRIPTION
This compares the current version of Adobe Reader to the latest from Adobe's CDN

If the latest version isn't installed, then the latest version is downloaded and silently installed

If Adobe isn't found in registry or WMI, then no action is taken

Currently working as of 5-3-23 - JM

#>

# Setting download setting variables
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

# Determining the current version of Reader installed
$CurrentReaderVersion = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where-Object { $_.DisplayName -like '*Adobe*' -and $_.DisplayName -like '*Reader*' } -ErrorAction SilentlyContinue
$CurrentReaderVersionWMI = (Get-CimInstance win32_product | Where-Object Name -Like '*Adobe Acrobat*' | Select-Object -ExpandProperty Version -ErrorAction SilentlyContinue).replace('.', '')

# Determining the latest version of Reader from Adobe download site
$Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$Session.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.67 Safari/537.36'
$Result = Invoke-RestMethod -Uri 'https://rdc.adobe.io/reader/products?lang=mui&site=enterprise&os=Windows%2011&country=US&nativeOs=Windows%2010&api_key=dc-get-adobereader-cdn' `
    -WebSession $Session `
    -Headers @{
    'Accept'             = '*/*'
    'Accept-Encoding'    = 'gzip, deflate, br'
    'Accept-Language'    = 'en-US,en;q=0.9'
    'Origin'             = 'https://get.adobe.com'
    'Referer'            = 'https://get.adobe.com/'
    'Sec-Fetch-Dest'     = 'empty'
    'Sec-Fetch-Mode'     = 'cors'
    'Sec-Fetch-Site'     = 'cross-site'
    'sec-ch-ua'          = "`" Not A;Brand`";v=`"99`", `"Chromium`";v=`"101`", `"Google Chrome`";v=`"101`""
    'sec-ch-ua-mobile'   = '?0'
    'sec-ch-ua-platform' = "`"Windows`""
    'x-api-key'          = 'dc-get-adobereader-cdn'
}

$Version = $result.products.reader[0].version
$LatestVersion = $Version.replace('.', '')

If ( -not (($null -eq $CurrentReaderVersion) -or ($null -eq $CurrentReaderVersionWMI) ) )
{
    Write-Host 'Adobe Reader not found to be installed, taking no action'
}

else
{
    If ( -not (($LatestVersion -ne $CurrentReaderVersion) -or ($LatestVersion -ne $CurrentReaderVersionWMI) ) )
    {
        Write-Host "Current Adobe Reader version isn't the latest, updating!"
        $URI = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/$LatestVersion/AcroRdrDCx64$($LatestVersion)_MUI.exe"
        $OutFile = Join-Path $env:TEMP "AcroRdrDCx64$($version)_MUI.exe"
        Write-Host "Downloading version $version from $URI to $OutFile"
        (New-Object System.Net.WebClient).DownloadFile($URI, $OutFile)

        Write-Host "Install version $version from $URI to $OutFile"
        Start-Process -FilePath $OutFile -ArgumentList '/sAll /rs /rps /msi /norestart /quiet EULA_ACCEPT=YES' -WorkingDirectory $env:TEMP -Wait -LoadUserProfile

        Write-Host "Cleaning up installer $version from $OutFile"
        Remove-Item $OutFile
    }

    else
    {
        Write-Host 'Current Adobe Reader version is LATEST, taking no action!'
    }
}


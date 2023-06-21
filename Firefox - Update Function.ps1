<#
.DESCRIPTION
This function updates whatever version of Mozilla Firefox that is currently installed
If both the 32 and 64 bit versions are installed, then both will be updated

There's no parameters required or available

.EXAMPLE
Update-Firefox

Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/w159/Firefox-Update-to-Latest/main/Firefox%20-%20Update%20to%20Latest.ps1'))
Update-Firefox

#>

function Update-Firefox {

    $ProgressPreference = 'SilentlyContinue'

    $webResponse = (Invoke-WebRequest -UseBasicParsing 'https://product-details.mozilla.org/1.0/firefox_versions.json').Content
    $GetLatest = $webResponse | ConvertFrom-Json 
    $FirefoxLatestVersion = $GetLatest | Select-Object -ExpandProperty "LATEST_FIREFOX_VERSION"

    $FirefoxX86EXE = "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
    $FireFoxx86Test = Test-Path $FirefoxX86EXE

    $FirefoxX64EXE = "C:\Program Files\Mozilla Firefox\firefox.exe"
    $FirefoxX64Test = Test-Path $FirefoxX64EXE
    


    if ($FireFoxx86Test -eq $true) {
    $FirefoxInstalledVersionX86 = (Get-Item $FirefoxX86EXE).VersionInfo | Select-Object -ExpandProperty ProductVersion

        if ($FirefoxInstalledVersionX86 -NE $FirefoxLatestVersion) {

            Write-Host "UPDATING FIREFOX"
            New-Item -Path "C:\" -Name "Utils" -ItemType Directory -Force
            Invoke-WebRequest -UseBasicParsing 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win&lang=en-US' -OutFile "C:\Utils\FirefoxX32LatestSetup.exe"
            Start-Process "C:\Utils\FirefoxX32LatestSetup.exe" -ArgumentList "/S /DesktopShortcut=false /TaskbarShortcut=false /StartMenuShortcut=false" -Wait

        }
    }

    if ($FirefoxX64Test -eq $true) {
    $FirefoxInstalledVersionX64 = (Get-Item $FirefoxX64EXE).VersionInfo | Select-Object -ExpandProperty ProductVersion

        if ($FirefoxInstalledVersionX64 -NE $FirefoxLatestVersion) {

            Write-Host "UPDATING FIREFOX"
            New-Item -Path "C:\" -Name "Utils" -ItemType Directory -Force
            Invoke-WebRequest -UseBasicParsing 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US' -OutFile "C:\Utils\FirefoxX64LatestSetup.exe"
            Start-Process "C:\Utils\FirefoxX64LatestSetup.exe" -ArgumentList "/S /DesktopShortcut=false /TaskbarShortcut=false /StartMenuShortcut=false" -Wait

        }
    }

    }

Update-Firefox




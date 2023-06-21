<#
.DESCRIPTION
This downloads and installs the DisplayLink drivers for docking stations

The drivers are only installed if the chassis is determined to likely be a laptop

Current Dock Models supported in this script:
WavLink WL-UG69PD2 (Specific Model Installer)
StartTech DK30A2DH (Potentially all similar models as well)

#>

# Completes setup requirements needed for script
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/w159/Get-Laptop/main/Get-Laptop.ps1'))

# Variables for driver downloads and working directory
$StarTechDocks = 'https://sgcdn.startech.com/005329/media/sets/displaylink_windows_drivers/[DisplayLink]%20Windows%20USB%20Display%20Adapter.zip'
$WavLink_WL_UG69PD2 = 'https://files2.wavlink.com/drivers/PC-peripherals/DL-displaylink/win-2022929.zip'

$TempDirectory = 'C:\Utils\DisplayLinkDriverSetup'
New-Item $TempDirectory -ItemType Directory -Force

# Begin script operations
Invoke-WebRequest -Uri $StarTechDocks -OutFile $TempDirectory\StarTechDocks.zip
Invoke-WebRequest -Uri $WavLink_WL_UG69PD2 -OutFile $TempDirectory\WavLink_WL_UG69PD2.zip -





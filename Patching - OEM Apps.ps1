

##########################################################
# Download, Configure, and Install PowerShell WinGET build
##########################################################

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Script -Name winget-install -Force
winget-install
$WingetLocation = Get-ChildItem -Recurse -Path "$Env:Programfiles\WindowsApps\Microsoft.DesktopAppInstaller*" | Where-Object Name -Like 'winget.exe'
$WingetCLI = $WingetLocation.FullName
Set-Alias -Name winget -Value $WingetCLI

##########################################################
# Usage Examples
##########################################################

# Export/Import current apps
# Export is used on reference PC
# Import is intended to be used on new PC, or for standardization
winget export --output C:\Utils\BaseBenchApps.json --accept-source-agreements
winget import --output C:\Utils\BaseBenchApps.json --accept-source-agreements

# Upgrade all currently installed packages found in repository
winget upgrade --all --silent

$ComputerSystemProductVendor = Get-WmiObject -Class Win32_ComputerSystemProduct | Select-Object Vendor
$ComputerSystemManufacturer = Get-WmiObject -Class Win32_ComputerSystem | Select-Object Manufacturer
$APPS = Get-WmiObject win32_product

if (($ComputerSystemProductVendor.Vendor -like '*LENOVO*') -or ($ComputerSystemManufacturer.Manufacturer -like '*LENOVO*'))
{

    $HPSupportAssistant_CHECK = $APPS | Where-Object Name -Like 'HP Support Assistant'
    $HPSupportSolutions_CHECK = $APPS | Where-Object Name -Like 'HP Support Solutions Framework'
    $HPSupportAssistant_CHECK.Uninstall()
    $HPSupportSolutions_CHECK.Uninstall()

    winget upgrade --id Lenovo.SystemUpdate
}

if (($ComputerSystemProductVendor.Vendor -like '*DELL*') -or ($ComputerSystemManufacturer.Manufacturer -like '*DELL*'))
{

    $HPSupportAssistant_CHECK = $APPS | Where-Object Name -Like 'HP Support Assistant'
    $HPSupportSolutions_CHECK = $APPS | Where-Object Name -Like 'HP Support Solutions Framework'
    $HPSupportAssistant_CHECK.Uninstall()
    $HPSupportSolutions_CHECK.Uninstall()

    winget upgrade --id Dell.CommandUpdate
}

if (($ComputerSystemProductVendor.Vendor -like '*HP*') -or ($ComputerSystemManufacturer.Manufacturer -like '*HP*') -or ($ComputerSystemManufacturer.Manufacturer -like '*Hewlett-Packard*') -or ($ComputerSystemProductVendor.Vendor -like '*Hewlett-Packard*'))
{

    $HPSupportAssistant_CHECK = $APPS | Where-Object Name -Like 'HP Support Assistant'
    $HPSupportAssistant_VERSION = ($HPSupportAssistant_CHECK).Version
    $HPSupportSolutions_CHECK = $APPS | Where-Object Name -Like 'HP Support Solutions Framework'
    $HPSupportSolutions_VERSION = ($HPSupportSolutions_CHECK).Version
    $HPSupportAssistant_VERSION
    $HPSupportSolutions_VERSION

    Invoke-WebRequest -UseBasicParsing 'https://ftp.hp.com/pub/softpaq/sp146001-146500/sp146042.exe' -OutFile 'C:\utils\HPSupportAssistant.exe'
    Start-Process 'C:\utils\HPSupportAssistant.exe' -ArgumentList '/s /e /f "C:\Utils\HPSupportAssistant"' -WindowStyle Hidden -Wait
    Start-Process 'C:\utils\HPSupportAssistant\msiinstaller.exe' -ArgumentList '/S /v/qn' -WindowStyle Hidden -Wait
}
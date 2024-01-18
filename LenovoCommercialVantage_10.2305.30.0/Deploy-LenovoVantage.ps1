Set-Location $PSScriptRoot

# Unblock all files
Get-ChildItem -Path .\ -Recurse | Unblock-File

# Uninstall any previous version of Vantage/Companion/Settings
& .\uninstall_vantage_v8\uninstall_apps.ps1

# Deploy the policy configuration (optional - see deployment guide)
# regedit /s sample-policy-config.reg
# regedit /s VantageDisableAutomaticSystemUpdates.reg

# Install the application - Commercial Vantage
& .\lenovo-commercial-vantage-install.ps1

# Skip the installation/configuration of LSIF on ARM machines
if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
     goto InstallVantageService
}

# Configure LSIF so that only Commercial Vantage plugins are installed (required)
# regedit /s SifRequireAppAssociation.reg

# Disable LSIF self-updates (optional - see deployment guide)
# regedit /s SifDisableSelfUpdate.reg

# Install/Update LSIF
& System-Interface-Foundation-Update-64.exe /verysilent /NORESTART

# Update LSIF plugins
Stop-Service -Name imcontrollerservice
Remove-Item $env:ProgramData\lenovo\imcontroller\ImControllerSubscription.xml
Remove-Item $env:ProgramData\lenovo\imcontroller\temp\ImControllerSubscription.xml
& $env:windir\lenovo\imcontroller\service\lenovo.modern.imcontroller.exe /installsubscription .\plugins\ImControllerSubscription-1.1.xml
mkdir $env:ProgramData\lenovo\imcontroller\temp
Copy-Item -Force $env:ProgramData\lenovo\imcontroller\ImControllerSubscription.xml $env:ProgramData\lenovo\imcontroller\temp\ImControllerSubscription.xml
Set-ItemProperty -Path $env:ProgramData\lenovo\imcontroller\ImControllerSubscription.xml -Name Attributes -Value 'ReadOnly'
Set-ItemProperty -Path $env:ProgramData\lenovo\imcontroller\temp\ImControllerSubscription.xml -Name Attributes -Value 'ReadOnly'
& $env:windir\lenovo\imcontroller\service\lenovo.modern.imcontroller.exe /installpackageswithreboot .\plugins
Start-Service -Name imcontrollerservice
Set-ItemProperty -Path $env:ProgramData\lenovo\imcontroller\temp\ImControllerSubscription.xml -Name Attributes -Value 'Normal'
Set-ItemProperty -Path $env:ProgramData\lenovo\imcontroller\ImControllerSubscription.xml -Name Attributes -Value 'Normal'

:InstallVantageService
# Install Vantage Service
& .\VantageService\Install-VantageService.ps1

# Install Vantage Service Addins
Stop-Service -Name LenovoVantageService
# Wait for 3 seconds
Start-Sleep -Seconds 3
# Ensure addins not running
Get-Process -Name LenovoVantage* | Stop-Process -Force
if (Test-Path .\LVSAddins) {
     Copy-Item -Path .\LVSAddins\* -Destination $env:PROGRAMDATA\Lenovo\Vantage\ -Recurse -Force
}

# Post copy deployment (update addin lists)
& .\VantageService\Update-AddinComponents.ps1

Start-Service -Name LenovoVantageService

Set-Location -Path $PSScriptRoot

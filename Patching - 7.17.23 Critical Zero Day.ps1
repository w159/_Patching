<#
.SYNOPSIS
Successful execution of this script will patch the following critical zero-day CVEs:

CVE-2023-36884
CVE-2023-33149
CVE-2023-33152
CVE-2023-33153
CVE-2023-33148
CVE-2023-33158
CVE-2023-33162
CVE-2023-33161
CVE-2023-35311
CVE-2023-33150
CVE-2023-33151

.NOTES
Reference the CVE article for more information, as well as any vulnerabilities that may be added to the list.
This script is provided as is with no warranty or guarantee of functionality.

.DESCRIPTION
This script checks for the Zero Day CVE-2023-36884 - Office and Windows HTML Remote Code Execution Vulnerability

.EXAMPLE
Import and/or run this script as is, or use it as a reference to create your own script.

IRM -UseBasicParsing 'https://raw.githubusercontent.com/w159/_Patching/main/Patching%20-%207.17.23%20Critical%20Zero%20Day.ps1' | IEX

#>


# Create a folder to store the script and any required files
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

if (!(Test-Path -Path 'C:\Utils'))
{
     New-Item -Path 'C:\Utils' -ItemType Directory
}
else
{
     Remove-Item -Path 'C:\Utils\*' -Recurse -Force
}

# Check for registry key - Block cross protocol file navigation
$RegistryKey = 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BLOCK_CROSS_PROTOCOL_FILE_NAVIGATION'
$Registry_CHECK = Test-Path -Path $RegistryKey
$Processes = @('Excel.exe', 'Graph.exe', 'MSAccess.exe', 'MSPub.exe', 'Powerpnt.exe', 'Visio.exe', 'WinProj.exe', 'Wordpad.exe')
If ($Registry_CHECK -eq $false)
{
     Write-Host 'Vulnerable - Creating registry key' -ForegroundColor Yellow
     New-Item -Path $RegistryKey -Force
     foreach ($Process in $Processes)
     {
          Write-Host "Adding $Process to registry key" -ForegroundColor Yellow
          New-ItemProperty -Path $RegistryKey -Name $Process -Value 1 -PropertyType DWORD -Force
     }
}
else
{
     Write-Host 'Mitigated - Registry key exists' -ForegroundColor Green
}

# Check for vulnerable Office versions
$Office_CHECK = (Get-CimInstance win32_product | Where-Object { $_.Name -like '*Office*' } | Where-Object Version -Like '16.0.*').Version
$OfficeUpdateClient = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Updates' -Name 'UpdateClientPath').UpdateClientPath
$UpdateCommand = '/update user displaylevel=false updatepromptuser=false forceappshutdown=true'
If ($Office_CHECK -notlike '*16529.20182')
{
     # Check for and install the latest Office update
     Write-Host 'Vulnerable - Installing the latest Office update' -ForegroundColor Yellow
     Start-Process -FilePath $OfficeUpdateClient -ArgumentList $UpdateCommand -Wait
}
else
{
     Write-Host 'Mitigated - Office is up to date' -ForegroundColor Green
}


$WindowsVersion = (Get-ComputerInfo | Select-Object -expand OsName)

If ($WindowsVersion -Like '*10*')
{
     $InstalledUpdates = Get-HotFix
     $KB5027215 = $InstalledUpdates | Where-Object { $_.HotFixID -eq 'KB5027215' } -ErrorAction SilentlyContinue
     $KB5026361 = $InstalledUpdates | Where-Object { $_.HotFixID -eq 'KB5026361' } -ErrorAction SilentlyContinue
     $KB5028166 = $InstalledUpdates | Where-Object { $_.HotFixID -eq 'KB5028166' } -ErrorAction SilentlyContinue

     if ($KB5027215)
     {
          # Check for 2023-06 Dynamic Cumulative Update for Windows 10 Version 22H2 for x64-based Systems (KB5027215) and install it if it is not present
          Start-Process WUSA -ArgumentList '/Uninstall /KB:5027215 /Quiet /NoRestart' -Wait
          Write-Host 'Installing Windows 10 KB5027215' -ForegroundColor Yellow
          Invoke-WebRequest -UseBasicParsing 'https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/secu/2023/06/windows10.0-kb5027215-x64_dae89e7b1f9881fa888ff85e27c9083a572c62aa.cab' -OutFile 'C:\Utils\Windows10.0-KB5027215-x64.cab'
          New-Item 'C:\Utils\Windows10.0-KB5027215-x64' -ItemType Directory -Force
          expand 'C:\Utils\Windows10.0-KB5027215-x64.cab' /f:'Windows10.0-KB5027215-x64.cab' 'C:\Utils\Windows10.0-KB5027215-x64'
          DISM /Online /Add-Package /PackagePath:'C:\Utils\Windows10.0-KB5027215-x64\Windows10.0-KB5027215-x64.cab' /NoRestart
     }
     else
     {
          Write-Host 'KB5027215 is already installed' -ForegroundColor Green
     }

     if ($KB5026361)
     {
          # Check for 2023-06 Cumulative Update Preview for Windows 10 Version 22H2 for x64-based Systems (KB5026361)
          Start-Process WUSA -ArgumentList '/Uninstall /KB:5026361 /Quiet /NoRestart' -Wait
          Write-Host 'Installing Windows 10 KB5026361' -ForegroundColor Yellow
          Invoke-WebRequest -UseBasicParsing 'https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/secu/2023/05/windows10.0-kb5026361-x64_961f439d6b20735f067af766e1813936bf76cb94.msu' -OutFile 'C:\Utils\Windows10.0-KB5026361-x64.msu'
          New-Item 'C:\Utils\Windows10.0-KB5026361-x64' -ItemType Directory -Force
          expand 'C:\Utils\Windows10.0-KB5026361-x64.msu' /f:'Windows10.0-KB5026361-x64.cab' 'C:\Utils\Windows10.0-KB5026361-x64'
          DISM /Online /Add-Package /PackagePath:'C:\Utils\Windows10.0-KB5026361-x64\Windows10.0-KB5026361-x64.cab' /NoRestart
     }
     else
     {
          Write-Host 'KB5026361 is already installed' -ForegroundColor Green
     }

     if ($KB5028166)
     {
          # Check for 2023-06 Cumulative Update Preview for Windows 10 Version 22H2 for x64-based Systems (KB5028166)
          Start-Process WUSA -ArgumentList '/Uninstall /KB:5028166 /Quiet /NoRestart' -Wait
          Write-Host 'Installing Windows 10 KB5028166' -ForegroundColor Yellow
          Invoke-WebRequest -UseBasicParsing 'https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/secu/2023/07/windows10.0-kb5028166-x64_fe3aa2fef685c0e76e1f5d34d529624294273f41.msu' -OutFile 'C:\Utils\Windows10.0-KB5028166-x64.msu'
          New-Item 'C:\Utils\Windows10.0-KB5028166-x64' -ItemType Directory -Force
          expand 'C:\Utils\Windows10.0-KB5028166-x64.msu' /f:'Windows10.0-KB5028166-x64.cab' 'C:\Utils\Windows10.0-KB5028166-x64'
          DISM /Online /Add-Package /PackagePath:'C:\Utils\Windows10.0-KB5028166-x64\Windows10.0-KB5028166-x64.cab' /NoRestart

     }
     else
     {
          Write-Host 'KB5028166 is already installed' -ForegroundColor Green
     }
}

# Download and Install Windows Update Module
Invoke-WebRequest -UseBasicParsing 'https://github.com/w159/PSWindowsUpdate/archive/refs/heads/main.zip' -OutFile 'C:\Utils\PSWindowsUpdate.zip'
Expand-Archive -Path 'C:\Utils\PSWindowsUpdate.zip' -DestinationPath 'C:\Utils\PSWindowsUpdate' -Force
Import-Module -Name 'C:\Utils\PSWindowsUpdate\PSWindowsUpdate-main\PSWindowsUpdate\PSWindowsUpdate.psd1'
Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot

# Install WinGET and update all apps
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -Force
Install-Module -Name PSWindowsUpdate -Force
$ProgressPreference = 'SilentlyContinue'
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Script -Name winget-install -Force
winget-install
$WingetLocation = Get-ChildItem -Recurse -Path "C:\$Env:Programfiles\WindowsApps\Microsoft.DesktopAppInstaller*" | Where-Object Name -Like 'winget.exe' | Sort-Object LastWriteTime -Descending | Select-Object -Last 1
$WingetCLI = $WingetLocation.FullName
Set-Alias -Name winget -Value $WingetCLI
winget settings --enable InstallerHashOverride
winget upgrade --all --silent --ignore-security-hash
$namespaceName = 'root\cimv2\mdm\dmmap'
$className = 'MDM_EnterpriseModernAppManagement_AppManagement01'
$wmiObj = Get-WmiObject -Namespace $namespaceName -Class $className
$result = $wmiObj.UpdateScanMethod()
$result


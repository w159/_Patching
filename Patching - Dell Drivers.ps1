

$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$userAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome

New-Item -Path 'C:\' -Name 'Utils' -ItemType Directory -Force -ErrorAction SilentlyContinue

$BIOSCheck = Get-ItemPropertyValue -Path 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' -Name 'BIOSVendor'

if ($BIOSCheck -like '*Dell*') {
    
    Write-Host "Dell BIOS check equals true"
    $DCU_x86 = Test-Path "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
    $DCU_x64 = Test-Path "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"

    if ( -not (($DCU_x86 -eq $false) -xor ($DCU_x64 -eq $false) ) ) {

    Write-Host "Installing Dell Command"
    Invoke-WebRequest -UseBasicParsing 'https://dl.dell.com/FOLDER09622916M/1/Dell-Command-Update-Application_714J9_WIN_4.8.0_A00.EXE' -UserAgent $userAgent -OutFile 'C:\utils\Dell-Command.EXE'
    Remove-Item "C:\Utils\dcu_exe" -Recurse -Force -ErrorAction SilentlyContinue
    Unblock-File "C:\utils\Dell-Command.EXE" -Confirm:$false
    Start-Process "C:\utils\Dell-Command.EXE" -ArgumentList "/s /e=C:\utils\dcu_exe" -WindowStyle Hidden -Wait
    $DellCommandSetupEXE = (Get-ChildItem -Path 'C:\utils\dcu_exe' -Recurse | Where-Object Name -Like DCU_Setup*).VersionInfo.FileName
    Start-Process -FilePath $DellCommandSetupEXE -ArgumentList "/S /v/qn" -WindowStyle Hidden -Wait
    Start-Service -Name "DellClientManagementService"
    $DCU_x86 = Test-Path "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
    $DCU_x64 = Test-Path "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"

    }

    else {
    Write-Host "Dell Command already installed, scanning for updates"
    If ($DCU_x86 -eq $true) {
    Write-Host "Dell Command x86 found"
        Start-Process "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/configure -userConsent=disable -updatesNotification=disable -autoSuspendBitLocker=enable -updateSeverity=security,critical,recommended -updateType=bios,firmware,driver -lockSettings=enable" -WindowStyle Hidden -Wait
        Start-Process "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/applyUpdates -silent -forceUpdate=enable -reboot=disable" -WindowStyle Hidden -Wait
    }

    If ($DCU_x64 -eq $true) {
    Write-Host "Dell Command x64 found"
        Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/configure -userConsent=disable -updatesNotification=disable -autoSuspendBitLocker=enable -updateSeverity=security,critical,recommended -updateType=bios,firmware,driver -lockSettings=enable" -WindowStyle Hidden -Wait
        Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/applyUpdates -silent -forceUpdate=enable -reboot=disable" -WindowStyle Hidden -Wait
    }
}
}

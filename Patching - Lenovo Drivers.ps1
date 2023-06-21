$BIOSCheck = Get-ItemPropertyValue -Path 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS' -Name 'BIOSVendor'

if ($BIOSCheck -like '*LENOVO*') {

    $LenovoSystemUpdateCheck = Test-Path "C:\Program Files (x86)\Lenovo\System Update\tvsu.exe"

    If ($LenovoSystemUpdateCheck -eq $false) { 

$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Remove-Item -Path 'C:\utils\LenovoSystemUpdate.exe' -Force
Invoke-WebRequest -UseBasicParsing 'https://download.lenovo.com/pccbbs/thinkvantage_en/system_update_5.08.01.exe' -OutFile 'C:\utils\LenovoSystemUpdate.exe'
Start-Process "C:\utils\LenovoSystemUpdate.exe" -ArgumentList "/VERYSILENT /NORESTART" -Wait
    }

##### Set SU AdminCommandLine
$RegKey = "HKLM:\SOFTWARE\Policies\Lenovo\System Update\UserSettings\General"
$RegName = "AdminCommandLine"
$RegValue = "/CM -search R -action INSTALL -IncludeRebootPackages 1,3,4 -noicon -exporttowmi"

# Create Subkeys if they don't exist
if (!(Test-Path $RegKey)) {
    New-Item -Path $RegKey -Force | Out-Null
    New-ItemProperty -Path $RegKey -Name $RegName -Value $RegValue -Force -ErrorAction SilentlyContinue
}
else {
    New-ItemProperty -Path $RegKey -Name $RegName -Value $RegValue -Force -ErrorAction SilentlyContinue
}

##### Configure SU interface
$ui = "HKLM:\SOFTWARE\WOW6432Node\Lenovo\System Update\Preferences\UserSettings\General"
$values = @{
    "AskBeforeClosing"     = "NO"
    "DisplayLicenseNotice" = "NO"
    "MetricsEnabled"       = "NO"
    "DebugEnable"          = "YES"
}

if (Test-Path $ui) {
    foreach ($item in $values.GetEnumerator() ) {
        New-ItemProperty -Path $ui -Name $item.Key -Value $item.Value -Force -ErrorAction SilentlyContinue
    }
}

<# 
Run SU and wait until the Tvsukernel process finishes.
Once the Tvsukernel ends, Autopilot flow will continue.
#>
Start-Process -FilePath 'C:\Program Files (x86)\Lenovo\System Update\tvsu.exe' -ArgumentList '/CM'

# Disable the default System Update scheduled tasks
Install-Module -Name LSUClient -Force -ErrorAction SilentlyContinue
Get-ScheduledTask -TaskPath "\TVT\" | Disable-ScheduledTask

$LenovoUpdaterScript = @"
Install-Module -Name LSUClient -Force
Suspend-BitLocker -MountPoint "C:" -RebootCount 1

Remove-Item -Path C:\Windows\Temp\LSUPackages -Recurse -Force -ErrorAction SilentlyContinue
`$updates = Get-LSUpdate | Where-Object { `$_.Installer.Unattended }
`$i = 1
foreach (`$update in `$updates) {
    Write-Host "Installing update `$i of `$(`$updates.Count): `$(`$update.Title)"
    Install-LSUpdate -Package `$update -Verbose
    `$i++
}

[array]`$results = Install-LSUpdate -Package `$updates

if (`$results.PendingAction -contains 'REBOOT_MANDATORY') {
    # reboot immediately or set a marker for yourself to perform the reboot shortly
    Restart-Computer -Confirm:`$false -Force
}
if (`$results.PendingAction -contains 'SHUTDOWN') {
    # shutdown immediately or set a marker for yourself to perform the shutdown shortly
    Restart-Computer -Confirm:`$false -Force
}
"@


New-Item -Path "C:\Windows" -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "C:\Windows\Utils" -Name LenovoUpdater.ps1 -ItemType File -Value $LenovoUpdaterScript -Force -ErrorAction SilentlyContinue

##### Disable Scheduler Ability.  
# This will prevent System Update from creating the default scheduled tasks when updating to future releases.
$sa = "HKLM:\SOFTWARE\WOW6432Node\Lenovo\System Update\Preferences\UserSettings\Scheduler"
Set-ItemProperty -Path $sa -Name "SchedulerAbility" -Value "NO" -Force -ErrorAction SilentlyContinue

##### Create a custom scheduled task for System Update
Get-ScheduledTask | Where-Object TaskName -EQ "Run-TVSU" | Unregister-ScheduledTask -Confirm:$false
Get-ScheduledTask | Where-Object TaskName -EQ "S5 - Run-TVSU" | Unregister-ScheduledTask -Confirm:$false

$Hours = 1, 2, 3, 4, 5, 5, 21, 22, 23 | Get-Random -Count 1
$Minutes = Get-Random -Minimum 00 -Maximum 59
$Time = Get-Date -Hour $Hours -Minute $Minutes -UFormat %r

$Trigger = (New-ScheduledTaskTrigger -Daily -At $Time)
$User = "NT AUTHORITY\SYSTEM"
$Action =   (New-ScheduledTaskAction -Execute "C:\Program Files (x86)\Lenovo\System Update\Tvsu.exe" -Argument '/CM'),
            (New-ScheduledTaskAction -Execute "POWERSHELL" -Argument '-ExecutionPolicy Bypass -File "C:\Windows\Utils\LenovoUpdater.ps1"')

$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "S5 - Lenovo Updater" -Trigger $Trigger -User $User -Action $Action -Settings $Settings `
                       -RunLevel Highest `
                       -Description 'This installs Lenovo System Update and updates Drivers and BIOS to latest. Created by S5 JM - Last Updated 4-19-23' -Force
}
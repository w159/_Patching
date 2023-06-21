

New-Item -Path "C:\Windows" -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue

$OfficeUpdatesScript = @"
`$OfficeX64Path = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
`$OfficeX32Path = "C:\Program Files (x86)\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
`$UpdateCommand = "/update user displaylevel=false forceappshutdown=true Updatepromptuser=false"
`$OfficeX64Test = Test-Path `$OfficeX64Path
`$OfficeX32Test = Test-Path `$OfficeX32Path

If (`$OfficeX32Test -eq  `$true){
    Start-Process `$OfficeX32Path -ArgumentList `$UpdateCommand -Wait -WindowStyle Hidden
}

If (`$OfficeX64Test -eq `$true){
    Start-Process `$OfficeX64Path -ArgumentList `$UpdateCommand -Wait -WindowStyle Hidden
}

`$namespaceName = "root\cimv2\mdm\dmmap"
`$className = "MDM_EnterpriseModernAppManagement_AppManagement01"
`$wmiObj = Get-WmiObject -Namespace `$namespaceName -Class `$className
`$result = `$wmiObj.UpdateScanMethod()
`$result
"@

New-Item -Path "C:\Windows\Utils" -Name OfficeUpdates.ps1 -ItemType File -Value $OfficeUpdatesScript -Force

$Hours = 1, 2, 3, 4, 5, 6, 21, 22, 23 | Get-Random -Count 1
$Minutes = Get-Random -Minimum 00 -Maximum 59
$Time = Get-Date -Hour $Hours -Minute $Minutes -UFormat %r
$Trigger = (New-ScheduledTaskTrigger -Daily -At $Time)
$User = "NT AUTHORITY\SYSTEM"
$Action = (New-ScheduledTaskAction -Execute "POWERSHELL" -Argument '-ExecutionPolicy Bypass -File "C:\Windows\Utils\OfficeUpdates.ps1"')
$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName "S5 - Office Updater" -Trigger $Trigger -User $User -Action $Action -Settings $Settings -RunLevel Highest -Force -Description "This task should update x32 and x64 versions of Microsoft Office apps. Created by JM Last updated 5-9-23"


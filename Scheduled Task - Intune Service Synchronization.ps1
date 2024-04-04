Get-ScheduledTask | Where-Object TaskName -EQ 'S5 - Intune *' | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
Get-ScheduledTask | Where-Object TaskName -EQ 'Intune Hourly Sync' | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
Get-ScheduledTask | Where-Object TaskName -EQ 'Intune App Sync' | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
Get-ScheduledTask | Where-Object TaskName -EQ 'Intune Compliance Sync' | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue


$Trigger = (New-ScheduledTaskTrigger -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 60) -Once)
$15MinuteTrigger = (New-ScheduledTaskTrigger -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -Once)

$SyncComplianceAction = (New-ScheduledTaskAction -Execute 'POWERSHELL' -Argument 'Start-Process -FilePath "C:\Program Files (x86)\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe" -ArgumentList "intunemanagementextension://synccompliance"')
$SyncIMEAction = (New-ScheduledTaskAction -Execute 'POWERSHELL' -Argument 'Start-Process -FilePath "C:\Program Files (x86)\Microsoft Intune Management Extension\Microsoft.Management.Services.IntuneWindowsAgent.exe" -ArgumentList "intunemanagementextension://syncapp"'),
     (New-ScheduledTaskAction -Execute 'POWERSHELL' -Argument 'Get-Service -DisplayName "Microsoft Intune Management Extension" | Stop-Service '),
     (New-ScheduledTaskAction -Execute 'POWERSHELL' -Argument 'Get-Service -DisplayName "Microsoft Intune Management Extension" | Start-Service ')

$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartOnIdle

$User = 'NT AUTHORITY\SYSTEM'

$TaskName_AppSync = 'Intune App Sync v4.4.24'
$Description_AppSync = 'This executes an IME action to initiate a sync for Intune data. Created by JM - Last updated 4.4.24'

$TaskName_CompSync = 'Intune Compliance Sync v4.4.24'
$Description_CompSync = 'This executes IME action initiate a sync for Intune compliance. Created by JM - Last updated 4.4.24'

Register-ScheduledTask -TaskName $TaskName_AppSync -Trigger $Trigger -Action $SyncIMEAction -User $User -Settings $Settings -RunLevel Highest -Force -Description $Description_AppSync
Register-ScheduledTask -TaskName $TaskName_CompSync -Trigger $15MinuteTrigger -Action $SyncComplianceAction -User $User -Settings $Settings -RunLevel Highest -Force -Description $Description_CompSync
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

New-Item -Path C:\ -Name Utils -ItemType Directory -Force
Invoke-WebRequest -UseBasicParsing 'https://download.lenovo.com/pccbbs/thinkvantage_en/metroapps/Vantage/LenovoCommercialVantage_10.2310.28.0.zip' -OutFile 'C:\Utils\LenovoVantage.zip'
Expand-Archive -Path 'C:\Utils\LenovoVantage.zip' -DestinationPath 'C:\Utils\LenovoVantage'
$VantageSetup = (Get-ChildItem -Path C:\Utils -Recurse | Where-Object Name -Like setup-commercial-vantage.bat).FullName
Start-Process -FilePath $VantageSetup

$registryPath = 'HKLM:\SOFTWARE\Policies\Lenovo\Commercial Vantage'
$registryKeys = @{
     'page.dashboard'                                                         = '1'
     'SystemUpdateFilter'                                                     = '1'
     'SystemUpdateFilter.critical.application'                                = '1'
     'SystemUpdateFilter.critical.driver'                                     = '1'
     'SystemUpdateFilter.critical.BIOS'                                       = '1'
     'SystemUpdateFilter.critical.firmware'                                   = '1'
     'SystemUpdateFilter.critical.others'                                     = '1'
     'SystemUpdateFilter.recommended.driver'                                  = '1'
     'SystemUpdateFilter.recommended.BIOS'                                    = '1'
     'SystemUpdateFilter.recommended.firmware'                                = '1'
     'AutoUpdateEnabled'                                                      = '1'
     'DeferUpdateEnabled'                                                     = '1'
     'DeferUpdateEnabled.Limit'                                               = '10'
     'DeferUpdateEnabled.Time'                                                = '240'
     'AutoUpdateDock'                                                         = '1'
     'AutoUpdateDailySchedule'                                                = '1'
     'AutoUpdateDailySchedule.days'                                           = ''
     'AutoUpdateDailySchedule.frequency.AllWeeks'                             = '1'
     'AutoUpdateDailySchedule.dayOfWeek.Saturday'                             = '1'
     'AutoUpdateScheduleTime'                                                 = '22:30:00'
     'feature.device-settings.power.wmi-battery'                              = '1'
     'feature.device-settings.power.wmi-battery.scheduletype'                 = '1'
     'feature.device-settings.power.wmi-battery.scheduleday'                  = '1'
     'feature.device-settings.power.wmi-battery.scheduletime'                 = '10:00:00'
     'feature.device-settings.smart-assist.active-protection-system-settings' = '1'
     'feature.device-settings.smart-assist.intelligent-screen'                = '1'
     'feature.device-settings.smart-assist.intelligent-security-settings'     = '1'
     'AcceptEULAAutomatically'                                                = '1'
     'TurnOffToastMessage'                                                    = '1'
     'page.wifiSecurity'                                                      = '1'
     'wmi.warranty'                                                           = '1'
     'feature.warranty'                                                       = '0'
     'feature.giveFeedback'                                                   = '1'
}

if (!(Test-Path $registryPath))
{
     New-Item -Path $registryPath -Force | Out-Null
}

foreach ($key in $registryKeys.Keys)
{
     if ($null -eq (Get-ItemProperty -Path $registryPath -Name $key -ErrorAction SilentlyContinue))
     {
          Set-ItemProperty -Path $registryPath -Name $key -Value $registryKeys[$key]
     }
}

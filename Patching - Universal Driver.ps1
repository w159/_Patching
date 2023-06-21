$logpath = "$($env:ProgramData)\IntuneScripts\$($myinvocation.mycommand.name).log"

if(!(Get-Item $logpath -ErrorAction SilentlyContinue)){ New-Item $logpath -Force }

Function Log {
    param(
        [Parameter(Mandatory=$true)][String]$msg
    )
    
    Add-Content $logpath "$(Get-Date) $($msg)"
}

Function WUDrivers 
{

	$ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
	$ServiceManager.ClientApplicationID = "My App"
	$NewUpdateService = $ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")
    $NewUpdateService

	#search and list all missing Drivers
	$Session = New-Object -ComObject Microsoft.Update.Session           
	$Searcher = $Session.CreateUpdateSearcher() 
	$Searcher.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'
	$Searcher.SearchScope =  1 # MachineOnly
	$Searcher.ServerSelection = 3 # Third Party

	$Criteria = "IsInstalled=0 and ISHidden=0 and Type='Driver'"
	Log "Searching Driver-Updates..."
	$SearchResult = $Searcher.Search($Criteria)          
	$Updates = $SearchResult.Updates

	#Show available Drivers

	Log "Drivers from Windows Update:"

	$Updates | foreach-object { Log $_.Title }

	#Download the Drivers from Microsoft
	$UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
	$updates | ForEach-Object { $UpdatesToDownload.Add($_) | out-null }
	Log "Downloading Drivers..."
	$UpdateSession = New-Object -Com Microsoft.Update.Session
	$Downloader = $UpdateSession.CreateUpdateDownloader()
	$Downloader.Updates = $UpdatesToDownload
	$Downloader.Download()

	#Check if the Drivers are all downloaded and trigger the Installation
	$UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
	$updates | ForEach-Object { if($_.IsDownloaded) { $UpdatesToInstall.Add($_) | out-null } }

	Log "Installing Drivers..."
	$Installer = $UpdateSession.CreateUpdateInstaller()
	$Installer.Updates = $UpdatesToInstall
	$InstallationResult = $Installer.Install()
    Log "$InstallationResult"

}

$ComputerSystemProductVendor = Get-WmiObject -Class Win32_ComputerSystemProduct | Select-Object Vendor
$ComputerSystemManufacturer = Get-WmiObject -Class Win32_ComputerSystem | Select-Object Manufacturer


if (($ComputerSystemProductVendor.Vendor -like "*LENOVO*") -or ($ComputerSystemManufacturer.Manufacturer -like "*LENOVO*")) {
    Log "Lenovo machine, will install TVSU"

    start-process -FilePath "$PSScriptRoot\LenovoSystemUpdate\system_update_5.07.0127.exe" -ArgumentList "/verysilent /norestart" -Wait -Passthru -WindowStyle Hidden 
    Log "TVSU installed"  
    reg.exe add "HKLM\SOFTWARE\Policies\Lenovo\System Update\UserSettings\General" /v AdminCommandLine /t REG_SZ /d "/CM -search A -action INSTALL -includerebootpackages 3 -noicon -noreboot -exporttowmi" /f /reg:64 | Out-Null
    reg.exe add "HKLM\SOFTWARE\WOW6432Node\Lenovo\System Update\Preferences\UserSettings\General" /v AskBeforeClosing /t REG_SZ /d "NO" /f /reg:64 | Out-Null
    reg.exe add "HKLM\SOFTWARE\WOW6432Node\Lenovo\System Update\Preferences\UserSettings\General" /v DisplayLicenseNotice /t REG_SZ /d "NO" /f /reg:64 | Out-Null
    reg.exe add "HKLM\SOFTWARE\WOW6432Node\Lenovo\System Update\Preferences\UserSettings\General" /v MetricsEnabled /t REG_SZ /d "NO" /f /reg:64 | Out-Null
    reg.exe add "HKLM\SOFTWARE\WOW6432Node\Lenovo\System Update\Preferences\UserSettings\General" /v DebugEnable /t REG_SZ /d "YES" /f /reg:64 | Out-Null

    Log "Running System Update, check C:\ProgramData\Lenovo\SystemUpdate\Logs"
    $su = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Lenovo\System Update\tvsu.exe"
    &$su /CM | Out-Null
    Wait-Process -Name Tvsukernel
    Disable-ScheduledTask -TaskPath "\TVT" -TaskName "TVSUUpdateTask"
    Disable-ScheduledTask -TaskPath "\TVT" -TaskName "TVSUUpdateTask_UserLogOn"
    reg.exe add "HKLM\SOFTWARE\WOW6432Node\Lenovo\System Update\Preferences\UserSettings\Scheduler" /v SchedulerAbility /t REG_SZ /d "NO" /f /reg:64 | Out-Null
    Log "Finished"   
    WUDrivers
    exit 3010

}elseif (($ComputerSystemProductVendor.Vendor -like "*DELL*") -or ($ComputerSystemManufacturer.Manufacturer -like "*DELL*")) {
    Log "Dell machine, will install dell command update"
    start-process -FilePath "$PSScriptRoot\DellCommandUpdate\DellCommandUpdateApp_Setup.exe" -ArgumentList "/S /v/qn" -Wait -Passthru -WindowStyle Hidden 
    Log "Dell Command Update installed"
    Start-Process -FilePath "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/applyUpdates -silent -reboot=disable -updateSeverity=critical,recommended -updateType=driver -outputLog=C:\TEMP\dell_dcu_cli.log" -Wait -Passthru -WindowStyle Hidden
    Log "Dell Command Update Finished"   
    exit 3010

}elseif (($ComputerSystemProductVendor.Vendor -like "*HP*") -or ($ComputerSystemManufacturer.Manufacturer -like "*HP*") -or ($ComputerSystemManufacturer.Manufacturer -like "*Hewlett-Packard*") -or ($ComputerSystemProductVendor.Vendor -like "*Hewlett-Packard*")) {
    Log "HP machine"
    Log "HP machine - staging tools - check C:\Windows\Temp"
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File .\Invoke-HPDriverUpdate.ps1 Stage" -Wait -Passthru -WindowStyle Hidden 
    Log "HP machine - running drivers update - check C:\Windows\Temp"
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File .\Invoke-HPDriverUpdate.ps1 Execute" -Wait -Passthru -WindowStyle Hidden     
    Set-Content -Path "$($env:Programdata)\driversinstalled.tag" -Value "Installed"
    Log "Finished"   
    exit 3010

}
else {
    WUDrivers
    Set-Content -Path "$($env:Programdata)\driversinstalled.tag" -Value "Installed"
}

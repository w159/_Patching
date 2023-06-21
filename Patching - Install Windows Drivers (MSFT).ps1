﻿$UpdateSvc = New-Object -ComObject Microsoft.Update.ServiceManager
$UpdateSvc.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")
$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher() 

$Searcher.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'
$Searcher.SearchScope =  1 # MachineOnly
$Searcher.ServerSelection = 3 # Third Party
          
$Criteria = "IsInstalled=0 and Type='Driver'"
Write-Host('Searching Driver-Updates...') -Fore Green     
$SearchResult = $Searcher.Search($Criteria)          
$Updates = $SearchResult.Updates
if([string]::IsNullOrEmpty($Updates)){
  Write-Host "No pending driver updates."
}
else{
  #Show available Drivers...
  $Updates | Select-Object Title, DriverModel, DriverVerDate, Driverclass, DriverManufacturer | Format-List
  $UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
  $updates | ForEach-Object { $UpdatesToDownload.Add($_) | out-null }
  Write-Host('Downloading Drivers...')  -Fore Green
  $UpdateSession = New-Object -Com Microsoft.Update.Session
  $Downloader = $UpdateSession.CreateUpdateDownloader()
  $Downloader.Updates = $UpdatesToDownload
  $Downloader.Download()
  $UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
  $updates | ForEach-Object { if($_.IsDownloaded) { $UpdatesToInstall.Add($_) | out-null } }

  Write-Host('Installing Drivers...')  -Fore Green
  $Installer = $UpdateSession.CreateUpdateInstaller()
  $Installer.Updates = $UpdatesToInstall
  $InstallationResult = $Installer.Install()
  if($InstallationResult.RebootRequired) { 
  Write-Host('Reboot required! Please reboot now.') -Fore Red
  } else { Write-Host('Done.') -Fore Green }
  $updateSvc.Services | Where-Object { $_.IsDefaultAUService -eq $false -and $_.ServiceID -eq "7971f918-a847-4430-9279-4a52d1efe18d" } | ForEach-Object { $UpdateSvc.RemoveService($_.ServiceID) }
}
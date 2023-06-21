$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$iwrParams = @{
    Uri                = 'https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x64'
    UserAgent          = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36 Edg/112.0.1722.71'
    MaximumRedirection = 0
    UseBasicParsing    = $True
    ErrorAction        = 'SilentlyContinue'
}

$WebRequest = Invoke-WebRequest @iwrParams
$ZoomDownload = $WebRequest.Headers.Location

$RegEx = '(?<=prod/)[0-9.]+'
$ZoomLatestVersion = [regex]::Matches($ZoomDownload, $RegEx) | ForEach-Object { $_.Value }
$ZoomApp = Get-WmiObject win32_product | Where-Object Name -Like 'Zoom(64bit)' | Select-Object -ExpandProperty Name
$ZoomCurrentVersion = Get-WmiObject win32_product | Where-Object Name -Like 'Zoom(64bit)' | Select-Object -ExpandProperty Version
$ZoomEXE = Test-Path -Path 'C:\Program Files\Zoom\bin\Zoom.exe'
$ZoomMSI = 'C:\Utils\ZoomInstallerFull.msi'
$InstallArgs = '/norestart /qn ZoomAutoUpdate=1 MSIRestartManagerControl=Disable zNoDesktopShortCut=True zSilentStart=1 /lex "C:\Utils\ZoomUpdater.log" zConfig="AU2_EnableAutoUpdate=1;AU2_UpdateChannelCandidates=1;AU2_SetUpdateChannel=1;AU2_EnableManualUpdate=0;AU2_EnableUpdateSuccessNotification=0;AU2_EnableUpdateAvailableBanner=0;AU2_EnableShowZoomUpdates=0;AutoStartAfterReboot=0;Min2Tray=1"'


if ( ($ZoomApp -eq 'Zoom(64bit)') -or ($ZoomEXE -eq $true) -and ($ZoomCurrentVersion -ne $ZoomLatestVersion) )
{

    Write-Host "Zoom found, updating to $ZoomLatestVersion"
    Invoke-WebRequest -UseBasicParsing 'https://zoom.us/client/latest/ZoomInstallerFull.msi?archType=x64' -OutFile 'C:\Utils\ZoomInstallerFull.msi' -UserAgent $UserAgent
    Unblock-File $ZoomMSI
    Start-Process -FilePath $ZoomMSI -ArgumentList $InstallArgs -Wait

    # Zoom Desktop System Settings
    New-Item -Path 'HKLM:\SOFTWARE\ZoomUMX\PerInstall' -Force -ErrorAction SilentlyContinue
    New-ItemProperty -Path 'HKLM:\SOFTWARE\ZoomUMX\PerInstall' -Name 'enableupdate' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue
    New-ItemProperty -Path 'HKLM:\SOFTWARE\ZoomUMX\PerInstall' -Name 'nodesktopshortcut' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue
    New-ItemProperty -Path 'HKLM:\SOFTWARE\ZoomUMX\PerInstall' -Name 'silentstart' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue

    # Configure Zoom Desktop Per User Settings
    New-PSDrive -PSProvider 'Registry' -Name 'HKU' -Root 'HKEY_USERS' -ErrorAction SilentlyContinue
    $users = Get-ChildItem 'HKU:\'

    foreach ($user in $users)
    {

        $LocalUser = $user.name
        New-Item -Path "HKU:\$LocalUser\SOFTWARE\ZoomUMX" -Force -ErrorAction SilentlyContinue
        New-ItemProperty -Path "HKU:\$LocalUser\SOFTWARE\ZoomUMX" -Name 'enableupdate' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue
        New-ItemProperty -Path "HKU:\$LocalUser\SOFTWARE\ZoomUMX" -Name 'nodesktopshortcut' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue
        New-ItemProperty -Path "HKU:\$LocalUser\SOFTWARE\ZoomUMX" -Name 'silentstart' -Value 'true' -PropertyType String -Force -ErrorAction SilentlyContinue

    }
}
else
{
    Write-Host 'Zoom not found, taking no action'
}
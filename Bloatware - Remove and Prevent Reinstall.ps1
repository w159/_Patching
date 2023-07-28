


$ProgressPreference = 'SilentlyContinue'
New-Item -Path C:\ -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue

$AppXPackages = @(
    '*3dbuilder*',
    '*Wifi*',
    '*windowsalarms*',
    '*windowscommunicationsapps*',
    '*officehub*',
    '*skypeapp*',
    '*getstarted*',
    '*zunemusic*',
    '*windowsmaps*',
    '*solitairecollection*',
    '*bingfinance*',
    '*zunevideo*',
    '*bingnews*',
    '*onenote*',
    '*people*',
    '*windowsphone*',
    '*bingsports*',
    '*soundrecorder*',
    '*bingweather*',
    '*xboxapp*',
    '*phone*',
    '*sway*',
    '*AdobePhotoshopExpress*',
    '*Candy*',
    '*Duolingo*',
    '*EclipseManager*',
    '*FarmVille*',
    '*Microsoft.3DBuilder*',
    '*Microsoft.BingNews*',
    '*Microsoft.BingTranslator*',
    '*Microsoft.BingWeather*',
    '*Microsoft.FreshPaint*',
    '*Microsoft.Getstarted*',
    '*Microsoft.Messaging*',
    '*Microsoft.MicrosoftOfficeHub*',
    '*Microsoft.MicrosoftSolitaireCollection*',
    '*Microsoft.NetworkSpeedTest*',
    '*Microsoft.Office.OneNote*',
    '*Microsoft.People*',
    '*Microsoft.SkypeApp*',
    '*Microsoft.WindowsAlarms*',
    '*Microsoft.WindowsFeedbackHub*',
    '*Microsoft.WindowsMaps*',
    'Microsoft.Winget.Source*',
    '*Microsoft.XboxApp*',
    '*Microsoft.ZuneMusic*',
    '*Microsoft.ZuneVideo*',
    '*Netflix*',
    '*PandoraMediaInc*',
    '*PicsArt*',
    '*Twitter*',
    '*Wunderlist*',
    '*Phone*',
    '*HPPrinterControl*'
)

foreach ($package in $AppXPackages)
{
    Write-Host 'Removing package:' $package
    Get-AppxPackage -AllUsers $package | Remove-AppxPackage -AllUsers
}

$AppCProvisionedPackages = @(
    '*AdobePhotoshopExpress*',
    '*Candy*',
    '*Duolingo*',
    '*EclipseManager*',
    '*FarmVille*',
    '*Microsoft.3DBuilder*',
    '*Microsoft.BingNews*',
    '*Microsoft.BingTranslator*',
    '*Microsoft.BingWeather*',
    '*Microsoft.FreshPaint*',
    '*Microsoft.Getstarted*',
    '*Microsoft.Messaging*',
    '*Microsoft.MicrosoftOfficeHub*',
    '*Microsoft.MicrosoftSolitaireCollection*',
    '*Microsoft.NetworkSpeedTest*',
    '*Microsoft.Office.OneNote*',
    '*Microsoft.People*',
    '*Microsoft.SkypeApp*',
    '*Microsoft.WindowsAlarms*',
    '*Microsoft.WindowsFeedbackHub*',
    '*Microsoft.WindowsMaps*',
    'Microsoft.Winget.Source*',
    '*Microsoft.XboxApp*',
    '*Microsoft.ZuneMusic*',
    '*Microsoft.ZuneVideo*',
    '*Netflix*',
    '*PandoraMediaInc*',
    '*PicsArt*',
    '*Twitter*',
    '*Wunderlist*',
    '*Phone*',
    '*windowscommunicationsapps*',
    '*bingfinance*',
    '*zunevideo*',
    '*WindowsPhone*',
    '*Money*',
    '*Windowsalarms*',
    '*bingsports*',
    '*sports*',
    '*sway*',
    '*Wifi*',
    '*HPPrinterControl*'
)

Get-AppxProvisionedPackage -Online | Where-Object { $AppCProvisionedPackages -contains $_.PackageName } | ForEach-Object {
    Write-Host 'Removing provisioned package:' $_.PackageName
    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName }


Write-Output 'Uninstalling default apps'

# Prevents Apps from re-installing
$cdm = @(
    'ContentDeliveryAllowed'
    'FeatureManagementEnabled'
    'OemPreInstalledAppsEnabled'
    'PreInstalledAppsEnabled'
    'PreInstalledAppsEverEnabled'
    'SilentInstalledAppsEnabled'
    'SubscribedContent-314559Enabled'
    'SubscribedContent-338387Enabled'
    'SubscribedContent-338388Enabled'
    'SubscribedContent-338389Enabled'
    'SubscribedContent-338393Enabled'
    'SubscribedContentEnabled'
    'SystemPaneSuggestionsEnabled'
)
New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Force -ErrorAction SilentlyContinue
foreach ($key in $cdm)
{
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' $key 0 -Force -ErrorAction SilentlyContinue
}

Write-Output 'Disabling Cortana...'
If (!(Test-Path 'HKCU:\Software\Microsoft\Personalization\Settings'))
{
    New-Item -Path 'HKCU:\Software\Microsoft\Personalization\Settings' -Force | Out-Null
}
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Personalization\Settings' -Name 'AcceptedPrivacyPolicy' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
If (!(Test-Path 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore'))
{
    New-Item -Path 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' -Force | Out-Null
}
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitTextCollection' -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitInkCollection' -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' -Name 'HarvestContacts' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCortanaButton' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana' -Name 'Value' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'))
{
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization'))
{
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' -Name 'AllowInputPersonalization' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.549981C3F5F10' | Remove-AppxPackage -ErrorAction SilentlyContinue
Write-Output 'done'1

Write-Output 'Disabling Xbox bloat...'
Get-AppxPackage 'Microsoft.XboxApp' | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.XboxIdentityProvider' | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.XboxSpeechToTextOverlay' | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.XboxGameOverlay' | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.XboxGamingOverlay' | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.Xbox.TCUI' | Remove-AppxPackage -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'))
{
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' | Out-Null
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue


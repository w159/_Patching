
<#
Removes and prevents reinstall of built-in Windows 10 bloatware applications.

Last Updated - 5.30.2024 JM


#>



$ProgressPreference = 'SilentlyContinue'
New-Item -Path C:\ -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue

# Uninstall default Microsoft applications
$MsftBloatApps = @(
    '*3dbuilder*',
    '*Wifi*',
    '*windowsalarms*',
    '*Spotify*',
    '*Netflix*',
    '*pandora*',
    '*twitter*',
    '*LinkedIn*',
    '*Facebook*',
    '*CandyCrush*',
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
    '*Microsoft.XboxApp*',
    '*Microsoft.ZuneMusic*',
    '*Microsoft.ZuneVideo*',
    '*Netflix*',
    '*PandoraMediaInc*',
    '*PicsArt*',
    '*Twitter*',
    '*Wunderlist*',
    '*Phone*',
    '*HPPrinterControl'
)

# Uninstall default third party applications
$ThirdPartyBloatApps = @(
    '9E2F88E3.Twitter',
    'PandoraMediaInc.29680B314EFC2',
    'Flipboard.Flipboard',
    'D52A8D61.FarmVille2CountryEscape',
    '6Wunderkinder.Wunderlist',
    'A278AB0D.MarchofEmpires',
    'king.com.CandyCrushSaga',
    'king.com.CandyCrushJellySaga',
    'spotifyAB.SpotifyMusic',
    'king.com.CandyCrushSodaSaga',
    '4DF9E0F8.Netflix',
    'Drawboard.DrawboardPDF',
    'D52A8D61.FarmVille2CountryEscape',
    'GAMELOFTSA.Asphalt8Airborne',
    'flaregamesGmbH.RoyalRevolt2',
    'AdobeSystemsIncorporated.AdobePhotoshopExpress',
    'ActiproSoftwareLLC.562882FEEB491',
    'D5EA27B7.Duolingo-LearnLanguagesforFree',
    'Facebook.Facebook',
    '46928bounde.EclipseManager',
    'A278AB0D.MarchofEmpires',
    'KeeperSecurityInc.Keeper',
    'king.com.BubbleWitch3Saga',
    '89006A2E.AutodeskSketchBook',
    'CAF9E577.Plex',
    'A278AB0D.DisneyMagicKingdoms',
    '828B5831.HiddenCityMysteryofShadows'
)

$XboxFeaturesApps = @(
    'Microsoft.XboxApp',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.XboxGameOverlay',
    'Microsoft.Xbox.TCUI'
)

# Remove Microsoft Bloat Apps
foreach ($MsftBloatApp in $MsftBloatApps) {
    Get-AppxPackage -Name $MsftBloatApp -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $MsftBloatApp | Remove-AppxProvisionedPackage -Online
}

# Remove Third Party Apps
foreach ($ThirdPartyBloatApp in $ThirdPartyBloatApps) {
    Get-AppxPackage -Name $ThirdPartyBloatApp -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $ThirdPartyBloatApp | Remove-AppxProvisionedPackage -Online
}

# Remove Xbox Apps
foreach ($XboxFeaturesApp in $XboxFeaturesApps) {
    Get-AppxPackage -Name $XboxFeaturesApp -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $XboxFeaturesApp | Remove-AppxProvisionedPackage -Online
}

# Disable Xbox gaming features
Set-ItemProperty -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Type DWord -Value 0
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR')) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Force
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Type DWord -Value 0

# Uninstall Windows Media Player
Disable-WindowsOptionalFeature -Online -FeatureName 'WindowsMediaPlayer' -NoRestart -WarningAction SilentlyContinue

# Disable search for app in store for unknown extensions
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer')) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Force
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'NoUseStoreOpenWith' -Type DWord -Value 1

# Disable Wi-Fi Sense
If (!(Test-Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting')) {
    New-Item -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' -Name 'Value' -Type DWord -Value 0
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' -Name 'Value' -Type DWord -Value 0

# Disable Bing Search in Start Menu
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Type DWord -Value 0
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search')) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Force
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'DisableWebSearch' -Type DWord -Value 1

# Prevent Apps from re-installing
$cdm = @(
    'ContentDeliveryAllowed',
    'FeatureManagementEnabled',
    'OemPreInstalledAppsEnabled',
    'PreInstalledAppsEnabled',
    'PreInstalledAppsEverEnabled',
    'SilentInstalledAppsEnabled',
    'SubscribedContent-314559Enabled',
    'SubscribedContent-338387Enabled',
    'SubscribedContent-338388Enabled',
    'SubscribedContent-338389Enabled',
    'SubscribedContent-338393Enabled',
    'SubscribedContentEnabled',
    'SystemPaneSuggestionsEnabled'
)
New-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Force -ErrorAction SilentlyContinue
foreach ($key in $cdm) {
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' $key 0 -Force -ErrorAction SilentlyContinue
}

# Disable Cortana
Write-Output 'Disabling Cortana...'
If (!(Test-Path 'HKCU:\Software\Microsoft\Personalization\Settings')) {
    New-Item -Path 'HKCU:\Software\Microsoft\Personalization\Settings' -Force | Out-Null
}
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Personalization\Settings' -Name 'AcceptedPrivacyPolicy' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
If (!(Test-Path 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore')) {
    New-Item -Path 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' -Force | Out-Null
}
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitTextCollection' -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\InputPersonalization' -Name 'RestrictImplicitInkCollection' -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' -Name 'HarvestContacts' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowCortanaButton' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana' -Name 'Value' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search')) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization')) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization' -Name 'AllowInputPersonalization' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.549981C3F5F10' | Remove-AppxPackage -ErrorAction SilentlyContinue
Write-Output 'Done'

# Disable Xbox bloat
Write-Output 'Disabling Xbox bloat...'
Get-AppxPackage 'Microsoft.XboxApp' | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.XboxIdentityProvider' | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.XboxSpeechToTextOverlay' | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.XboxGameOverlay' | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.XboxGamingOverlay' | Remove-AppxPackage -ErrorAction SilentlyContinue
Get-AppxPackage 'Microsoft.Xbox.TCUI' | Remove-AppxPackage -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR')) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue

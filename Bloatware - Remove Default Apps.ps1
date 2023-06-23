
$apps = @(
    'Microsoft.549981C3F5F10' # Cortana
    'Microsoft.3DBuilder'
    'Microsoft.BingFinance'
    'Microsoft.BingNews'
    'Microsoft.BingSports'
    'Microsoft.BingTranslator'
    'Microsoft.BingWeather'
    'Microsoft.GamingServices'
    'Microsoft.Microsoft3DViewer'
    'Microsoft.MicrosoftOfficeHub'
    'Microsoft.MicrosoftPowerBIForWindows'
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.MinecraftUWP'
    'Microsoft.NetworkSpeedTest'
    'Microsoft.Print3D'
    'Microsoft.SkypeApp'
    'Microsoft.WindowsMaps'
    'Microsoft.WindowsSoundRecorder'
    'Microsoft.Xbox.TCUI'
    'Microsoft.XboxApp'
    'Microsoft.XboxGameOverlay'
    'Microsoft.XboxGamingOverlay'
    'Microsoft.XboxSpeechToTextOverlay'
    'Microsoft.ZuneMusic'
    'Microsoft.ZuneVideo'

    # Threshold 2 apps
    #'Microsoft.CommsPhone'
    'Microsoft.ConnectivityStore'
    'Microsoft.GetHelp'
    'Microsoft.Getstarted'
    'Microsoft.Messaging'
    'Microsoft.Office.Sway'
    'Microsoft.OneConnect'
    'Microsoft.WindowsFeedbackHub'

    # Creators Update apps
    'Microsoft.Microsoft3DViewer'
    #"Microsoft.MSPaint"

    # Redstone apps
    'Microsoft.BingFoodAndDrink'
    'Microsoft.BingHealthAndFitness'
    'Microsoft.BingTravel'
    'Microsoft.WindowsReadingList'

    # Redstone 5 apps
    'Microsoft.MixedReality.Portal'
    'Microsoft.ScreenSketch'
    'Microsoft.XboxGamingOverlay'
    #'Microsoft.YourPhone'

    # non-Microsoft
    'E046963F.AIMeetingManager'
    'E046963F.LenovoCompanion'
    'E046963F.LenovoSettingsforEnterprise'
    'E0469640.LenovoUtility'
    '2FE3CB00.PicsArt-PhotoStudio'
    '46928bounde.EclipseManager'
    '4DF9E0F8.Netflix'
    '613EBCEA.PolarrPhotoEditorAcademicEdition'
    '6Wunderkinder.Wunderlist'
    '7EE7776C.LinkedInforWindows'
    '89006A2E.AutodeskSketchBook'
    '9E2F88E3.Twitter'
    'A278AB0D.DisneyMagicKingdoms'
    'A278AB0D.MarchofEmpires'
    'ActiproSoftwareLLC.562882FEEB491' # next one is for the Code Writer from Actipro Software LLC
    'CAF9E577.Plex'
    'ClearChannelRadioDigital.iHeartRadio'
    'D52A8D61.FarmVille2CountryEscape'
    'D5EA27B7.Duolingo-LearnLanguagesforFree'
    'DB6EA5DB.CyberLinkMediaSuiteEssentials'
    'DolbyLaboratories.DolbyAccess'
    'Drawboard.DrawboardPDF'
    'Facebook.Facebook'
    'Fitbit.FitbitCoach'
    'Flipboard.Flipboard'
    'GAMELOFTSA.Asphalt8Airborne'
    'KeeperSecurityInc.Keeper'
    'NORDCURRENT.COOKINGFEVER'
    'PandoraMediaInc.29680B314EFC2'
    'Playtika.CaesarsSlotsFreeCasino'
    'ShazamEntertainmentLtd.Shazam'
    'SlingTVLLC.SlingTV'
    'SpotifyAB.SpotifyMusic'
    'TheNewYorkTimes.NYTCrossword'
    'ThumbmunkeysLtd.PhototasticCollage'
    'TuneIn.TuneInRadio'
    'WinZipComputing.WinZipUniversal'
    'XINGAG.XING'
    'flaregamesGmbH.RoyalRevolt2'
    'king.com.*'
    'king.com.BubbleWitch3Saga'
    'king.com.CandyCrushSaga'
    'king.com.CandyCrushSodaSaga'
    'AcrobatNotificationClient'
    'Windows.CBSPreview'

    # apps which other apps depend on
    'Microsoft.Advertising.Xaml'
)

Write-Output 'Uninstalling default apps'

foreach ($app in $apps)
{
    Write-Output "Trying to remove $app"

    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers

    Get-AppxProvisionedPackage -Online |
        Where-Object DisplayName -EQ $app |
        Remove-AppxProvisionedPackage -Online
}

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

New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore' -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore' 'AutoDownload' 2 -Force -ErrorAction SilentlyContinue

# Prevents "Suggested Applications" returning
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1 -Force -ErrorAction SilentlyContinue


Start-Process 'C:\Program Files (x86)\Hewlett-Packard\HP Support Framework\UninstallHPSA.exe' -ArgumentList '/S' -NoNewWindow -Wait
Start-Sleep -Seconds 60
$HPSupportFramework_CHECK = Get-WmiObject win32_product | Where-Object Name -Like 'HP Support Solutions*'
$HPSupportFramework_CHECK.Uninstall()


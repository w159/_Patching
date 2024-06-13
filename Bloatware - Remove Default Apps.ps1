#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param (
    [switch]$Silent,
    [switch]$RunAppConfigurator,
    [switch]$RunDefaults,
    [switch]$RunWin11Defaults,
    [switch]$RemoveApps,
    [switch]$RemoveAppsCustom,
    [switch]$RemoveGamingApps,
    [switch]$RemoveCommApps,
    [switch]$RemoveDevApps,
    [switch]$RemoveW11Outlook,
    [switch]$DisableDVR,
    [switch]$DisableTelemetry,
    [switch]$DisableBingSearches,
    [switch]$DisableBing,
    [switch]$DisableLockscrTips,
    [switch]$DisableLockscreenTips,
    [switch]$DisableWindowsSuggestions,
    [switch]$DisableSuggestions,
    [switch]$ShowHiddenFolders,
    [switch]$ShowKnownFileExt,
    [switch]$HideDupliDrive,
    [switch]$TaskbarAlignLeft,
    [switch]$HideSearchTb,
    [switch]$ShowSearchIconTb,
    [switch]$ShowSearchLabelTb,
    [switch]$ShowSearchBoxTb,
    [switch]$HideTaskview,
    [switch]$DisableCopilot,
    [switch]$DisableRecall,
    [switch]$DisableWidgets,
    [switch]$HideWidgets,
    [switch]$DisableChat,
    [switch]$HideChat,
    [switch]$ClearStart,
    [switch]$RevertContextMenu,
    [switch]$DisableOnedrive,
    [switch]$HideOnedrive,
    [switch]$Disable3dObjects,
    [switch]$Hide3dObjects,
    [switch]$DisableMusic,
    [switch]$HideMusic,
    [switch]$DisableIncludeInLibrary,
    [switch]$HideIncludeInLibrary,
    [switch]$DisableGiveAccessTo,
    [switch]$HideGiveAccessTo,
    [switch]$DisableShare,
    [switch]$HideShare
)

# Set specified parameters to always run
$Silent = $true
$RemoveAppsCustom = $true
$RemoveGamingApps = $true
$RemoveCommApps = $true
$RemoveW11Outlook = $true
$RemoveDevApps = $true
$DisableDVR = $true
$DisableBingSearches = $true
$DisableBing = $true
$DisableLockscrTips = $true
$DisableLockscreenTips = $true
$DisableWindowsSuggestions = $true
$DisableSuggestions = $true
$TaskbarAlignLeft = $true
$HideTaskview = $true
$DisableCopilot = $true
$DisableRecall = $true
$DisableWidgets = $true
$DisableChat = $true
$RevertContextMenu = $true
$Disable3dObjects = $true
$DisableMusic = $true
$DisableGiveAccessTo = $true

# Reads list of apps from file and removes them for all user accounts and from the OS image.
function RemoveAppsFromFile {
    $appsList = @(
        'ACGMediaPlayer',
        'ActiproSoftwareLLC',
        'AdobeSystemsIncorporated.AdobePhotoshopExpress',
        'Amazon.com.Amazon',
        'AmazonVideo.PrimeVideo',
        'Asphalt8Airborne',
        'AutodeskSketchBook',
        'CaesarsSlotsFreeCasino',
        'Clipchamp.Clipchamp',
        'COOKINGFEVER',
        'CyberLinkMediaSuiteEssentials',
        'Disney',
        'DisneyMagicKingdoms',
        'Dolby',
        'DrawboardPDF',
        'Duolingo-LearnLanguagesforFree',
        'EclipseManager',
        'Facebook',
        'FarmVille2CountryEscape',
        'fitbit',
        'Flipboard',
        'HiddenCity',
        'HULULLC.HULUPLUS',
        'iHeartRadio',
        'Instagram',
        'king.com.BubbleWitch3Saga',
        'king.com.CandyCrushSaga',
        'king.com.CandyCrushSodaSaga',
        'LinkedInforWindows',
        'MarchofEmpires',
        'Microsoft.3DBuilder',
        'Microsoft.549981C3F5F10',
        'Microsoft.BingFinance',
        'Microsoft.BingFoodAndDrink',
        'Microsoft.BingHealthAndFitness',
        'Microsoft.BingNews',
        'Microsoft.BingSports',
        'Microsoft.BingTranslator',
        'Microsoft.BingTravel',
        'Microsoft.BingWeather',
        'Microsoft.GamingApp',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.Messaging',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MicrosoftJournal',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftPowerBIForWindows',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MicrosoftStickyNotes',
        'Microsoft.MixedReality.Portal',
        'Microsoft.NetworkSpeedTest',
        'Microsoft.News',
        'Microsoft.Office.OneNote',
        'Microsoft.Office.Sway',
        'Microsoft.OneConnect',
        'Microsoft.OneDrive',
        'Microsoft.OutlookForWindows',
        'Microsoft.Paint',
        'Microsoft.People',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.Print3D',
        'Microsoft.SkypeApp',
        'Microsoft.Todos',
        'Microsoft.Whiteboard',
        'Microsoft.WindowsAlarms',
        'Microsoft.windowscommunicationsapps',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.WindowsSoundRecorder',
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo',
        'MicrosoftCorporationII.MicrosoftFamily',
        'MicrosoftTeams',
        'MSTeams',
        'Netflix',
        'NYTCrossword',
        'OneCalendar',
        'PandoraMediaInc',
        'PhototasticCollage',
        'PicsArt-PhotoStudio',
        'Plex',
        'PolarrPhotoEditorAcademicEdition',
        'Royal',
        'Shazam',
        'Sidia.LiveWallpaper',
        'SlingTV',
        'Speed',
        'Spotify',
        'TikTok',
        'TuneInRadio',
        'Twitter',
        'Viber',
        'Windows.DevHome',
        'WinZipUniversal',
        'Wunderlist',
        'XING',
        'ACGMediaPlayer',
        'ActiproSoftwareLLC',
        'AdobeSystemsIncorporated.AdobePhotoshopExpress',
        'Amazon.com.Amazon',
        'AmazonVideo.PrimeVideo',
        'Asphalt8Airborne',
        'AutodeskSketchBook',
        'CaesarsSlotsFreeCasino',
        'Clipchamp.Clipchamp',
        'COOKINGFEVER',
        'CyberLinkMediaSuiteEssentials',
        'Disney',
        'DisneyMagicKingdoms',
        'Dolby',
        'DrawboardPDF',
        'Duolingo-LearnLanguagesforFree',
        'EclipseManager',
        'Facebook',
        'FarmVille2CountryEscape',
        'fitbit',
        'Flipboard',
        'HiddenCity',
        'HULULLC.HULUPLUS',
        'iHeartRadio',
        'Instagram',
        'king.com.BubbleWitch3Saga',
        'king.com.CandyCrushSaga',
        'king.com.CandyCrushSodaSaga',
        'LinkedInforWindows',
        'MarchofEmpires',
        'Microsoft.3DBuilder',
        'Microsoft.549981C3F5F10',
        'Microsoft.BingFinance',
        'Microsoft.BingFoodAndDrink',
        'Microsoft.BingHealthAndFitness',
        'Microsoft.BingNews',
        'Microsoft.BingSports',
        'Microsoft.BingTranslator',
        'Microsoft.BingTravel',
        'Microsoft.BingWeather',
        'Microsoft.GamingApp',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.Messaging',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MicrosoftJournal',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftPowerBIForWindows',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MicrosoftStickyNotes',
        'Microsoft.MixedReality.Portal',
        'Microsoft.NetworkSpeedTest',
        'Microsoft.News',
        'Microsoft.Office.OneNote',
        'Microsoft.Office.Sway',
        'Microsoft.OneConnect',
        'Microsoft.OneDrive',
        'Microsoft.OutlookForWindows',
        'Microsoft.Paint',
        'Microsoft.People',
        'Microsoft.PowerAutomateDesktop',
        'Microsoft.Print3D',
        'Microsoft.SkypeApp',
        'Microsoft.Todos',
        'Microsoft.Whiteboard',
        'Microsoft.WindowsAlarms',
        'Microsoft.windowscommunicationsapps',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps',
        'Microsoft.WindowsSoundRecorder',
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxIdentityProvider',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo',
        'MicrosoftCorporationII.MicrosoftFamily',
        'MicrosoftTeams',
        'MSTeams',
        'Netflix',
        'NYTCrossword',
        'OneCalendar',
        'PandoraMediaInc',
        'PhototasticCollage',
        'PicsArt-PhotoStudio',
        'Plex',
        'PolarrPhotoEditorAcademicEdition',
        'Royal',
        'Shazam',
        'Sidia.LiveWallpaper',
        'SlingTV',
        'Speed',
        'Spotify',
        'TikTok',
        'TuneInRadio',
        'Twitter',
        'Viber',
        'Windows.DevHome',
        'WinZipUniversal',
        'Wunderlist',
        'XING',
        'Microsoft.549981C3F5F10',
        'Microsoft.3DBuilder',
        'Microsoft.BingFinance',
        'Microsoft.BingNews',
        'Microsoft.BingSports',
        'Microsoft.BingTranslator',
        'Microsoft.BingWeather',
        'Microsoft.GamingServices',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftPowerBIForWindows',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MinecraftUWP',
        'Microsoft.NetworkSpeedTest',
        'Microsoft.Print3D',
        'Microsoft.SkypeApp',
        'Microsoft.WindowsMaps',
        'Microsoft.WindowsSoundRecorder',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.XboxSpeechToTextOverlay',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo',
        'Microsoft.CommsPhone',
        'Microsoft.ConnectivityStore',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.Messaging',
        'Microsoft.Office.Sway',
        'Microsoft.OneConnect',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MSPaint',
        'Microsoft.BingFoodAndDrink',
        'Microsoft.BingHealthAndFitness',
        'Microsoft.BingTravel',
        'Microsoft.WindowsReadingList',
        'Microsoft.MixedReality.Portal',
        'Microsoft.ScreenSketch',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.YourPhone',
        'E046963F.AIMeetingManager',
        'E046963F.LenovoCompanion',
        'E046963F.LenovoSettingsforEnterprise',
        'E0469640.LenovoUtility',
        '2FE3CB00.PicsArt-PhotoStudio',
        '46928bounde.EclipseManager',
        '4DF9E0F8.Netflix',
        '613EBCEA.PolarrPhotoEditorAcademicEdition',
        '6Wunderkinder.Wunderlist',
        '7EE7776C.LinkedInforWindows',
        '89006A2E.AutodeskSketchBook',
        '9E2F88E3.Twitter',
        'A278AB0D.DisneyMagicKingdoms',
        'A278AB0D.MarchofEmpires',
        'ActiproSoftwareLLC.562882FEEB491',
        'CAF9E577.Plex',
        'ClearChannelRadioDigital.iHeartRadio',
        'D52A8D61.FarmVille2CountryEscape',
        'D5EA27B7.Duolingo-LearnLanguagesforFree',
        'DB6EA5DB.CyberLinkMediaSuiteEssentials',
        'DolbyLaboratories.DolbyAccess',
        'Drawboard.DrawboardPDF',
        'Facebook.Facebook',
        'Fitbit.FitbitCoach',
        'Flipboard.Flipboard',
        'GAMELOFTSA.Asphalt8Airborne',
        'KeeperSecurityInc.Keeper',
        'NORDCURRENT.COOKINGFEVER',
        'PandoraMediaInc.29680B314EFC2',
        'Playtika.CaesarsSlotsFreeCasino',
        'ShazamEntertainmentLtd.Shazam',
        'SlingTVLLC.SlingTV',
        'SpotifyAB.SpotifyMusic',
        'TheNewYorkTimes.NYTCrossword',
        'ThumbmunkeysLtd.PhototasticCollage',
        'TuneIn.TuneInRadio',
        'WinZipComputing.WinZipUniversal',
        'XINGAG.XING',
        'flaregamesGmbH.RoyalRevolt2',
        'king.com.*',
        'king.com.BubbleWitch3Saga',
        'king.com.CandyCrushSaga',
        'king.com.CandyCrushSodaSaga',
        'AcrobatNotificationClient',
        'Windows.CBSPreview',
        'Microsoft.Advertising.Xaml'
    )

    Write-Output '> Removing default selection of apps...'

    # Get list of apps from file at the path provided, and remove them one by one
    Foreach ($app in ($appsList)) {
        $appString = $app.Trim('*')
        $appsList += $appString
    }

    RemoveApps $appsList
}

# Removes apps specified during function call from all user accounts and from the OS image.
function RemoveApps {
    param (
        $appslist
    )

    Foreach ($app in $appsList) {
        Write-Output "Attempting to remove $app..."

        if (($app -eq 'Microsoft.OneDrive') -or ($app -eq 'Microsoft.Edge')) {
            # Use winget to remove OneDrive and Edge
            if ($global:wingetInstalled -eq $false) {
                Write-Host "WinGet is either not installed or is outdated, so $app could not be removed" -ForegroundColor Red
            }
            else {
                # Uninstall app via winget
                winget uninstall --accept-source-agreements --disable-interactivity --id $app
            }
        }
        else {
            # Use Remove-AppxPackage to remove all other apps
            $app = '*' + $app + '*'

            # Remove installed app for all existing users
            Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers

            # Remove provisioned app from OS image, so the app won't be installed for any new users
            Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $app } | ForEach-Object { Remove-ProvisionedAppxPackage -Online -AllUsers -PackageName $_.PackageName }
        }
    }
}

# Restart the Windows explorer process
function RestartExplorer {
    Write-Output '> Restarting Windows explorer to apply all changes. Note: This may cause some flickering.'

    if ([Environment]::Is64BitProcess -eq [Environment]::Is64BitOperatingSystem) {
        Stop-Process -processName: Explorer -Force
    }
    else {
        Write-Warning 'Unable to restart Windows Explorer, please manually restart your PC to apply all changes.'
    }
}

# Check if winget is installed & if it is, check if the version is at least v1.4
if ((Get-AppxPackage -Name '*Microsoft.DesktopAppInstaller*') -and ((winget -v) -replace 'v', '' -gt 1.4)) {
    $global:wingetInstalled = $true
}
else {
    $global:wingetInstalled = $false

    if (-not $Silent) {
        Write-Warning 'Winget is not installed or outdated. This may prevent Win11Debloat from removing certain apps.'
    }
}

# Hide progress bars for app removal, as they block Win11Debloat's output
$ProgressPreference = 'SilentlyContinue'

RemoveAppsFromFile "$appsList"

Write-Output "> Removing $($appsList.Count) apps..."
RemoveApps $appsList

Write-Output '> Removing Mail, Calendar and People apps...'
$appsList = 'Microsoft.windowscommunicationsapps', 'Microsoft.People'
RemoveApps $appsList

Write-Output '> Removing new Outlook for Windows app...'
$appsList = 'Microsoft.OutlookForWindows'
RemoveApps $appsList

Write-Output '> Removing developer-related apps...'
$appsList = 'Microsoft.PowerAutomateDesktop', 'Microsoft.RemoteDesktop', 'Windows.DevHome'
RemoveApps $appsList

Write-Output '> Removing gaming-related apps...'
$appsList = 'Microsoft.GamingApp', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay'
RemoveApps $appsList

# Also remove the app package for Bing Search
$appsList = 'Microsoft.BingSearch'
RemoveApps $appsList

# Align taskbar left
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 0

# Disable AI Recall
if (-not (Test-Path 'HKLM:\Software\Microsoft\PolicyManager\default\Experience\AllowAITethering')) {
    New-Item -Path 'HKLM:\Software\Microsoft\PolicyManager\default\Experience\AllowAITethering' -Force
}
Set-ItemProperty -Path 'HKLM:\Software\Microsoft\PolicyManager\default\Experience\AllowAITethering' -Name 'value' -Value 0

# Disable App Launch Tracking
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackProgs' -Value 0
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\Explorer' -Name 'Start_TrackProgs' -Value 0

# Disable Bing Cortana in Search
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Value 0

# Disable Chat Taskbar
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Value 0

# Disable Copilot
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarCopilot' -Value 0

# Disable DVR
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Value 0

# Disable Give Access To context menu
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoExtendedContextMenus' -Value 1

# Disable Include in Library from context menu
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoInlcludeInLibrary' -PropertyType DWORD -Value 1 -Force

# Disable Lockscreen Tips
Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightFeatures' -Value 1

# Disable Share from context menu
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoShare' -PropertyType DWORD -Value 1 -Force

# Disable Show More Options Context Menu
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoLegacyContextMenu' -Value 1

# Disable Telemetry
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0

# Disable Widgets Taskbar
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarDa' -Value 0

# Disable Windows Suggestions
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 1

# Hide 3D Objects Folder
New-Item -Path 'HKCU:\Software\Classes\CLSID\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\ShellFolder' -Force
Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\ShellFolder' -Name 'Attributes' -Value 4035969014
Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\ShellFolder' -Name 'PinToNameSpaceTree' -Value 0

# Hide duplicate removable drives from navigation pane of File Explorer
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoDrivesInSendToMenu' -Value 1

# Hide Music Folder
New-Item -Path 'HKCU:\Software\Classes\CLSID\{3DFDF296-D6E4-4F4D-AD34-5FE9A5A67C82}\ShellFolder' -Force
Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{3DFDF296-D6E4-4F4D-AD34-5FE9A5A67C82}\ShellFolder' -Name 'Attributes' -Value 4035969014
Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{3DFDF296-D6E4-4F4D-AD34-5FE9A5A67C82}\ShellFolder' -Name 'PinToNameSpaceTree' -Value 0

# Hide OneDrive Folder
#New-Item -Path 'HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder' -Force
#Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder' -Name 'Attributes' -Value 4035969014
#Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder' -Name 'PinToNameSpaceTree' -Value 0

# Hide Search Taskbar
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'SearchBoxTaskbarMode' -Value 0

# Hide Taskview Taskbar
#Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Value 0

# Show Extensions for Known File Types
#Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0

# Show Hidden Folders
#Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Value 1
#Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSuperHidden' -Value 1

# Show Search Box
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'SearchBoxTaskbarMode' -Value 1

# Show Search Icon
#Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'SearchBoxTaskbarMode' -Value 2

# Show Search Icon and Label
#Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'SearchBoxTaskbarMode' -Value 3

$apps = @(
    $appsList
)

Write-Output 'Uninstalling default apps'
foreach ($app in $apps) {
    Write-Output "Trying to remove $app"
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online
}

# Disable Xbox gaming features
Set-ItemProperty -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Type DWord -Value 0
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR')) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Force
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Type DWord -Value 0

# Disable Bing Search in Start Menu
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Type DWord -Value 0
If (!(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search')) {
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Force
}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'DisableWebSearch' -Type DWord -Value 1

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
Get-AppxPackage 'Microsoft.549981C3F5F10' | Remove-AppxPackage -ErrorAction SilentlyContinue -AllUsers
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

# Prevents Apps from re-installing
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

New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore' -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore' 'AutoDownload' 2 -Force -ErrorAction SilentlyContinue

# Prevents "Suggested Applications" returning
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1 -Force -ErrorAction SilentlyContinue

RestartExplorer

Write-Output ''
Write-Output ''
Write-Output ''
Write-Output 'Script completed successfully!'
Write-Output 'Please restart your PC to apply all changes.'

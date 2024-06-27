#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param (
    [switch]$Silent,
    [switch]$RunAppConfigurator,
    [switch]$RunDefaults, [switch]$RunWin11Defaults,
    [switch]$RemoveApps,
    [switch]$RemoveAppsCustom,
    [switch]$RemoveGamingApps,
    [switch]$RemoveCommApps,
    [switch]$RemoveDevApps,
    [switch]$RemoveW11Outlook,
    [switch]$DisableDVR,
    [switch]$DisableTelemetry,
    [switch]$DisableBingSearches, [switch]$DisableBing,
    [switch]$DisableLockscrTips, [switch]$DisableLockscreenTips,
    [switch]$DisableWindowsSuggestions, [switch]$DisableSuggestions,
    [switch]$ShowHiddenFolders,
    [switch]$ShowKnownFileExt,
    [switch]$HideDupliDrive,
    [switch]$TaskbarAlignLeft,
    [switch]$HideSearchTb, [switch]$ShowSearchIconTb, [switch]$ShowSearchLabelTb, [switch]$ShowSearchBoxTb,
    [switch]$HideTaskview,
    [switch]$DisableCopilot,
    [switch]$DisableRecall,
    [switch]$DisableWidgets,
    [switch]$HideWidgets,
    [switch]$DisableChat,
    [switch]$HideChat,
    [switch]$ClearStart,
    [switch]$RevertContextMenu,
    [switch]$DisableOnedrive, [switch]$HideOnedrive,
    [switch]$Disable3dObjects, [switch]$Hide3dObjects,
    [switch]$DisableMusic, [switch]$HideMusic,
    [switch]$DisableIncludeInLibrary, [switch]$HideIncludeInLibrary,
    [switch]$DisableGiveAccessTo, [switch]$HideGiveAccessTo,
    [switch]$DisableShare, [switch]$HideShare
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
New-Item -Path 'C:\Windows\Utils' -ItemType Directory -Force

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

# Shows application selection form that allows the user to select what apps they want to remove or keep
$appsList = @(
    'ACGMediaPlayer'
    'ActiproSoftwareLLC'
    'AdobeSystemsIncorporated.AdobePhotoshopExpress'
    'Amazon.com.Amazon'
    'AmazonVideo.PrimeVideo'
    'Asphalt8Airborne'
    'AutodeskSketchBook'
    'CaesarsSlotsFreeCasino'
    'Clipchamp.Clipchamp'
    'COOKINGFEVER'
    'CyberLinkMediaSuiteEssentials'
    'Disney'
    'DisneyMagicKingdoms'
    'Dolby'
    'DrawboardPDF'
    'Duolingo-LearnLanguagesforFree'
    'EclipseManager'
    'Facebook'
    'FarmVille2CountryEscape'
    'fitbit'
    'Flipboard'
    'HiddenCity'
    'HULULLC.HULUPLUS'
    'iHeartRadio'
    'Instagram'
    'king.com.BubbleWitch3Saga'
    'king.com.CandyCrushSaga'
    'king.com.CandyCrushSodaSaga'
    'LinkedInforWindows'
    'Lenovo'
    'McAfeeWPSSparsePackage'
    'MarchofEmpires'
    'Microsoft.3DBuilder'
    'Microsoft.549981C3F5F10'
    'Microsoft.BingFinance'
    'Microsoft.BingFoodAndDrink'
    'Microsoft.BingHealthAndFitness'
    'Microsoft.BingNews'
    'Microsoft.BingSports'
    'Microsoft.BingTranslator'
    'Microsoft.BingTravel'
    'Microsoft.BingWeather'
    'Microsoft.Windows.ContentDeliveryManager'
    'Microsoft.GamingApp'
    'Microsoft.GetHelp'
    'Microsoft.Getstarted'
    'Microsoft.Messaging'
    'Microsoft.Microsoft3DViewer'
    'Microsoft.MicrosoftJournal'
    'Microsoft.MicrosoftOfficeHub'
    'Microsoft.MicrosoftPowerBIForWindows'
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.MicrosoftStickyNotes'
    'Microsoft.MixedReality.Portal'
    'Microsoft.NetworkSpeedTest'
    'Microsoft.News'
    'Microsoft.Office.OneNote'
    'Microsoft.Office.Sway'
    'Microsoft.OneConnect'
    'Microsoft.Windows.OOBENetworkConnectionFlow'
    'Microsoft.OneDrive'
    'Microsoft.OutlookForWindows'
    'Microsoft.Paint'
    'Microsoft.People'
    'Microsoft.Windows.PeopleExperienceHost'
    'Microsoft.Windows.ParentalControls'
    'Microsoft.PowerAutomateDesktop'
    'Microsoft.Print3D'
    'Microsoft.SkypeApp'
    'microsoft.microsoftskydrive'
    'Microsoft.Todos'
    'Microsoft.Whiteboard'
    'Microsoft.WindowsAlarms'
    'Microsoft.windowscommunicationsapps'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.WindowsMaps'
    'Microsoft.WindowsSoundRecorder'
    'Microsoft.XboxApp'
    'Microsoft.XboxGameOverlay'
    'Microsoft.XboxGamingOverlay'
    'Microsoft.XboxIdentityProvider'
    'Microsoft.XboxSpeechToTextOverlay'
    'Microsoft.YourPhone'
    'Microsoft.ZuneMusic'
    'Microsoft.ZuneVideo'
    'MicrosoftCorporationII.MicrosoftFamily'
    'MicrosoftTeams'
    'McAfeeWPSSparsePackage'
    'Microsoft.Xbox.TCUI'
    'Microsoft.XboxGameCallableUI'
    'MicrosoftCorporationII.QuickAssist'
    'MicrosoftWindows.UndockedDevKit'
    'MSTeams'
    'Netflix'
    'NYTCrossword'
    'OneCalendar'
    'PandoraMediaInc'
    'PhototasticCollage'
    'PicsArt-PhotoStudio'
    'Plex'
    'PolarrPhotoEditorAcademicEdition'
    'Royal'
    'Shazam'
    'Sidia.LiveWallpaper'
    'SlingTV'
    'Speed'
    'Spotify'
    'TikTok'
    'TuneInRadio'
    'Twitter'
    'Viber'
    'Windows.DevHome'
    'WinZipUniversal'
    'Wunderlist'
    'XING'
)



# Reads list of apps from file and removes them for all user accounts and from the OS image.
function RemoveAppsFromFile {
    $appsList = @($appsList)

    Write-Output '> Removing default selection of apps...'

    # Get list of apps from file at the path provided, and remove them one by one
    Foreach ($app in ($appsList)) {
        # Remove any spaces before and after the Appname
        $app = $app.Trim()

        # Remove any comments from the Appname
        if (-not ($app.IndexOf('#') -eq -1)) {
            $app = $app.Substring(0, $app.IndexOf('#'))
        }
        # Remove any remaining spaces from the Appname
        if (-not ($app.IndexOf(' ') -eq -1)) {
            $app = $app.Substring(0, $app.IndexOf(' '))
        }

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
            } else {
                # Uninstall app via winget
                winget uninstall --accept-source-agreements --disable-interactivity --id $app
            }
        } else {
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

    # Only restart if the powershell process matches the OS architecture
    # Restarting explorer from a 32bit Powershell window will fail on a 64bit OS
    if ([Environment]::Is64BitProcess -eq [Environment]::Is64BitOperatingSystem) {
        Stop-Process -processName: Explorer -Force
    } else {
        Write-Warning 'Unable to restart Windows Explorer, please manually restart your PC to apply all changes.'
    }
}


# Check if winget is installed & if it is, check if the version is at least v1.4
if ((Get-AppxPackage -Name '*Microsoft.DesktopAppInstaller*') -and ((winget -v) -replace 'v', '' -gt 1.4)) {
    $global:wingetInstalled = $true
} else {
    $global:wingetInstalled = $false

    # Show warning that requires user confirmation, Suppress confirmation if Silent parameter was passed
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

Write-Output ''

Write-Output '> Removing new Outlook for Windows app...'

$appsList = 'Microsoft.OutlookForWindows'
RemoveApps $appsList

Write-Output ''

Write-Output '> Removing developer-related related apps...'

$appsList = 'Microsoft.PowerAutomateDesktop', 'Microsoft.RemoteDesktop', 'Windows.DevHome'
RemoveApps $appsList

Write-Output ''

Write-Output '> Removing gaming related apps...'

$appsList = 'Microsoft.GamingApp', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay'
RemoveApps $appsList

Write-Output ''
# Also remove the app package for bing search
$appsList = 'Microsoft.BingSearch'
RemoveApps $appsList
Write-Output ''

# Align_Taskbar_Left.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 0

# Disable_AI_Recall.reg
Set-ItemProperty -Path 'HKLM:\Software\Microsoft\PolicyManager\default\Experience\AllowAITethering' -Name 'value' -Value 0

# Disable_App_Launch_Tracking_For_All_Users.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Start_TrackProgs' -Value 0
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\Explorer' -Name 'Start_TrackProgs' -Value 0

# Disable_Bing_Cortana_In_Search.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'BingSearchEnabled' -Value 0
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'CortanaConsent' -Value 0

# Disable_Chat_Taskbar.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarMn' -Value 0

# Disable_Copilot.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarCopilot' -Value 0

# Disable_DVR.reg
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Value 0

# Disable_Give_access_to_context_menu.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoExtendedContextMenus' -Value 1

# Disable_Include_in_library_from_context_menu.reg
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoInlcludeInLibrary' -PropertyType DWORD -Value 1 -Force

# Disable_Lockscreen_Tips.reg
Set-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsSpotlightFeatures' -Value 1

# Disable_Share_from_context_menu.reg
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoShare' -PropertyType DWORD -Value 1 -Force

# Disable_Show_More_Options_Context_Menu.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoLegacyContextMenu' -Value 1

# Disable_Telemetry.reg
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0

# Disable_Widgets_Taskbar.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarDa' -Value 0

# Disable_Windows_Suggestions.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 0

# Hide_3D_Objects_Folder.reg
New-Item -Path 'HKCU:\Software\Classes\CLSID\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\ShellFolder' -Force
Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\ShellFolder' -Name 'Attributes' -Value 4035969014
Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\ShellFolder' -Name 'PinToNameSpaceTree' -Value 0

# Hide_duplicate_removable_drives_from_navigation_pane_of_File_Explorer.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoDrivesInSendToMenu' -Value 1

# Hide_Music_Folder.reg
New-Item -Path 'HKCU:\Software\Classes\CLSID\{3DFDF296-D6E4-4F4D-AD34-5FE9A5A67C82}\ShellFolder' -Force
Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{3DFDF296-D6E4-4F4D-AD34-5FE9A5A67C82}\ShellFolder' -Name 'Attributes' -Value 4035969014
Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{3DFDF296-D6E4-4F4D-AD34-5FE9A5A67C82}\ShellFolder' -Name 'PinToNameSpaceTree' -Value 0

# Hide_Onedrive_Folder.reg
New-Item -Path 'HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder' -Force
Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder' -Name 'Attributes' -Value 4035969014
Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}\ShellFolder' -Name 'PinToNameSpaceTree' -Value 0

# Hide_Search_Taskbar.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'SearchBoxTaskbarMode' -Value 0

# Hide_Taskview_Taskbar.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowTaskViewButton' -Value 0

# Show_Extensions_For_Known_File_Types.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0

# Show_Hidden_Folders.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Value 1
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSuperHidden' -Value 1

# Show_Search_Box.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'SearchBoxTaskbarMode' -Value 1

# Show_Search_Icon.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'SearchBoxTaskbarMode' -Value 2

# Show_Search_Icon_And_Label.reg
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'SearchBoxTaskbarMode' -Value 3

# Remove McAffe crap app
#Invoke-WebRequest -UseBasicParsing 'https://download.mcafee.com/molbin/iss-loc/SupportTools/MCPR/MCPR.exe'  -OutFile 'C:\Windows\Utils\MCPR.exe'
#Expand-Archive 'C:\Windows\Utils\MCPR.exe' -DestinationPath 'C:\Windows\Utils' -Force
#Start-Process -FilePath 'C:\Windows\Utils\McAfee Consumer Product Removal Tool.exe' -ArgumentList '/q' -Wait


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
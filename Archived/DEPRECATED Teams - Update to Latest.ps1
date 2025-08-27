# Define the URL for the Teams desktop app download page
$teamsDownloadUrl = 'https://teams.microsoft.com/downloads'

# Check if Teams is installed
if (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like '*Teams*' } -NE $null)
{
     # Get the installed version of Teams
     $installedVersion = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like '*Teams*' }).DisplayVersion

     # Get the latest version of Teams from the download page
     $latestVersion = (Invoke-WebRequest $teamsDownloadUrl).Links | Where-Object { $_.href -like '*Teams_windows*' } | Select-Object -First 1 | Select-Object -ExpandProperty href | Select-String -Pattern '(\d+\.)+\d+'

     # Compare the installed version to the latest version
     if ($installedVersion -lt $latestVersion)
     {
          # Download and install the latest version of Teams
          $teamsInstallerUrl = 'https://teams.microsoft.com/downloads/desktopinstaller'
          $teamsInstallerPath = "$env:TEMP\TeamsSetup.exe"
          Invoke-WebRequest -Uri $teamsInstallerUrl -OutFile $teamsInstallerPath
          Start-Process -FilePath $teamsInstallerPath -ArgumentList '/silent /install' -Wait
     }
     else
     {
          Write-Host "Teams is up to date (version $installedVersion)"
     }
}
else
{
     Write-Host 'Teams is not installed'
}


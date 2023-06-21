<#
.DESCRIPTION
This script should check for the current NVIDIA driver installed and update as needed
The NVIDIA download site is used to compare the current and latest versions



#>

Get-ScheduledTask | Where-Object TaskName -EQ "Nvidia-Updater" | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
Get-ScheduledTask | Where-Object TaskName -EQ "S5 - NVIDIA Updater" | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

$VideoController = (Get-WmiObject -ClassName Win32_VideoController | Where-Object Name -match "NVIDIA").VideoProcessor

if ($VideoController -notcontains "NVIDIA"){

Write-Host "IS NVIDIA - Building script to verify up to date"


[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
New-Item -Path C:\ -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path C:\Windows -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue

Get-ScheduledTask | Where-Object TaskName -EQ "Nvidia-Updater" | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

$NVIDIAUpdatesScript = @"
`$TestWingetLocation = Get-ChildItem -Recurse -Path "C:\`$Env:Programfiles\WindowsApps\Microsoft.DesktopAppInstaller*" | Where-Object Name -Like "winget.exe"
`$nvidiaTempFolder = "`$folder\NVIDIA"
if (`$TestWingetLocation.Name -ne "winget.exe") {
    Write-Host "Installing WinGet Package Manager"
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Script -Name winget-install -Force
    winget-install
    `$WingetLocation = Get-ChildItem -Recurse -Path "C:\`$Env:Programfiles\WindowsApps\Microsoft.DesktopAppInstaller*" | Where-Object Name -Like "winget.exe"
    `$WingetCLI = `$WingetLocation.FullName
    Set-Alias -Name winget -Value `$WingetCLI -ErrorAction SilentlyContinue -Force
}
else {
    Write-Host "WinGet Package Manager Already installed!"
    `$WingetLocation = Get-ChildItem -Recurse -Path "C:\`$Env:Programfiles\WindowsApps\Microsoft.DesktopAppInstaller*" | Where-Object Name -Like "winget.exe"
    `$WingetCLI = `$WingetLocation.FullName
    Set-Alias -Name winget -Value `$WingetCLI -ErrorAction SilentlyContinue -Force
}

winget upgrade --id Nvidia.GeForceExperience --silent --accept-source-agreements --accept-package-agreements
# Installer options
`$folder = "C:\Utils"   # Downloads and extracts the driver here

`$scheduleTask = `$true  # Creates a Scheduled Task to run to check for driver updates
`$scheduleDay = "Sunday" # When should the scheduled task run (Default = Sunday)
`$scheduleTime = "11pm"  # The time the scheduled task should run (Default = 12pm)

# Checking if 7zip or WinRAR are installed
# Check 7zip install path on registry
`$7zipinstalled = `$false 
if ((Test-path HKLM:\SOFTWARE\7-Zip\) -eq `$true) {
    `$7zpath = Get-ItemProperty -path  HKLM:\SOFTWARE\7-Zip\ -Name Path
    `$7zpath = `$7zpath.Path
    `$7zpathexe = `$7zpath + "7z.exe"
    if ((Test-Path `$7zpathexe) -eq `$true) {
        `$archiverProgram = `$7zpathexe
        `$7zipinstalled = `$true 
    }    
}
if (`$7zipinstalled -eq `$false) {
    if ((Test-path HKLM:\SOFTWARE\WinRAR) -eq `$true) {
        `$winrarpath = Get-ItemProperty -Path HKLM:\SOFTWARE\WinRAR -Name exe64 
        `$winrarpath = `$winrarpath.exe64
        if ((Test-Path `$winrarpath) -eq `$true) {
            `$archiverProgram = `$winrarpath
        }
    }
}
else {
    # Download and silently install 7-zip if the user presses y
    `$7zip = "https://www.7-zip.org/a/7z2201-x64.exe"
    `$output = "C:\Utils\7Zip.exe"
        (New-Object System.Net.WebClient).DownloadFile(`$7zip, `$output)
    Start-Process `$output -Wait -ArgumentList "/S"
    # Delete the installer once it completes
    Remove-Item `$output
}

if ((Test-path HKLM:\SOFTWARE\7-Zip\) -eq `$true) {
    `$7zpath = Get-ItemProperty -path  HKLM:\SOFTWARE\7-Zip\ -Name Path
    `$7zpath = `$7zpath.Path
    `$7zpathexe = `$7zpath + "7z.exe"
    if ((Test-Path `$7zpathexe) -eq `$true) {
        `$archiverProgram = `$7zpathexe
        `$7zipinstalled = `$true 
    }    
}
if (`$7zipinstalled -eq `$false) {
    if ((Test-path HKLM:\SOFTWARE\WinRAR) -eq `$true) {
        `$winrarpath = Get-ItemProperty -Path HKLM:\SOFTWARE\WinRAR -Name exe64 
        `$winrarpath = `$winrarpath.exe64
        if ((Test-Path `$winrarpath) -eq `$true) {
            `$archiverProgram = `$winrarpath
        }
    }
}

# Checking currently installed driver version
try {
    `$VideoController = Get-WmiObject -ClassName Win32_VideoController | Where-Object { `$_.Name -match "NVIDIA" }
    `$ins_version = (`$VideoController.DriverVersion.Replace('.', '')[-5..-1] -join '').insert(3, '.')
}
catch {
    # exit 0
}
Write-Host "Installed version `t`$ins_version"

# Checking latest driver version
`$uri = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php' +
'?func=DriverManualLookup' +
'&psid=120' + # Geforce RTX 30 Series
'&pfid=929' + # RTX 3080
'&osID=57' + # Windows 10 64bit
'&languageCode=1033' + # en-US; seems to be "Windows Locale ID"[1] in decimal
'&isWHQL=1' + # WHQL certified
'&dch=1' + # DCH drivers (the new standard)
'&sort1=0' + # sort: most recent first(?)
'&numberOfResults=1' # single, most recent result is enough

#[1]: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/a9eac961-e77d-41a6-90a5-ce1a8b0cdb9c

`$response = Invoke-WebRequest -UseBasicParsing `$uri -Method GET
`$payload = `$response.Content | ConvertFrom-Json
`$version = `$payload.IDS[0].downloadInfo.Version
# Comparing installed driver version to latest driver version from Nvidia
if (!`$clean -and (`$version -eq `$ins_version)) {
    Write-Host "The installed version is the same as the latest version."
    # exit 0
}
else {

    Write-Host "NVIDIA Drivers are now being updated."
    # Checking Windows version
    if ([Environment]::OSVersion.Version -ge (new-object 'Version' 9, 1)) {
        `$windowsVersion = "win10-win11"
    }
    else {
        `$windowsVersion = "win8-win7"
    }

    # Checking Windows bitness
    if ([Environment]::Is64BitOperatingSystem) {
        `$windowsArchitecture = "64bit"
    }
    else {
        `$windowsArchitecture = "32bit"
    }

    # Create a new temp folder NVIDIA
    `$nvidiaTempFolder = "`$folder\NVIDIA"
    New-Item -Path `$nvidiaTempFolder -ItemType Directory 2>&1 | Out-Null

    # Generating the download link
    `$url = "https://international.download.nvidia.com/Windows/`$version/`$version-desktop-`$windowsVersion-`$windowsArchitecture-international-dch-whql.exe"
    `$rp_url = "https://international.download.nvidia.com/Windows/`$version/`$version-desktop-`$windowsVersion-`$windowsArchitecture-international-dch-whql-rp.exe"

    # Downloading the installer
    `$dlFile = "`$nvidiaTempFolder\`$version.exe"
    Start-BitsTransfer -Source `$url -Destination `$dlFile
    if (`$?) {
        Write-Host "Proceed..."
    }
    else {
        Write-Host "Download failed, trying alternative RP package now..."
        Start-BitsTransfer -Source `$rp_url -Destination `$dlFile
    }

    # Extracting setup files
    `$extractFolder = "`$nvidiaTempFolder\`$version"
    `$filesToExtract = "Display.Driver HDAudio NVI2 PhysX EULA.txt ListDevices.txt setup.cfg setup.exe"
    if (`$7zipinstalled) {
        Start-Process -FilePath `$archiverProgram -NoNewWindow -ArgumentList "x -bso0 -bsp1 -bse1 -aoa `$dlFile `$filesToExtract -o""`$extractFolder""" -wait
    }
    elseif (`$archiverProgram -eq `$winrarpath) {
        Start-Process -FilePath `$archiverProgram -NoNewWindow -ArgumentList 'x `$dlFile `$extractFolder -IBCK `$filesToExtract' -wait
    }
    else {
        # exit 0
    }

    # Remove unneeded dependencies from setup.cfg
(Get-Content "`$extractFolder\setup.cfg") | Where-Object { `$_ -notmatch 'name="\`${{(EulaHtmlFile|FunctionalConsentFile|PrivacyPolicyFile)}}' } | Set-Content "`$extractFolder\setup.cfg" -Encoding UTF8 -Force

    # Installing drivers
    `$install_args = "-passive -noreboot -noeula -nofinish -s"
    if (`$clean) {
        `$install_args = `$install_args + " -clean"
    }
    Start-Process -FilePath "`$extractFolder\setup.exe" -ArgumentList `$install_args -wait
}
Remove-Item `$nvidiaTempFolder -Recurse -Force -ErrorAction SilentlyContinue
"@

New-Item -Path "C:\Windows\Utils" -Name NVIDIAUpdater.ps1 -ItemType File -Value $NVIDIAUpdatesScript -Force -ErrorAction SilentlyContinue
    
$Hours = 1, 2, 3, 4, 5, 5, 21, 22, 23 | Get-Random -Count 1
$Minutes = Get-Random -Minimum 00 -Maximum 59
$Time = Get-Date -Hour $Hours -Minute $Minutes -UFormat %r
$Trigger = (New-ScheduledTaskTrigger -Daily -At $Time)
$User = "NT AUTHORITY\SYSTEM"

$Action = (New-ScheduledTaskAction -Execute "POWERSHELL" -Argument '-ExecutionPolicy Bypass -File "C:\Windows\Utils\NVIDIAUpdater.ps1"')

$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "S5 - NVIDIA Driver Updater" -Trigger $Trigger -User $User -Action $Action -Settings $Settings -RunLevel Highest -Force -Description "This task updates the Nvidia Geforce software and drivers if installed. S5-JM last updated 5-3-23"

}

else {"NOT NVIDIA - No actions taken"}
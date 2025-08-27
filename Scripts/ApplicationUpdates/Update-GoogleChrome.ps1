#Requires -Version 5.1

<#
.SYNOPSIS
    Updates Google Chrome to the latest stable version.

.DESCRIPTION
    This script automatically downloads and installs the latest version of Google Chrome
    Enterprise MSI. It checks the current installed version against the latest available
    version and only updates if necessary.

.PARAMETER Force
    Force update even if Chrome is already up to date

.PARAMETER Silent
    Run installation silently without user interaction

.PARAMETER LogPath
    Custom path for log files (default: %TEMP%\PatchingLogs)

.PARAMETER DownloadPath
    Custom path for downloaded installer (default: %TEMP%\ChromeUpdate)

.EXAMPLE
    .\Update-GoogleChrome.ps1
    
.EXAMPLE
    .\Update-GoogleChrome.ps1 -Force -Silent

.NOTES
    Version: 2.0.0
    Author: Patching Scripts Collection
    Requires: PowerShell 5.1+, Internet connectivity
    
    This script downloads and installs the Google Chrome Enterprise MSI package.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$Silent,
    
    [Parameter()]
    [string]$LogPath,
    
    [Parameter()]
    [string]$DownloadPath
)

# Import required modules
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Modules"
Import-Module (Join-Path -Path $modulePath -ChildPath "Common\PatchingCommon.psm1") -Force
Import-Module (Join-Path -Path $modulePath -ChildPath "Logging\PatchingLogging.psm1") -Force

#region Script Initialization

# Initialize logging
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
if ($LogPath) {
    $logFile = Initialize-PatchingLog -ScriptName $scriptName -LogPath $LogPath
} else {
    $logFile = Initialize-PatchingLog -ScriptName $scriptName
}

Write-PatchingInfo "Starting Google Chrome update process" -WriteToHost

# Configure secure connection defaults
Set-SecureConnectionDefaults

# Set download path
if ([string]::IsNullOrEmpty($DownloadPath)) {
    $DownloadPath = Join-Path -Path $env:TEMP -ChildPath "ChromeUpdate"
}

if (-not (Test-Path -Path $DownloadPath)) {
    New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
    Write-PatchingInfo "Created download directory: $DownloadPath"
}

#endregion

#region Core Functions

<#
.SYNOPSIS
    Gets the latest available Chrome version from Google's API.
#>
function Get-LatestChromeVersion {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    $operation = Start-PatchingOperation -OperationName "Chrome Version Lookup"
    
    try {
        Write-PatchingInfo "Querying Google Chrome version API"
        
        $apiUrl = 'https://versionhistory.googleapis.com/v1/chrome/platforms/all/channels/all/versions/'
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -ErrorAction Stop
        
        $latestVersion = $response.Versions | 
                        Where-Object { $_.name -like 'chrome/platforms/win64/channels/stable/versions/*' } | 
                        Sort-Object -Descending | 
                        Select-Object -First 1 | 
                        Select-Object -ExpandProperty version
        
        if ([string]::IsNullOrEmpty($latestVersion)) {
            throw "Failed to retrieve latest Chrome version from API"
        }
        
        Write-PatchingInfo "Latest Chrome version: $latestVersion"
        Complete-PatchingOperation -OperationName "Chrome Version Lookup" -Stopwatch $operation -Success $true
        return $latestVersion
    }
    catch {
        Write-PatchingError "Failed to get latest Chrome version" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "Chrome Version Lookup" -Stopwatch $operation -Success $false
        return $null
    }
}

<#
.SYNOPSIS
    Gets all installed Chrome versions on the system.
#>
function Get-InstalledChromeVersions {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param()
    
    try {
        Write-PatchingInfo "Checking installed Chrome versions"
        
        $versions = @()
        
        # Check via WMI (Windows Installer)
        try {
            $wmiVersion = Get-CimInstance -ClassName Win32_Product -Filter "Name LIKE '%Chrome%'" -ErrorAction Stop |
                         Select-Object -ExpandProperty Version -First 1
            if ($wmiVersion) {
                $versions += [PSCustomObject]@{
                    Source = 'WMI'
                    Version = $wmiVersion
                    Path = 'Unknown'
                }
                Write-PatchingInfo "Chrome version from WMI: $wmiVersion"
            }
        }
        catch {
            Write-PatchingVerbose "Could not retrieve Chrome version from WMI: $($_.Exception.Message)"
        }
        
        # Check 64-bit installation
        $chrome64Path = Join-Path -Path ${env:ProgramFiles} -ChildPath "Google\Chrome\Application\chrome.exe"
        if (Test-Path -Path $chrome64Path) {
            try {
                $version64 = (Get-Item -Path $chrome64Path).VersionInfo.ProductVersion
                $versions += [PSCustomObject]@{
                    Source = 'File (64-bit)'
                    Version = $version64
                    Path = $chrome64Path
                }
                Write-PatchingInfo "Chrome 64-bit version: $version64"
            }
            catch {
                Write-PatchingVerbose "Could not get version from 64-bit Chrome executable: $($_.Exception.Message)"
            }
        }
        
        # Check 32-bit installation
        $chrome32Path = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Google\Chrome\Application\chrome.exe"
        if (Test-Path -Path $chrome32Path) {
            try {
                $version32 = (Get-Item -Path $chrome32Path).VersionInfo.ProductVersion
                $versions += [PSCustomObject]@{
                    Source = 'File (32-bit)'
                    Version = $version32
                    Path = $chrome32Path
                }
                Write-PatchingInfo "Chrome 32-bit version: $version32"
            }
            catch {
                Write-PatchingVerbose "Could not get version from 32-bit Chrome executable: $($_.Exception.Message)"
            }
        }
        
        if ($versions.Count -eq 0) {
            Write-PatchingInfo "No Chrome installations found"
        }
        
        return $versions
    }
    catch {
        Write-PatchingError "Error checking installed Chrome versions" -Exception $_.Exception
        return @()
    }
}

<#
.SYNOPSIS
    Downloads the Chrome Enterprise MSI installer.
#>
function Get-ChromeInstaller {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DownloadPath
    )
    
    $operation = Start-PatchingOperation -OperationName "Chrome Installer Download"
    
    try {
        $installerUrl = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'
        $installerPath = Join-Path -Path $DownloadPath -ChildPath "googlechromestandaloneenterprise64.msi"
        
        Write-PatchingInfo "Downloading Chrome installer from: $installerUrl"
        Write-PatchingInfo "Download destination: $installerPath"
        
        # Remove existing installer if present
        if (Test-Path -Path $installerPath) {
            Remove-Item -Path $installerPath -Force
            Write-PatchingInfo "Removed existing installer file"
        }
        
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
        
        # Unblock the downloaded file
        Unblock-File -Path $installerPath -ErrorAction SilentlyContinue
        
        if (Test-Path -Path $installerPath) {
            $fileSize = (Get-Item -Path $installerPath).Length
            Write-PatchingInfo "Chrome installer downloaded successfully ($([math]::Round($fileSize / 1MB, 2)) MB)"
            Complete-PatchingOperation -OperationName "Chrome Installer Download" -Stopwatch $operation -Success $true
            return $installerPath
        } else {
            throw "Downloaded installer file not found"
        }
    }
    catch {
        Write-PatchingError "Failed to download Chrome installer" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "Chrome Installer Download" -Stopwatch $operation -Success $false
        return $null
    }
}

<#
.SYNOPSIS
    Installs Chrome using the MSI installer.
#>
function Install-ChromeUpdate {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath,
        
        [Parameter()]
        [switch]$Silent
    )
    
    $operation = Start-PatchingOperation -OperationName "Chrome Installation"
    
    try {
        if (-not (Test-Path -Path $InstallerPath)) {
            throw "Installer file not found: $InstallerPath"
        }
        
        # Prepare installation arguments
        $arguments = @('/i', $InstallerPath)
        
        if ($Silent) {
            $arguments += @('/quiet', '/norestart')
        } else {
            $arguments += @('/passive', '/norestart')
        }
        
        # Add logging
        $logPath = Join-Path -Path $DownloadPath -ChildPath "ChromeInstall.log"
        $arguments += @("/L*V", $logPath)
        
        Write-PatchingInfo "Starting Chrome installation"
        Write-PatchingInfo "Installation mode: $(if ($Silent) {'Silent'} else {'Passive'})"
        Write-PatchingInfo "Installer: $InstallerPath"
        Write-PatchingInfo "Log file: $logPath"
        
        # Close Chrome processes before installation
        $chromeProcesses = Get-Process -Name 'chrome' -ErrorAction SilentlyContinue
        if ($chromeProcesses) {
            Write-PatchingInfo "Closing $($chromeProcesses.Count) Chrome processes"
            $chromeProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        
        # Run installer
        $result = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        
        if ($result.ExitCode -eq 0) {
            Write-PatchingInfo "Chrome installation completed successfully"
            Complete-PatchingOperation -OperationName "Chrome Installation" -Stopwatch $operation -Success $true
            return $true
        } else {
            Write-PatchingError "Chrome installation failed with exit code: $($result.ExitCode)"
            
            # Try to read installation log for more details
            if (Test-Path -Path $logPath) {
                try {
                    $logContent = Get-Content -Path $logPath -Tail 10 -ErrorAction SilentlyContinue
                    Write-PatchingInfo "Last 10 lines from installation log:"
                    $logContent | ForEach-Object { Write-PatchingInfo "  $_" }
                }
                catch {
                    Write-PatchingVerbose "Could not read installation log: $($_.Exception.Message)"
                }
            }
            
            Complete-PatchingOperation -OperationName "Chrome Installation" -Stopwatch $operation -Success $false
            return $false
        }
    }
    catch {
        Write-PatchingError "Error during Chrome installation" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "Chrome Installation" -Stopwatch $operation -Success $false
        return $false
    }
}

#endregion

#region Main Execution

try {
    # Get system information
    $systemInfo = Get-SystemInformation
    Write-PatchingInfo "System: $($systemInfo.ComputerName) - $($systemInfo.OSName)"
    
    # Get latest available version
    $latestVersion = Get-LatestChromeVersion
    if ([string]::IsNullOrEmpty($latestVersion)) {
        Write-PatchingError "Could not determine latest Chrome version" -WriteToHost
        Complete-PatchingLog -Success $false
        exit 1
    }
    
    # Get installed versions
    $installedVersions = Get-InstalledChromeVersions
    
    # Determine if update is needed
    $updateNeeded = $Force
    
    if (-not $Force) {
        if ($installedVersions.Count -eq 0) {
            Write-PatchingInfo "No Chrome installation found, proceeding with installation"
            $updateNeeded = $true
        } else {
            $versionsToUpdate = $installedVersions | Where-Object { 
                -not [string]::IsNullOrEmpty($_.Version) -and $_.Version -ne $latestVersion
            }
            
            if ($versionsToUpdate) {
                Write-PatchingInfo "Found Chrome versions that need updating:"
                foreach ($version in $versionsToUpdate) {
                    Write-PatchingInfo "  $($version.Source): $($version.Version) -> $latestVersion"
                }
                $updateNeeded = $true
            } else {
                Write-PatchingInfo "All installed Chrome versions are up to date ($latestVersion)"
                $updateNeeded = $false
            }
        }
    }
    
    if ($updateNeeded) {
        Write-PatchingInfo "Updating Chrome to version $latestVersion" -WriteToHost
        
        # Download installer
        $installerPath = Get-ChromeInstaller -DownloadPath $DownloadPath
        if ([string]::IsNullOrEmpty($installerPath)) {
            Write-PatchingError "Failed to download Chrome installer" -WriteToHost
            Complete-PatchingLog -Success $false
            exit 1
        }
        
        # Install Chrome
        $installSuccess = Install-ChromeUpdate -InstallerPath $installerPath -Silent:$Silent
        if (-not $installSuccess) {
            Write-PatchingError "Chrome installation failed" -WriteToHost
            Complete-PatchingLog -Success $false
            exit 1
        }
        
        # Verify installation
        Start-Sleep -Seconds 3
        $newVersions = Get-InstalledChromeVersions
        $updateSuccessful = $newVersions | Where-Object { $_.Version -eq $latestVersion }
        
        if ($updateSuccessful) {
            Write-PatchingInfo "Chrome update verification successful" -WriteToHost
            Write-PatchingInfo "Updated to version: $latestVersion" -WriteToHost
        } else {
            Write-PatchingWarning "Chrome update verification failed - version mismatch detected"
        }
        
        # Cleanup downloaded installer
        try {
            if (Test-Path -Path $installerPath) {
                Remove-Item -Path $installerPath -Force
                Write-PatchingInfo "Cleaned up installer file"
            }
        } catch {
            Write-PatchingVerbose "Could not remove installer file: $($_.Exception.Message)"
        }
        
    } else {
        Write-PatchingInfo "Chrome is already up to date (version $latestVersion)" -WriteToHost
    }
    
    Write-PatchingInfo "Chrome update process completed successfully" -WriteToHost
    Complete-PatchingLog -Success $true
    
} catch {
    Write-PatchingError "Critical error during Chrome update process" -Exception $_.Exception -WriteToHost
    Complete-PatchingLog -Success $false
    exit 1
}

#endregion
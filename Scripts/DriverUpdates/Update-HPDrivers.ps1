#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Downloads and installs the latest HP drivers using HP Image Assistant (HPIA).

.DESCRIPTION
    This script downloads and installs the latest matching drivers from HP repository
    using HP Image Assistant. It validates HP hardware, manages PowerShell modules,
    and provides comprehensive logging throughout the process.

.PARAMETER HPIAAction
    Specify the HP Image Assistant action to perform (Download or Install)

.PARAMETER WorkingDirectory
    Specify a custom working directory for HPIA operations

.PARAMETER LogPath
    Custom path for log files (default: %TEMP%\PatchingLogs)

.PARAMETER DownloadsOnly
    Only download drivers without installing them

.PARAMETER Force
    Force reinstallation of modules and tools

.EXAMPLE
    .\Update-HPDrivers.ps1
    
.EXAMPLE
    .\Update-HPDrivers.ps1 -HPIAAction Download -DownloadsOnly

.EXAMPLE
    .\Update-HPDrivers.ps1 -WorkingDirectory "C:\HPDrivers" -Force

.NOTES
    Version: 2.0.0
    Author: Patching Scripts Collection
    Requires: PowerShell 5.1+, Administrative privileges, HP hardware
    
    This script requires HP hardware and installs the HP Client Management Script Library (HPCMSL).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet("Download", "Install")]
    [string]$HPIAAction = "Install",
    
    [Parameter()]
    [string]$WorkingDirectory,
    
    [Parameter()]
    [string]$LogPath,
    
    [Parameter()]
    [switch]$DownloadsOnly,
    
    [Parameter()]
    [switch]$Force
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

Write-PatchingInfo "Starting HP driver update process" -WriteToHost

# Verify administrator privileges
if (-not (Test-IsAdministrator)) {
    Write-PatchingError "This script requires administrative privileges" -WriteToHost
    Complete-PatchingLog -Success $false
    exit 1
}

# Configure secure connection defaults
Set-SecureConnectionDefaults

# Validate HP hardware
$systemInfo = Get-SystemInformation
Write-PatchingInfo "System: $($systemInfo.ComputerName) - $($systemInfo.Manufacturer) $($systemInfo.Model)"

if (-not (Test-SystemManufacturer -Manufacturer "HP") -and -not (Test-SystemManufacturer -Manufacturer "Hewlett-Packard")) {
    Write-PatchingError "This script requires HP hardware. Detected manufacturer: $($systemInfo.Manufacturer)" -WriteToHost
    Complete-PatchingLog -Success $false
    exit 1
}

Write-PatchingInfo "HP hardware validated successfully"

# Set working directory
if ([string]::IsNullOrEmpty($WorkingDirectory)) {
    $WorkingDirectory = Join-Path -Path $env:TEMP -ChildPath "HPDriverUpdate"
}

if (-not (Test-Path -Path $WorkingDirectory)) {
    New-Item -Path $WorkingDirectory -ItemType Directory -Force | Out-Null
    Write-PatchingInfo "Created working directory: $WorkingDirectory"
}

#endregion

#region PowerShell Module Management

<#
.SYNOPSIS
    Ensures required PowerShell modules are installed and up to date.
#>
function Initialize-PowerShellModules {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    $operation = Start-PatchingOperation -OperationName "PowerShell Module Initialization"
    
    try {
        Write-PatchingInfo "Initializing PowerShell modules and package providers"
        
        # Install latest NuGet package provider
        Write-PatchingInfo "Installing NuGet package provider"
        try {
            Install-PackageProvider -Name "NuGet" -Force -Scope AllUsers -ErrorAction Stop
            Write-PatchingInfo "NuGet package provider installed successfully"
        }
        catch {
            Write-PatchingWarning "Failed to install NuGet package provider: $($_.Exception.Message)"
        }
        
        # Ensure PSGallery is trusted
        try {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
            Write-PatchingInfo "PSGallery repository set as trusted"
        }
        catch {
            Write-PatchingWarning "Failed to set PSGallery as trusted: $($_.Exception.Message)"
        }
        
        # Update PowerShellGet if needed
        $powerShellGetInstalled = Get-Module -ListAvailable -Name "PowerShellGet" | Sort-Object Version -Descending | Select-Object -First 1
        
        if ($powerShellGetInstalled) {
            Write-PatchingInfo "PowerShellGet version $($powerShellGetInstalled.Version) is installed"
            
            try {
                $powerShellGetLatest = Find-Module -Name "PowerShellGet" -ErrorAction Stop
                
                if ($powerShellGetInstalled.Version -lt $powerShellGetLatest.Version) {
                    Write-PatchingInfo "Updating PowerShellGet from $($powerShellGetInstalled.Version) to $($powerShellGetLatest.Version)"
                    Update-Module -Name "PowerShellGet" -Scope AllUsers -Force -ErrorAction Stop
                    Write-PatchingInfo "PowerShellGet updated successfully"
                }
            }
            catch {
                Write-PatchingWarning "Failed to update PowerShellGet: $($_.Exception.Message)"
            }
        }
        else {
            Write-PatchingInfo "PowerShellGet not found, installing from repository"
            try {
                Install-Module -Name "PackageManagement" -Force -Scope AllUsers -AllowClobber -ErrorAction Stop
                Install-Module -Name "PowerShellGet" -Force -Scope AllUsers -AllowClobber -ErrorAction Stop
                Write-PatchingInfo "PowerShellGet installed successfully"
            }
            catch {
                Write-PatchingError "Failed to install PowerShellGet: $($_.Exception.Message)"
                Complete-PatchingOperation -OperationName "PowerShell Module Initialization" -Stopwatch $operation -Success $false
                return $false
            }
        }
        
        Complete-PatchingOperation -OperationName "PowerShell Module Initialization" -Stopwatch $operation -Success $true
        return $true
    }
    catch {
        Write-PatchingError "Error initializing PowerShell modules" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "PowerShell Module Initialization" -Stopwatch $operation -Success $false
        return $false
    }
}

<#
.SYNOPSIS
    Installs or updates the HP Client Management Script Library (HPCMSL).
#>
function Initialize-HPCMSLModule {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    $operation = Start-PatchingOperation -OperationName "HPCMSL Module Installation"
    
    try {
        Write-PatchingInfo "Installing HP Client Management Script Library (HPCMSL)"
        
        # Check if HPCMSL is already installed
        $hpcmslInstalled = Get-Module -ListAvailable -Name "HPCMSL" | Sort-Object Version -Descending | Select-Object -First 1
        
        if ($hpcmslInstalled -and -not $Force) {
            Write-PatchingInfo "HPCMSL version $($hpcmslInstalled.Version) is already installed"
            
            # Try to update if newer version available
            try {
                $hpcmslLatest = Find-Module -Name "HPCMSL" -ErrorAction Stop
                if ($hpcmslInstalled.Version -lt $hpcmslLatest.Version) {
                    Write-PatchingInfo "Updating HPCMSL from $($hpcmslInstalled.Version) to $($hpcmslLatest.Version)"
                    Update-Module -Name "HPCMSL" -Scope AllUsers -Force -ErrorAction Stop
                    Write-PatchingInfo "HPCMSL updated successfully"
                }
            }
            catch {
                Write-PatchingVerbose "Could not check for HPCMSL updates: $($_.Exception.Message)"
            }
        }
        else {
            Write-PatchingInfo "Installing HPCMSL module from PowerShell Gallery"
            Install-Module -Name "HPCMSL" -AcceptLicense -Force -Scope AllUsers -ErrorAction Stop
            Write-PatchingInfo "HPCMSL module installed successfully"
        }
        
        # Import the module
        Import-Module -Name "HPCMSL" -Force -ErrorAction Stop
        Write-PatchingInfo "HPCMSL module imported successfully"
        
        Complete-PatchingOperation -OperationName "HPCMSL Module Installation" -Stopwatch $operation -Success $true
        return $true
    }
    catch {
        Write-PatchingError "Failed to install HPCMSL module" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "HPCMSL Module Installation" -Stopwatch $operation -Success $false
        return $false
    }
}

#endregion

#region HP Image Assistant Functions

<#
.SYNOPSIS
    Downloads and extracts HP Image Assistant.
#>
function Initialize-HPImageAssistant {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )
    
    $operation = Start-PatchingOperation -OperationName "HP Image Assistant Setup"
    
    try {
        $hpiaDirectory = Join-Path -Path $WorkingDirectory -ChildPath "HPIA"
        $hpiaExecutable = Join-Path -Path $hpiaDirectory -ChildPath "HPImageAssistant.exe"
        
        # Check if HPIA is already present
        if ((Test-Path -Path $hpiaExecutable) -and -not $Force) {
            Write-PatchingInfo "HP Image Assistant already exists at: $hpiaExecutable"
            Complete-PatchingOperation -OperationName "HP Image Assistant Setup" -Stopwatch $operation -Success $true
            return $hpiaExecutable
        }
        
        Write-PatchingInfo "Downloading and extracting HP Image Assistant"
        
        # Create HPIA directory
        if (-not (Test-Path -Path $hpiaDirectory)) {
            New-Item -Path $hpiaDirectory -ItemType Directory -Force | Out-Null
        }
        
        # Download HPIA using HPCMSL
        try {
            Get-HPImageAssistant -Extract -Destination $hpiaDirectory -ErrorAction Stop
            Write-PatchingInfo "HP Image Assistant downloaded and extracted successfully"
        }
        catch {
            Write-PatchingError "Failed to download HP Image Assistant using HPCMSL: $($_.Exception.Message)"
            
            # Fallback: try manual download
            Write-PatchingInfo "Attempting manual download of HP Image Assistant"
            $hpiaUrl = "https://ftp.hp.com/pub/caps-softpaq/cmit/HPIA.exe"
            $hpiaDownloadPath = Join-Path -Path $WorkingDirectory -ChildPath "HPIA.exe"
            
            try {
                Invoke-WebRequest -Uri $hpiaUrl -OutFile $hpiaDownloadPath -UseBasicParsing -ErrorAction Stop
                
                # Extract HPIA
                $extractArgs = @("/s", "/e", "/f", $hpiaDirectory)
                $extractResult = Start-Process -FilePath $hpiaDownloadPath -ArgumentList $extractArgs -Wait -PassThru -NoNewWindow
                
                if ($extractResult.ExitCode -eq 0) {
                    Write-PatchingInfo "HP Image Assistant extracted successfully (manual method)"
                    Remove-Item -Path $hpiaDownloadPath -Force -ErrorAction SilentlyContinue
                }
                else {
                    throw "Extraction failed with exit code: $($extractResult.ExitCode)"
                }
            }
            catch {
                Write-PatchingError "Manual download also failed: $($_.Exception.Message)"
                Complete-PatchingOperation -OperationName "HP Image Assistant Setup" -Stopwatch $operation -Success $false
                return $null
            }
        }
        
        # Verify HPIA executable exists
        if (Test-Path -Path $hpiaExecutable) {
            Write-PatchingInfo "HP Image Assistant ready at: $hpiaExecutable"
            Complete-PatchingOperation -OperationName "HP Image Assistant Setup" -Stopwatch $operation -Success $true
            return $hpiaExecutable
        }
        else {
            Write-PatchingError "HP Image Assistant executable not found after extraction"
            Complete-PatchingOperation -OperationName "HP Image Assistant Setup" -Stopwatch $operation -Success $false
            return $null
        }
    }
    catch {
        Write-PatchingError "Error setting up HP Image Assistant" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "HP Image Assistant Setup" -Stopwatch $operation -Success $false
        return $null
    }
}

<#
.SYNOPSIS
    Runs HP Image Assistant to analyze and update drivers.
#>
function Invoke-HPDriverAnalysis {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$HPIAExecutable,
        
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,
        
        [Parameter()]
        [string]$Action = "Install",
        
        [Parameter()]
        [switch]$DownloadsOnly
    )
    
    $operation = Start-PatchingOperation -OperationName "HP Driver Analysis and Update"
    
    try {
        $reportPath = Join-Path -Path $WorkingDirectory -ChildPath "HPIAReport.xml"
        $downloadPath = Join-Path -Path $WorkingDirectory -ChildPath "Downloads"
        
        # Create downloads directory
        if (-not (Test-Path -Path $downloadPath)) {
            New-Item -Path $downloadPath -ItemType Directory -Force | Out-Null
        }
        
        # Build HPIA arguments
        $arguments = @(
            "/Operation:Analyze",
            "/Category:Drivers",
            "/Selection:All",
            "/Action:$Action",
            "/Silent",
            "/ReportFolder:$WorkingDirectory",
            "/DownloadFolder:$downloadPath"
        )
        
        if ($DownloadsOnly) {
            $arguments = $arguments -replace "/Action:$Action", "/Action:Download"
        }
        
        Write-PatchingInfo "Running HP Image Assistant with action: $(if ($DownloadsOnly) {'Download'} else {$Action})"
        Write-PatchingInfo "HPIA Command: $HPIAExecutable $($arguments -join ' ')"
        Write-PatchingInfo "Report path: $reportPath"
        Write-PatchingInfo "Download path: $downloadPath"
        
        # Run HPIA
        $result = Start-Process -FilePath $HPIAExecutable -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        
        Write-PatchingInfo "HP Image Assistant completed with exit code: $($result.ExitCode)"
        
        # Parse results
        if (Test-Path -Path $reportPath) {
            try {
                [xml]$report = Get-Content -Path $reportPath -ErrorAction Stop
                
                $totalRecommendations = $report.SelectNodes("//Recommendation").Count
                $criticalUpdates = $report.SelectNodes("//Recommendation[@Criticality='Critical']").Count
                $recommendedUpdates = $report.SelectNodes("//Recommendation[@Criticality='Recommended']").Count
                $routineUpdates = $report.SelectNodes("//Recommendation[@Criticality='Routine']").Count
                
                Write-PatchingInfo "HP Driver Analysis Results:"
                Write-PatchingInfo "  Total recommendations: $totalRecommendations"
                Write-PatchingInfo "  Critical updates: $criticalUpdates"
                Write-PatchingInfo "  Recommended updates: $recommendedUpdates"
                Write-PatchingInfo "  Routine updates: $routineUpdates"
                
                if ($totalRecommendations -gt 0) {
                    Write-PatchingInfo "Driver updates were $(if ($DownloadsOnly) {'downloaded'} else {'processed'}) successfully"
                }
                else {
                    Write-PatchingInfo "No driver updates needed - system is up to date"
                }
            }
            catch {
                Write-PatchingWarning "Could not parse HPIA report: $($_.Exception.Message)"
            }
        }
        else {
            Write-PatchingWarning "HPIA report file not found: $reportPath"
        }
        
        # Check for downloaded files
        if (Test-Path -Path $downloadPath) {
            $downloadedFiles = Get-ChildItem -Path $downloadPath -Recurse -File
            if ($downloadedFiles) {
                Write-PatchingInfo "Downloaded $($downloadedFiles.Count) driver files"
                $totalSize = ($downloadedFiles | Measure-Object -Property Length -Sum).Sum
                Write-PatchingInfo "Total download size: $([math]::Round($totalSize / 1MB, 2)) MB"
            }
        }
        
        # Determine success based on exit code
        $success = $result.ExitCode -eq 0 -or $result.ExitCode -eq 3010 -or $result.ExitCode -eq 3
        
        if ($success) {
            Write-PatchingInfo "HP driver update process completed successfully"
            Complete-PatchingOperation -OperationName "HP Driver Analysis and Update" -Stopwatch $operation -Success $true
        }
        else {
            Write-PatchingWarning "HP driver update process completed with warnings (exit code: $($result.ExitCode))"
            Complete-PatchingOperation -OperationName "HP Driver Analysis and Update" -Stopwatch $operation -Success $false
        }
        
        return $success
    }
    catch {
        Write-PatchingError "Error during HP driver analysis" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "HP Driver Analysis and Update" -Stopwatch $operation -Success $false
        return $false
    }
}

#endregion

#region Main Execution

try {
    Write-PatchingInfo "HP Driver Update Configuration:"
    Write-PatchingInfo "  Action: $HPIAAction"
    Write-PatchingInfo "  Working Directory: $WorkingDirectory"
    Write-PatchingInfo "  Downloads Only: $DownloadsOnly"
    Write-PatchingInfo "  Force Reinstall: $Force"
    
    # Step 1: Initialize PowerShell modules
    $modulesReady = Initialize-PowerShellModules
    if (-not $modulesReady) {
        Write-PatchingError "Failed to initialize PowerShell modules" -WriteToHost
        Complete-PatchingLog -Success $false
        exit 1
    }
    
    # Step 2: Install HPCMSL module
    $hpcmslReady = Initialize-HPCMSLModule
    if (-not $hpcmslReady) {
        Write-PatchingError "Failed to initialize HPCMSL module" -WriteToHost
        Complete-PatchingLog -Success $false
        exit 1
    }
    
    # Step 3: Setup HP Image Assistant
    $hpiaPath = Initialize-HPImageAssistant -WorkingDirectory $WorkingDirectory
    if ([string]::IsNullOrEmpty($hpiaPath)) {
        Write-PatchingError "Failed to setup HP Image Assistant" -WriteToHost
        Complete-PatchingLog -Success $false
        exit 1
    }
    
    # Step 4: Run driver analysis and updates
    $updateSuccess = Invoke-HPDriverAnalysis -HPIAExecutable $hpiaPath -WorkingDirectory $WorkingDirectory -Action $HPIAAction -DownloadsOnly:$DownloadsOnly
    
    if ($updateSuccess) {
        Write-PatchingInfo "HP driver update process completed successfully" -WriteToHost
        
        # Check if reboot is recommended
        if (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
            Write-PatchingInfo "System reboot is recommended to complete driver installation" -WriteToHost
        }
        
        Complete-PatchingLog -Success $true
    }
    else {
        Write-PatchingWarning "HP driver update process completed with warnings" -WriteToHost
        Complete-PatchingLog -Success $false
        exit 1
    }
    
} catch {
    Write-PatchingError "Critical error during HP driver update process" -Exception $_.Exception -WriteToHost
    Complete-PatchingLog -Success $false
    exit 1
}

#endregion
#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Comprehensive Windows system patching and repair script.

.DESCRIPTION
    This script performs comprehensive system maintenance including:
    - Windows updates installation
    - Application updates via WinGet
    - System file checking and repair
    - Windows Update cache cleanup
    - Lenovo driver updates (if applicable)
    - Bloatware removal
    - Office updates
    - Microsoft Store app updates

.PARAMETER IncludeDriverUpdates
    Include Lenovo driver updates using LSUClient module

.PARAMETER IncludeBloatwareRemoval
    Remove specified bloatware applications

.PARAMETER IncludeOfficeUpdates
    Update Microsoft Office applications

.PARAMETER IncludeStoreAppUpdates
    Update Microsoft Store applications

.PARAMETER LogPath
    Custom path for log files (default: %TEMP%\PatchingLogs)

.EXAMPLE
    .\Invoke-SystemMaintenanceAndPatching.ps1
    
.EXAMPLE
    .\Invoke-SystemMaintenanceAndPatching.ps1 -IncludeDriverUpdates -IncludeBloatwareRemoval

.NOTES
    Version: 2.0.0
    Author: Patching Scripts Collection
    Requires: PowerShell 5.1+, Administrative privileges
    
    This script must be run as Administrator for proper functionality.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$IncludeDriverUpdates,
    
    [Parameter()]
    [switch]$IncludeBloatwareRemoval,
    
    [Parameter()]
    [switch]$IncludeOfficeUpdates,
    
    [Parameter()]
    [switch]$IncludeStoreAppUpdates,
    
    [Parameter()]
    [string]$LogPath
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

Write-PatchingInfo "Starting comprehensive system maintenance and patching" -WriteToHost

# Verify administrator privileges
if (-not (Test-IsAdministrator)) {
    Write-PatchingError "This script requires administrative privileges" -WriteToHost
    Complete-PatchingLog -Success $false
    exit 1
}

# Configure secure connection defaults
Set-SecureConnectionDefaults

# Set PowerShell Gallery as trusted
try {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
    Write-PatchingInfo "PowerShell Gallery set as trusted repository"
} catch {
    Write-PatchingWarning "Failed to set PowerShell Gallery as trusted: $($_.Exception.Message)"
}

#endregion

#region Core Functions

<#
.SYNOPSIS
    Ensures WinGet is available and properly configured.
#>
function Initialize-WinGet {
    [CmdletBinding()]
    param()
    
    $operation = Start-PatchingOperation -OperationName "WinGet Initialization"
    
    try {
        # Try to find existing WinGet installation
        $wingetPath = Get-ChildItem -Recurse -Path "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller*" -Filter "winget.exe" -ErrorAction SilentlyContinue |
                     Sort-Object LastWriteTime -Descending | 
                     Select-Object -First 1
        
        if ($null -eq $wingetPath) {
            Write-PatchingInfo "WinGet not found, attempting to install"
            
            # Install WinGet using the winget-install script
            Install-Script -Name winget-install -Force -Scope AllUsers
            & winget-install
            
            # Try to find WinGet again
            $wingetPath = Get-ChildItem -Recurse -Path "$env:ProgramFiles\WindowsApps\Microsoft.DesktopAppInstaller*" -Filter "winget.exe" -ErrorAction SilentlyContinue |
                         Sort-Object LastWriteTime -Descending | 
                         Select-Object -First 1
        }
        
        if ($wingetPath) {
            $script:WinGetPath = $wingetPath.FullName
            Write-PatchingInfo "WinGet found at: $script:WinGetPath"
            Complete-PatchingOperation -OperationName "WinGet Initialization" -Stopwatch $operation -Success $true
            return $true
        } else {
            Write-PatchingError "Failed to locate or install WinGet"
            Complete-PatchingOperation -OperationName "WinGet Initialization" -Stopwatch $operation -Success $false
            return $false
        }
    } catch {
        Write-PatchingError "Error initializing WinGet" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "WinGet Initialization" -Stopwatch $operation -Success $false
        return $false
    }
}

<#
.SYNOPSIS
    Updates all applications using WinGet.
#>
function Update-ApplicationsWithWinGet {
    [CmdletBinding()]
    param()
    
    $operation = Start-PatchingOperation -OperationName "WinGet Application Updates"
    
    try {
        if (-not $script:WinGetPath) {
            Write-PatchingWarning "WinGet not available, skipping application updates"
            Complete-PatchingOperation -OperationName "WinGet Application Updates" -Stopwatch $operation -Success $false
            return
        }
        
        Write-PatchingInfo "Updating all applications using WinGet"
        
        $arguments = @(
            'upgrade',
            '--all',
            '--silent',
            '--accept-source-agreements',
            '--accept-package-agreements'
        )
        
        $result = Start-Process -FilePath $script:WinGetPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        
        if ($result.ExitCode -eq 0) {
            Write-PatchingInfo "WinGet application updates completed successfully"
            Complete-PatchingOperation -OperationName "WinGet Application Updates" -Stopwatch $operation -Success $true
        } else {
            Write-PatchingWarning "WinGet updates completed with exit code: $($result.ExitCode)"
            Complete-PatchingOperation -OperationName "WinGet Application Updates" -Stopwatch $operation -Success $false
        }
    } catch {
        Write-PatchingError "Error updating applications with WinGet" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "WinGet Application Updates" -Stopwatch $operation -Success $false
    }
}

<#
.SYNOPSIS
    Resets Windows Update components to resolve update issues.
#>
function Reset-WindowsUpdateComponents {
    [CmdletBinding()]
    param()
    
    $operation = Start-PatchingOperation -OperationName "Windows Update Components Reset"
    
    try {
        Write-PatchingInfo "Resetting Windows Update components"
        
        # Stop Windows Update services
        $services = @('wuauserv', 'bits', 'cryptsvc')
        foreach ($service in $services) {
            try {
                Stop-Service -Name $service -Force -ErrorAction Stop
                Write-PatchingInfo "Stopped service: $service"
            } catch {
                Write-PatchingWarning "Failed to stop service $service`: $($_.Exception.Message)"
            }
        }
        
        # Backup and clear SoftwareDistribution folder
        $softwareDistPath = Join-Path -Path $env:SystemRoot -ChildPath 'SoftwareDistribution'
        $backupPath = "$softwareDistPath.bak"
        
        if (Test-Path -Path $backupPath) {
            Remove-Item -Path $backupPath -Recurse -Force
            Write-PatchingInfo "Removed existing backup: $backupPath"
        }
        
        if (Test-Path -Path $softwareDistPath) {
            Rename-Item -Path $softwareDistPath -NewName 'SoftwareDistribution.bak' -Force
            Write-PatchingInfo "Backed up SoftwareDistribution folder"
        }
        
        # Backup and clear catroot2 folder
        $catroot2Path = Join-Path -Path $env:SystemRoot -ChildPath 'System32\catroot2'
        $catroot2BackupPath = "$catroot2Path.old"
        
        if (-not (Test-Path -Path $catroot2BackupPath)) {
            New-Item -ItemType Directory -Path $catroot2BackupPath -Force | Out-Null
        }
        
        if (Test-Path -Path $catroot2Path) {
            Copy-Item -Path $catroot2Path -Destination $catroot2BackupPath -Recurse -Force
            Write-PatchingInfo "Backed up catroot2 folder"
        }
        
        # Restart services
        foreach ($service in $services) {
            try {
                Start-Service -Name $service -ErrorAction Stop
                Write-PatchingInfo "Started service: $service"
            } catch {
                Write-PatchingWarning "Failed to start service $service`: $($_.Exception.Message)"
            }
        }
        
        Complete-PatchingOperation -OperationName "Windows Update Components Reset" -Stopwatch $operation -Success $true
    } catch {
        Write-PatchingError "Error resetting Windows Update components" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "Windows Update Components Reset" -Stopwatch $operation -Success $false
    }
}

<#
.SYNOPSIS
    Runs system file checker and DISM repair operations.
#>
function Repair-SystemFiles {
    [CmdletBinding()]
    param()
    
    $operation = Start-PatchingOperation -OperationName "System File Repair"
    
    try {
        Write-PatchingInfo "Running System File Checker (SFC /scannow)"
        $sfcResult = Start-Process -FilePath 'sfc.exe' -ArgumentList '/scannow' -Wait -PassThru -NoNewWindow
        
        if ($sfcResult.ExitCode -eq 0) {
            Write-PatchingInfo "SFC scan completed successfully"
        } else {
            Write-PatchingWarning "SFC scan completed with exit code: $($sfcResult.ExitCode)"
        }
        
        Write-PatchingInfo "Running DISM image repair"
        $dismResult = Start-Process -FilePath 'DISM.exe' -ArgumentList '/Online', '/Cleanup-Image', '/RestoreHealth' -Wait -PassThru -NoNewWindow
        
        if ($dismResult.ExitCode -eq 0) {
            Write-PatchingInfo "DISM repair completed successfully"
            Complete-PatchingOperation -OperationName "System File Repair" -Stopwatch $operation -Success $true
        } else {
            Write-PatchingWarning "DISM repair completed with exit code: $($dismResult.ExitCode)"
            Complete-PatchingOperation -OperationName "System File Repair" -Stopwatch $operation -Success $false
        }
    } catch {
        Write-PatchingError "Error during system file repair" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "System File Repair" -Stopwatch $operation -Success $false
    }
}

<#
.SYNOPSIS
    Updates Lenovo drivers using LSUClient module if on Lenovo hardware.
#>
function Update-LenovoDrivers {
    [CmdletBinding()]
    param()
    
    if (-not $IncludeDriverUpdates) {
        Write-PatchingInfo "Driver updates skipped (not requested)"
        return
    }
    
    $operation = Start-PatchingOperation -OperationName "Lenovo Driver Updates"
    
    try {
        # Check if this is Lenovo hardware
        if (-not (Test-SystemManufacturer -Manufacturer "Lenovo")) {
            Write-PatchingInfo "Non-Lenovo hardware detected, skipping Lenovo driver updates"
            Complete-PatchingOperation -OperationName "Lenovo Driver Updates" -Stopwatch $operation -Success $true
            return
        }
        
        Write-PatchingInfo "Lenovo hardware detected, installing LSUClient module"
        
        # Install and import LSUClient module
        if (-not (Get-Module -ListAvailable -Name 'LSUClient')) {
            Install-Module -Name 'LSUClient' -Scope AllUsers -Force
            Write-PatchingInfo "LSUClient module installed"
        }
        
        Import-Module -Name 'LSUClient' -Force
        Write-PatchingInfo "LSUClient module imported"
        
        # Get available updates
        $updates = Get-LSUpdate -All | Where-Object { $_.IsApplicable -eq 'True' -and $_.IsInstalled -eq 'False' }
        
        if ($updates) {
            Write-PatchingInfo "Found $($updates.Count) Lenovo updates available"
            
            # Save and install updates
            $updates | Save-LSUpdate -Verbose
            $updates | Install-LSUpdate -Verbose
            
            Write-PatchingInfo "Lenovo driver updates installation completed"
            Complete-PatchingOperation -OperationName "Lenovo Driver Updates" -Stopwatch $operation -Success $true
        } else {
            Write-PatchingInfo "No Lenovo updates available"
            Complete-PatchingOperation -OperationName "Lenovo Driver Updates" -Stopwatch $operation -Success $true
        }
    } catch {
        Write-PatchingError "Error updating Lenovo drivers" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "Lenovo Driver Updates" -Stopwatch $operation -Success $false
    }
}

<#
.SYNOPSIS
    Removes specified bloatware applications.
#>
function Remove-BloatwareApplications {
    [CmdletBinding()]
    param()
    
    if (-not $IncludeBloatwareRemoval) {
        Write-PatchingInfo "Bloatware removal skipped (not requested)"
        return
    }
    
    $operation = Start-PatchingOperation -OperationName "Bloatware Removal"
    
    try {
        # Applications to remove (can be customized)
        $appsToRemove = @(
            'Teams Machine-Wide Installer',
            'McAfee',
            'Microsoft.OutlookForWindows'
        )
        
        Write-PatchingInfo "Removing bloatware applications using WinGet"
        
        foreach ($appName in $appsToRemove) {
            try {
                if ($script:WinGetPath) {
                    Write-PatchingInfo "Attempting to uninstall: $appName"
                    $result = Start-Process -FilePath $script:WinGetPath -ArgumentList 'uninstall', $appName, '--silent' -Wait -PassThru -NoNewWindow
                    
                    if ($result.ExitCode -eq 0) {
                        Write-PatchingInfo "Successfully uninstalled: $appName"
                    } else {
                        Write-PatchingWarning "Failed to uninstall $appName (exit code: $($result.ExitCode))"
                    }
                } else {
                    Write-PatchingWarning "WinGet not available, skipping $appName"
                }
            } catch {
                Write-PatchingWarning "Error uninstalling $appName`: $($_.Exception.Message)"
            }
        }
        
        Complete-PatchingOperation -OperationName "Bloatware Removal" -Stopwatch $operation -Success $true
    } catch {
        Write-PatchingError "Error during bloatware removal" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "Bloatware Removal" -Stopwatch $operation -Success $false
    }
}

<#
.SYNOPSIS
    Updates Microsoft Office applications.
#>
function Update-OfficeApplications {
    [CmdletBinding()]
    param()
    
    if (-not $IncludeOfficeUpdates) {
        Write-PatchingInfo "Office updates skipped (not requested)"
        return
    }
    
    $operation = Start-PatchingOperation -OperationName "Office Updates"
    
    try {
        $officeC2RPath = Join-Path -Path ${env:ProgramFiles} -ChildPath "Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
        
        if (Test-Path -Path $officeC2RPath) {
            Write-PatchingInfo "Updating Microsoft Office applications"
            
            $arguments = @(
                '/update',
                'user',
                'displaylevel=false',
                'forceappshutdown=true',
                'updatepromptuser=false'
            )
            
            $result = Start-Process -FilePath $officeC2RPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
            
            if ($result.ExitCode -eq 0) {
                Write-PatchingInfo "Office updates completed successfully"
                Complete-PatchingOperation -OperationName "Office Updates" -Stopwatch $operation -Success $true
            } else {
                Write-PatchingWarning "Office updates completed with exit code: $($result.ExitCode)"
                Complete-PatchingOperation -OperationName "Office Updates" -Stopwatch $operation -Success $false
            }
        } else {
            Write-PatchingInfo "Microsoft Office Click-to-Run not found, skipping Office updates"
            Complete-PatchingOperation -OperationName "Office Updates" -Stopwatch $operation -Success $true
        }
    } catch {
        Write-PatchingError "Error updating Office applications" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "Office Updates" -Stopwatch $operation -Success $false
    }
}

<#
.SYNOPSIS
    Updates Microsoft Store applications.
#>
function Update-StoreApplications {
    [CmdletBinding()]
    param()
    
    if (-not $IncludeStoreAppUpdates) {
        Write-PatchingInfo "Store app updates skipped (not requested)"
        return
    }
    
    $operation = Start-PatchingOperation -OperationName "Microsoft Store App Updates"
    
    try {
        Write-PatchingInfo "Triggering Microsoft Store app updates"
        
        $namespaceName = 'root\cimv2\mdm\dmmap'
        $className = 'MDM_EnterpriseModernAppManagement_AppManagement01'
        
        $wmiObj = Get-CimInstance -Namespace $namespaceName -ClassName $className -ErrorAction Stop
        $result = Invoke-CimMethod -CimInstance $wmiObj -MethodName 'UpdateScanMethod'
        
        Write-PatchingInfo "Store app update scan initiated. Result: $($result.ReturnValue)"
        Complete-PatchingOperation -OperationName "Microsoft Store App Updates" -Stopwatch $operation -Success $true
    } catch {
        Write-PatchingError "Error updating Store applications" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "Microsoft Store App Updates" -Stopwatch $operation -Success $false
    }
}

<#
.SYNOPSIS
    Installs Windows updates using PSWindowsUpdate module.
#>
function Install-WindowsUpdates {
    [CmdletBinding()]
    param()
    
    $operation = Start-PatchingOperation -OperationName "Windows Updates Installation"
    
    try {
        Write-PatchingInfo "Installing PSWindowsUpdate module"
        
        if (-not (Get-Module -ListAvailable -Name 'PSWindowsUpdate')) {
            Install-Module -Name 'PSWindowsUpdate' -Scope AllUsers -Force
            Write-PatchingInfo "PSWindowsUpdate module installed"
        }
        
        Import-Module -Name 'PSWindowsUpdate' -Force
        Write-PatchingInfo "PSWindowsUpdate module imported"
        
        Write-PatchingInfo "Installing available Windows updates"
        Install-WindowsUpdate -AcceptAll -Install -IgnoreReboot
        
        Write-PatchingInfo "Windows updates installation completed"
        Complete-PatchingOperation -OperationName "Windows Updates Installation" -Stopwatch $operation -Success $true
    } catch {
        Write-PatchingError "Error installing Windows updates" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "Windows Updates Installation" -Stopwatch $operation -Success $false
    }
}

#endregion

#region Main Execution

try {
    Write-PatchingInfo "System Information:" -WriteToHost
    $systemInfo = Get-SystemInformation
    Write-PatchingInfo "Computer: $($systemInfo.ComputerName)" -WriteToHost
    Write-PatchingInfo "OS: $($systemInfo.OSName) (Build $($systemInfo.OSBuild))" -WriteToHost
    Write-PatchingInfo "Manufacturer: $($systemInfo.Manufacturer)" -WriteToHost
    Write-PatchingInfo "Model: $($systemInfo.Model)" -WriteToHost
    
    # Step 1: Initialize WinGet
    $wingetAvailable = Initialize-WinGet
    
    # Step 2: Update applications with WinGet
    if ($wingetAvailable) {
        Update-ApplicationsWithWinGet
    }
    
    # Step 3: Reset Windows Update components
    Reset-WindowsUpdateComponents
    
    # Step 4: Repair system files
    Repair-SystemFiles
    
    # Step 5: Update Lenovo drivers (if applicable and requested)
    Update-LenovoDrivers
    
    # Step 6: Remove bloatware applications (if requested)
    Remove-BloatwareApplications
    
    # Step 7: Update Office applications (if requested)
    Update-OfficeApplications
    
    # Step 8: Update Microsoft Store applications (if requested)
    Update-StoreApplications
    
    # Step 9: Install Windows updates
    Install-WindowsUpdates
    
    Write-PatchingInfo "System maintenance and patching completed successfully" -WriteToHost
    Complete-PatchingLog -Success $true
    
} catch {
    Write-PatchingError "Critical error during script execution" -Exception $_.Exception -WriteToHost
    Complete-PatchingLog -Success $false
    exit 1
}

#endregion
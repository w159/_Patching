#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Patches Windows Recovery Environment (WinRE) with security updates for Windows 10 version 2004 and later.

.DESCRIPTION
    This script applies critical security patches to the Windows Recovery Environment (WinRE)
    for Windows 10 version 2004 and later versions, including Windows 11. It safely mounts
    the WinRE image, applies the specified update package, and handles BitLocker protector
    refresh when necessary.

.PARAMETER WorkDirectory
    Working directory for WinRE patching operations (default: creates temporary directory)

.PARAMETER PackagePath
    Path to the Windows update package (.cab file) to apply to WinRE

.PARAMETER Force
    Force patching even if script was previously run successfully

.EXAMPLE
    .\Invoke-WinREPatching2004Plus.ps1 -PackagePath "C:\Updates\windows10.0-kb5034235-x64.cab"

.EXAMPLE
    .\Invoke-WinREPatching2004Plus.ps1 -PackagePath "C:\Updates\patch.cab" -WorkDirectory "C:\Temp\WinRE"

.NOTES
    Version: 2.0.0
    Author: Patching Scripts Collection
    Requires: PowerShell 5.1+, Administrative privileges, DISM tools
    
    This script targets Windows 10 version 2004+ and Windows 11 systems.
    It includes proper BitLocker handling and version checking.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$WorkDirectory,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript({
        if (-not (Test-Path -Path $_ -PathType Leaf)) {
            throw "Package file does not exist: $_"
        }
        if (-not ($_ -like "*.cab" -or $_ -like "*.msu")) {
            throw "Package file must be a .cab or .msu file: $_"
        }
        return $true
    })]
    [string]$PackagePath,
    
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
$logFile = Initialize-PatchingLog -ScriptName $scriptName

Write-PatchingInfo "Starting WinRE patching for Windows 10 2004+ and Windows 11" -WriteToHost

# Verify administrator privileges
if (-not (Test-IsAdministrator)) {
    Write-PatchingError "This script requires administrative privileges" -WriteToHost
    Complete-PatchingLog -Success $false
    exit 1
}

# Validate package path
$PackagePath = Resolve-Path -Path $PackagePath
Write-PatchingInfo "Package path: $PackagePath"

#endregion

#region Helper Functions

<#
.SYNOPSIS
    Checks if BitLocker is enabled with TPM-based protector.
#>
function Test-BitLockerTPMProtector {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    
    try {
        $driveLetter = $env:SystemDrive
        Write-PatchingInfo "Checking BitLocker status for drive: $driveLetter"
        
        $bitLocker = Get-CimInstance -Namespace "Root\cimv2\Security\MicrosoftVolumeEncryption" -ClassName "Win32_EncryptableVolume" -Filter "DriveLetter = '$driveLetter'" -ErrorAction Stop
        
        if (-not $bitLocker) {
            Write-PatchingInfo "No BitLocker object found"
            return $false
        }
        
        $protectionStatus = $bitLocker | Invoke-CimMethod -MethodName "GetProtectionStatus"
        
        switch ($protectionStatus.ProtectionStatus) {
            0 { 
                Write-PatchingInfo "BitLocker: Unprotected"
                return $false
            }
            1 { 
                Write-PatchingInfo "BitLocker: Protected"
                # Continue to check protector types
            }
            2 { 
                Write-PatchingInfo "BitLocker: Unknown status"
                return $false
            }
            default { 
                Write-PatchingInfo "BitLocker: No status returned"
                return $false
            }
        }
        
        # Get key protectors
        $protectorIds = $bitLocker | Invoke-CimMethod -MethodName "GetKeyProtectors" -Arguments @{KeyProtectorType = 0}
        
        $hasTPMProtector = $false
        foreach ($protectorId in $protectorIds.VolumeKeyProtectorID) {
            $protectorType = $bitLocker | Invoke-CimMethod -MethodName "GetKeyProtectorType" -Arguments @{VolumeKeyProtectorID = $protectorId}
            
            switch ($protectorType.KeyProtectorType) {
                1 { 
                    Write-PatchingInfo "Found TPM protector"
                    $hasTPMProtector = $true
                }
                4 { 
                    Write-PatchingInfo "Found TPM and PIN protector"
                    $hasTPMProtector = $true
                }
                5 { 
                    Write-PatchingInfo "Found TPM and Startup Key protector"
                    $hasTPMProtector = $true
                }
                6 { 
                    Write-PatchingInfo "Found TPM, PIN and Startup Key protector"
                    $hasTPMProtector = $true
                }
            }
        }
        
        if ($hasTPMProtector) {
            Write-PatchingInfo "Has TPM-based protector"
        } else {
            Write-PatchingInfo "Does not have TPM-based protector"
        }
        
        return $hasTPMProtector
    }
    catch {
        Write-PatchingWarning "Failed to check BitLocker status: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Sets registry key to indicate successful script execution.
#>
function Set-SuccessRegistryKey {
    [CmdletBinding()]
    param()
    
    try {
        $registryPath = 'HKLM:\SOFTWARE\Microsoft\PushButtonReset'
        Set-RegistryValue -Path $registryPath -Name 'WinREPatchScriptSucceed' -Value 1 -Type DWord
        Write-PatchingInfo "Success registry key set"
    }
    catch {
        Write-PatchingWarning "Failed to set success registry key: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Examines target file version to determine if update is needed.
#>
function Test-TargetFileVersion {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MountDirectory
    )
    
    try {
        $targetFile = Join-Path -Path $MountDirectory -ChildPath "Windows\System32\bootmenuux.dll"
        Write-PatchingInfo "Examining target file: $targetFile"
        
        if (-not (Test-Path -Path $targetFile)) {
            Write-PatchingWarning "Target file not found: $targetFile"
            return $false
        }
        
        $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($targetFile)
        $productVersion = $versionInfo.ProductVersion
        
        Write-PatchingInfo "Target file version: $productVersion"
        
        $versionParts = $productVersion.Split('.')
        if ($versionParts.Length -lt 3) {
            Write-PatchingWarning "Invalid version format: $productVersion"
            return $false
        }
        
        $buildNumber = $versionParts[2]
        $revision = [int]$versionParts[3]
        
        # Check version-specific revision requirements
        switch ($buildNumber) {
            "14393" {
                Write-PatchingInfo "Windows 10, version 1607"
                return $revision -ge 5499
            }
            "17763" {
                Write-PatchingInfo "Windows 10, version 1809"
                return $revision -ge 3646
            }
            "19041" {
                Write-PatchingInfo "Windows 10, version 2004"
                return $revision -ge 2247
            }
            "19042" {
                Write-PatchingInfo "Windows 10, version 20H2"
                return $revision -ge 1706
            }
            "19043" {
                Write-PatchingInfo "Windows 10, version 21H1"
                return $revision -ge 1706
            }
            "19044" {
                Write-PatchingInfo "Windows 10, version 21H2"
                return $revision -ge 1706
            }
            "22000" {
                Write-PatchingInfo "Windows 11, version 21H2"
                return $revision -ge 1215
            }
            "22621" {
                Write-PatchingInfo "Windows 11, version 22H2"
                return $revision -ge 815
            }
            "22631" {
                Write-PatchingInfo "Windows 11, version 23H2"
                return $revision -ge 2428
            }
            default {
                Write-PatchingWarning "Unsupported OS version (build: $buildNumber)"
                return $false
            }
        }
    }
    catch {
        Write-PatchingError "Failed to examine target file version" -Exception $_.Exception
        return $false
    }
}

<#
.SYNOPSIS
    Applies the update package to the mounted WinRE image.
#>
function Install-WinREPackage {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MountDirectory,
        
        [Parameter(Mandatory = $true)]
        [string]$PackagePath
    )
    
    $operation = Start-PatchingOperation -OperationName "WinRE Package Installation"
    
    try {
        # Check if update is already applied
        $hasUpdated = Test-TargetFileVersion -MountDirectory $MountDirectory
        if ($hasUpdated) {
            Write-PatchingInfo "The update has already been applied to WinRE"
            Set-SuccessRegistryKey
            Complete-PatchingOperation -OperationName "WinRE Package Installation" -Stopwatch $operation -Success $true
            return $false
        }
        
        # Apply package
        Write-PatchingInfo "Applying package: $PackagePath"
        $dismArgs = @(
            '/Add-Package',
            "/Image:$MountDirectory",
            "/PackagePath:$PackagePath"
        )
        
        $dismResult = Start-Process -FilePath 'DISM.exe' -ArgumentList $dismArgs -Wait -PassThru -NoNewWindow
        
        if ($dismResult.ExitCode -ne 0) {
            Write-PatchingError "Package installation failed with exit code: $($dismResult.ExitCode)"
            Complete-PatchingOperation -OperationName "WinRE Package Installation" -Stopwatch $operation -Success $false
            return $false
        }
        
        Write-PatchingInfo "Package applied successfully"
        
        # Cleanup recovery image
        Write-PatchingInfo "Cleaning up WinRE image"
        $cleanupArgs = @(
            "/Image:$MountDirectory",
            '/Cleanup-Image',
            '/StartComponentCleanup',
            '/ResetBase'
        )
        
        $cleanupResult = Start-Process -FilePath 'DISM.exe' -ArgumentList $cleanupArgs -Wait -PassThru -NoNewWindow
        
        if ($cleanupResult.ExitCode -ne 0) {
            Write-PatchingWarning "Image cleanup failed with exit code: $($cleanupResult.ExitCode)"
        } else {
            Write-PatchingInfo "Image cleanup completed successfully"
        }
        
        Complete-PatchingOperation -OperationName "WinRE Package Installation" -Stopwatch $operation -Success $true
        return $true
    }
    catch {
        Write-PatchingError "Error installing WinRE package" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "WinRE Package Installation" -Stopwatch $operation -Success $false
        return $false
    }
}

<#
.SYNOPSIS
    Gets WinRE image information and location.
#>
function Get-WinREImageInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    try {
        Write-PatchingInfo "Getting WinRE information"
        $reagentcResult = & reagentc.exe /info
        
        $winreInfo = [PSCustomObject]@{
            Enabled = $false
            ImagePath = $null
            Location = $null
        }
        
        foreach ($line in $reagentcResult) {
            if ($line -match "Windows RE status:\s+(.+)") {
                $winreInfo.Enabled = $matches[1] -eq "Enabled"
            }
            elseif ($line -match "Windows RE location:\s+(.+)") {
                $location = $matches[1].Trim()
                if ($location -ne "Unknown") {
                    $winreInfo.Location = $location
                }
            }
        }
        
        if ($winreInfo.Location) {
            # Extract WinRE image path
            if ($winreInfo.Location -match "\\\\\\?\\(.+)") {
                $drivePath = $matches[1]
                $winreInfo.ImagePath = Join-Path -Path $drivePath -ChildPath "Recovery\WindowsRE\winre.wim"
            }
        }
        
        Write-PatchingInfo "WinRE Enabled: $($winreInfo.Enabled)"
        Write-PatchingInfo "WinRE Location: $($winreInfo.Location)"
        Write-PatchingInfo "WinRE Image Path: $($winreInfo.ImagePath)"
        
        return $winreInfo
    }
    catch {
        Write-PatchingError "Failed to get WinRE information" -Exception $_.Exception
        return $null
    }
}

#endregion

#region Main Execution

try {
    # Check if script was previously run successfully
    if (-not $Force) {
        $previousSuccess = Get-RegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\PushButtonReset' -Name 'WinREPatchScriptSucceed' -DefaultValue 0
        if ($previousSuccess -eq 1) {
            Write-PatchingInfo "This script was previously run successfully. Use -Force to run again." -WriteToHost
            Complete-PatchingLog -Success $true
            exit 0
        }
    }
    
    # Get system information
    $systemInfo = Get-SystemInformation
    Write-PatchingInfo "System: $($systemInfo.ComputerName) - $($systemInfo.OSName) (Build $($systemInfo.OSBuild))"
    
    # Get WinRE information
    $winreInfo = Get-WinREImageInfo
    if (-not $winreInfo -or -not $winreInfo.ImagePath) {
        Write-PatchingError "Failed to locate WinRE image" -WriteToHost
        Complete-PatchingLog -Success $false
        exit 1
    }
    
    if (-not (Test-Path -Path $winreInfo.ImagePath)) {
        Write-PatchingError "WinRE image file not found: $($winreInfo.ImagePath)" -WriteToHost
        Complete-PatchingLog -Success $false
        exit 1
    }
    
    # Create working directory
    if ([string]::IsNullOrEmpty($WorkDirectory)) {
        $WorkDirectory = New-TemporaryDirectory
        if (-not $WorkDirectory) {
            Write-PatchingError "Failed to create working directory" -WriteToHost
            Complete-PatchingLog -Success $false
            exit 1
        }
    } else {
        if (-not (Test-Path -Path $WorkDirectory)) {
            New-Item -Path $WorkDirectory -ItemType Directory -Force | Out-Null
        }
    }
    
    $mountDir = Join-Path -Path $WorkDirectory -ChildPath "WinRE_Mount"
    if (-not (Test-Path -Path $mountDir)) {
        New-Item -Path $mountDir -ItemType Directory -Force | Out-Null
    }
    
    Write-PatchingInfo "Working directory: $WorkDirectory"
    Write-PatchingInfo "Mount directory: $mountDir"
    
    # Set permissions on mount directory
    try {
        & icacls.exe $mountDir /grant:r "*S-1-5-32-544:(OI)(CI)(F)" | Out-Null
        Write-PatchingInfo "Mount directory permissions set"
    } catch {
        Write-PatchingWarning "Failed to set mount directory permissions: $($_.Exception.Message)"
    }
    
    # Mount WinRE image
    Write-PatchingInfo "Mounting WinRE image: $($winreInfo.ImagePath)"
    $mountArgs = @(
        '/Mount-Image',
        "/ImageFile:$($winreInfo.ImagePath)",
        '/Index:1',
        "/MountDir:$mountDir"
    )
    
    $mountResult = Start-Process -FilePath 'DISM.exe' -ArgumentList $mountArgs -Wait -PassThru -NoNewWindow
    
    if ($mountResult.ExitCode -eq 0) {
        Write-PatchingInfo "WinRE image mounted successfully"
        
        try {
            # Apply package to WinRE
            $packageApplied = Install-WinREPackage -MountDirectory $mountDir -PackagePath $PackagePath
            
            if ($packageApplied) {
                # Verify update was applied
                $hasUpdated = Test-TargetFileVersion -MountDirectory $mountDir
                
                if ($hasUpdated) {
                    Write-PatchingInfo "Patch verification successful - expected version found"
                } else {
                    Write-PatchingWarning "Patch verification failed - unexpected version found"
                }
                
                # Unmount and commit changes
                Write-PatchingInfo "Unmounting WinRE image and committing changes"
                $unmountArgs = @('/Unmount-Image', "/MountDir:$mountDir", '/Commit')
                $unmountResult = Start-Process -FilePath 'DISM.exe' -ArgumentList $unmountArgs -Wait -PassThru -NoNewWindow
                
                if ($unmountResult.ExitCode -eq 0) {
                    Write-PatchingInfo "WinRE image unmounted and changes committed successfully"
                    
                    if ($hasUpdated) {
                        # Handle BitLocker TPM protector refresh if needed
                        if (Test-BitLockerTPMProtector) {
                            Write-PatchingInfo "Refreshing BitLocker protector for new WinRE"
                            
                            try {
                                & reagentc.exe /disable | Out-Null
                                Write-PatchingInfo "WinRE disabled"
                                
                                Start-Sleep -Seconds 2
                                
                                & reagentc.exe /enable | Out-Null
                                Write-PatchingInfo "WinRE re-enabled"
                                
                                & reagentc.exe /info
                            } catch {
                                Write-PatchingWarning "Failed to refresh BitLocker protector: $($_.Exception.Message)"
                            }
                        }
                        
                        # Set success registry key
                        Set-SuccessRegistryKey
                    }
                } else {
                    Write-PatchingError "Failed to unmount WinRE image (exit code: $($unmountResult.ExitCode))"
                    Complete-PatchingLog -Success $false
                    exit 1
                }
            } else {
                # Discard changes
                Write-PatchingInfo "Discarding WinRE image changes"
                $discardArgs = @('/Unmount-Image', "/MountDir:$mountDir", '/Discard')
                $discardResult = Start-Process -FilePath 'DISM.exe' -ArgumentList $discardArgs -Wait -PassThru -NoNewWindow
                
                if ($discardResult.ExitCode -ne 0) {
                    Write-PatchingError "Failed to discard WinRE image changes (exit code: $($discardResult.ExitCode))"
                }
            }
        } finally {
            # Ensure mount directory is cleaned up
            if (Test-Path -Path $mountDir) {
                Remove-DirectorySafe -Path $mountDir -Force
                Write-PatchingInfo "Mount directory cleaned up"
            }
        }
    } else {
        Write-PatchingError "Failed to mount WinRE image (exit code: $($mountResult.ExitCode))" -WriteToHost
        Complete-PatchingLog -Success $false
        exit 1
    }
    
    Write-PatchingInfo "WinRE patching completed successfully" -WriteToHost
    Complete-PatchingLog -Success $true
    
} catch {
    Write-PatchingError "Critical error during WinRE patching" -Exception $_.Exception -WriteToHost
    
    # Ensure cleanup happens even on error
    if ($mountDir -and (Test-Path -Path $mountDir)) {
        try {
            $discardArgs = @('/Unmount-Image', "/MountDir:$mountDir", '/Discard')
            Start-Process -FilePath 'DISM.exe' -ArgumentList $discardArgs -Wait -NoNewWindow | Out-Null
        } catch {
            Write-PatchingWarning "Failed to discard mounted image during error cleanup"
        }
        
        Remove-DirectorySafe -Path $mountDir -Force
    }
    
    Complete-PatchingLog -Success $false
    exit 1
}

#endregion
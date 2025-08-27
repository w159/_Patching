#Requires -Version 5.1

<#
.SYNOPSIS
    Common functions and utilities for the Patching PowerShell module collection.

.DESCRIPTION
    This module provides shared functionality used across all patching scripts including
    system detection, common validation, and utility functions.

.NOTES
    Version: 2.0.0
    Author: Patching Scripts Collection
    Created: 2024
    Last Modified: 2024
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest

#region System Detection Functions

<#
.SYNOPSIS
    Gets detailed system information for the current device.

.DESCRIPTION
    Returns comprehensive system information including OS version, hardware manufacturer,
    architecture, and other relevant details for patching decisions.

.OUTPUTS
    PSCustomObject with system information properties
#>
function Get-SystemInformation {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $processor = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
        
        return [PSCustomObject]@{
            ComputerName = $computerSystem.Name
            Manufacturer = $computerSystem.Manufacturer.Trim()
            Model = $computerSystem.Model.Trim()
            OSName = $operatingSystem.Caption
            OSVersion = $operatingSystem.Version
            OSBuild = $operatingSystem.BuildNumber
            OSArchitecture = $operatingSystem.OSArchitecture
            ProcessorName = $processor.Name
            ProcessorArchitecture = $processor.Architecture
            TotalPhysicalMemory = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
            Is64Bit = [System.Environment]::Is64BitOperatingSystem
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            ExecutionPolicy = Get-ExecutionPolicy
            LastBootTime = $operatingSystem.LastBootUpTime
        }
    }
    catch {
        Write-Error "Failed to retrieve system information: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Tests if the current system is manufactured by a specific vendor.

.PARAMETER Manufacturer
    The manufacturer name to test against (HP, Dell, Lenovo, etc.)

.OUTPUTS
    Boolean indicating if the system matches the specified manufacturer
#>
function Test-SystemManufacturer {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Manufacturer
    )
    
    try {
        $systemInfo = Get-SystemInformation
        if ($null -eq $systemInfo) {
            return $false
        }
        
        switch -Wildcard ($systemInfo.Manufacturer) {
            "*$Manufacturer*" { return $true }
            default { return $false }
        }
    }
    catch {
        Write-Warning "Could not determine system manufacturer: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Gets the Windows version and build information.

.OUTPUTS
    PSCustomObject with Windows version details
#>
function Get-WindowsVersion {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    try {
        $registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        $versionInfo = Get-ItemProperty -Path $registryPath -ErrorAction Stop
        
        return [PSCustomObject]@{
            ProductName = $versionInfo.ProductName
            DisplayVersion = $versionInfo.DisplayVersion
            ReleaseId = $versionInfo.ReleaseId
            CurrentBuild = $versionInfo.CurrentBuild
            UBR = $versionInfo.UBR
            BuildLabEx = $versionInfo.BuildLabEx
            InstallationType = $versionInfo.InstallationType
        }
    }
    catch {
        Write-Error "Failed to retrieve Windows version information: $($_.Exception.Message)"
        return $null
    }
}

#endregion

#region Security and Validation Functions

<#
.SYNOPSIS
    Ensures PowerShell is running with administrative privileges.

.DESCRIPTION
    Checks if the current PowerShell session has administrative privileges and
    optionally restarts with elevation if not running as administrator.

.PARAMETER RestartElevated
    If specified, will restart the script with elevation if not already running as administrator.

.OUTPUTS
    Boolean indicating if running as administrator
#>
function Test-IsAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter()]
        [switch]$RestartElevated
    )
    
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin -and $RestartElevated) {
        Write-Warning "Script requires administrative privileges. Attempting to restart with elevation..."
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.ScriptName)`""
        Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
        exit
    }
    
    return $isAdmin
}

<#
.SYNOPSIS
    Configures secure connection settings for web requests.

.DESCRIPTION
    Sets TLS 1.2 as the security protocol and configures other secure connection settings.
#>
function Set-SecureConnectionDefaults {
    [CmdletBinding()]
    param()
    
    try {
        # Enable TLS 1.2 and 1.3 if available
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 -bor [Net.SecurityProtocolType]::Tls11
        
        # Set progress preference to silent for faster downloads
        $Global:ProgressPreference = 'SilentlyContinue'
        
        Write-Verbose "Secure connection defaults configured successfully"
    }
    catch {
        Write-Warning "Failed to configure secure connection defaults: $($_.Exception.Message)"
    }
}

#endregion

#region File and Path Functions

<#
.SYNOPSIS
    Creates a temporary working directory for script operations.

.OUTPUTS
    String path to the created temporary directory
#>
function New-TemporaryDirectory {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    try {
        $tempPath = Join-Path -Path $env:TEMP -ChildPath "PatchingScripts_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
        Write-Verbose "Created temporary directory: $tempPath"
        return $tempPath
    }
    catch {
        Write-Error "Failed to create temporary directory: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Safely removes a directory and all its contents.

.PARAMETER Path
    The path to the directory to remove

.PARAMETER Force
    Force removal even if directory contains files
#>
function Remove-DirectorySafe {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        
        [Parameter()]
        [switch]$Force
    )
    
    if (Test-Path -Path $Path) {
        try {
            if ($PSCmdlet.ShouldProcess($Path, "Remove Directory")) {
                Remove-Item -Path $Path -Recurse -Force:$Force -ErrorAction Stop
                Write-Verbose "Successfully removed directory: $Path"
            }
        }
        catch {
            Write-Warning "Failed to remove directory '$Path': $($_.Exception.Message)"
        }
    }
}

#endregion

#region Registry Functions

<#
.SYNOPSIS
    Safely gets a registry value with error handling.

.PARAMETER Path
    Registry path

.PARAMETER Name
    Value name

.PARAMETER DefaultValue
    Default value to return if the registry value doesn't exist

.OUTPUTS
    The registry value or default value if not found
#>
function Get-RegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [object]$DefaultValue = $null
    )
    
    try {
        if (Test-Path -Path $Path) {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
            return $value.$Name
        }
        else {
            Write-Verbose "Registry path '$Path' does not exist"
            return $DefaultValue
        }
    }
    catch {
        Write-Verbose "Registry value '$Name' not found at '$Path': $($_.Exception.Message)"
        return $DefaultValue
    }
}

<#
.SYNOPSIS
    Safely sets a registry value with error handling.

.PARAMETER Path
    Registry path

.PARAMETER Name
    Value name

.PARAMETER Value
    Value to set

.PARAMETER Type
    Registry value type

.OUTPUTS
    Boolean indicating success
#>
function Set-RegistryValue {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [object]$Value,
        
        [Parameter()]
        [Microsoft.Win32.RegistryValueKind]$Type = 'String'
    )
    
    try {
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-Verbose "Created registry path: $Path"
        }
        
        if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set Registry Value")) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -ErrorAction Stop
            Write-Verbose "Set registry value '$Name' at '$Path'"
            return $true
        }
        return $false
    }
    catch {
        Write-Error "Failed to set registry value '$Name' at '$Path': $($_.Exception.Message)"
        return $false
    }
}

#endregion

# Export all functions
Export-ModuleMember -Function @(
    'Get-SystemInformation',
    'Test-SystemManufacturer',
    'Get-WindowsVersion',
    'Test-IsAdministrator',
    'Set-SecureConnectionDefaults',
    'New-TemporaryDirectory',
    'Remove-DirectorySafe',
    'Get-RegistryValue',
    'Set-RegistryValue'
)
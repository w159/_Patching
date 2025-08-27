#Requires -Version 5.1

<#
.SYNOPSIS
    Centralized logging module for the Patching PowerShell script collection.

.DESCRIPTION
    This module provides consistent logging functionality across all patching scripts
    with support for different log levels, file output, and structured logging.

.NOTES
    Version: 2.0.0
    Author: Patching Scripts Collection
    Created: 2024
    Last Modified: 2024
#>

# Set strict mode for better error handling
Set-StrictMode -Version Latest

#region Module Variables

# Default log path
$script:DefaultLogPath = Join-Path -Path $env:TEMP -ChildPath "PatchingLogs"
$script:CurrentLogFile = $null
$script:LoggingEnabled = $true

# Log levels enumeration
enum LogLevel {
    Verbose = 0
    Information = 1
    Warning = 2
    Error = 3
    Critical = 4
}

#endregion

#region Core Logging Functions

<#
.SYNOPSIS
    Initializes logging for a patching script.

.DESCRIPTION
    Sets up the logging infrastructure, creates log directories, and configures
    the log file for the current script execution.

.PARAMETER ScriptName
    Name of the script initializing logging

.PARAMETER LogPath
    Path where log files should be stored

.PARAMETER MaxLogFiles
    Maximum number of log files to retain (default: 10)

.OUTPUTS
    String path to the current log file
#>
function Initialize-PatchingLog {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptName,
        
        [Parameter()]
        [string]$LogPath = $script:DefaultLogPath,
        
        [Parameter()]
        [int]$MaxLogFiles = 10
    )
    
    try {
        # Create log directory if it doesn't exist
        if (-not (Test-Path -Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
        }
        
        # Generate log file name with timestamp
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $logFileName = "$($ScriptName)_$timestamp.log"
        $script:CurrentLogFile = Join-Path -Path $LogPath -ChildPath $logFileName
        
        # Clean up old log files
        Remove-OldLogFiles -LogPath $LogPath -ScriptName $ScriptName -MaxFiles $MaxLogFiles
        
        # Write initial log entry
        $systemInfo = Get-SystemInformation
        $logHeader = @"
================================================================================
Log initialized for: $ScriptName
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $($systemInfo.ComputerName)
OS: $($systemInfo.OSName) (Build $($systemInfo.OSBuild))
PowerShell Version: $($systemInfo.PowerShellVersion)
Is Administrator: $(Test-IsAdministrator)
Log File: $script:CurrentLogFile
================================================================================
"@
        
        Add-Content -Path $script:CurrentLogFile -Value $logHeader -Encoding UTF8
        
        Write-Verbose "Logging initialized: $script:CurrentLogFile"
        return $script:CurrentLogFile
    }
    catch {
        Write-Warning "Failed to initialize logging: $($_.Exception.Message)"
        $script:LoggingEnabled = $false
        return $null
    }
}

<#
.SYNOPSIS
    Writes a message to the log with specified level.

.PARAMETER Message
    The message to log

.PARAMETER Level
    The log level (Verbose, Information, Warning, Error, Critical)

.PARAMETER Category
    Optional category for the log entry

.PARAMETER WriteToHost
    Whether to also write to the console host
#>
function Write-PatchingLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Message,
        
        [Parameter()]
        [LogLevel]$Level = [LogLevel]::Information,
        
        [Parameter()]
        [string]$Category = 'General',
        
        [Parameter()]
        [switch]$WriteToHost
    )
    
    process {
        if (-not $script:LoggingEnabled -or [string]::IsNullOrEmpty($script:CurrentLogFile)) {
            if ($WriteToHost) {
                Write-Host $Message
            }
            return
        }
        
        try {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            $logEntry = "[$timestamp] [$($Level.ToString().ToUpper())] [$Category] $Message"
            
            # Write to log file
            Add-Content -Path $script:CurrentLogFile -Value $logEntry -Encoding UTF8
            
            # Optionally write to console
            if ($WriteToHost) {
                switch ($Level) {
                    ([LogLevel]::Verbose) { Write-Host $Message -ForegroundColor Gray }
                    ([LogLevel]::Information) { Write-Host $Message -ForegroundColor White }
                    ([LogLevel]::Warning) { Write-Host $Message -ForegroundColor Yellow }
                    ([LogLevel]::Error) { Write-Host $Message -ForegroundColor Red }
                    ([LogLevel]::Critical) { Write-Host $Message -ForegroundColor Magenta }
                }
            }
        }
        catch {
            Write-Warning "Failed to write to log: $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    Writes an informational message to the log.

.PARAMETER Message
    The message to log

.PARAMETER Category
    Optional category for the log entry

.PARAMETER WriteToHost
    Whether to also write to the console host
#>
function Write-PatchingInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,
        
        [Parameter()]
        [string]$Category = 'General',
        
        [Parameter()]
        [switch]$WriteToHost
    )
    
    process {
        Write-PatchingLog -Message $Message -Level ([LogLevel]::Information) -Category $Category -WriteToHost:$WriteToHost
    }
}

<#
.SYNOPSIS
    Writes a warning message to the log.

.PARAMETER Message
    The message to log

.PARAMETER Category
    Optional category for the log entry

.PARAMETER WriteToHost
    Whether to also write to the console host
#>
function Write-PatchingWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,
        
        [Parameter()]
        [string]$Category = 'General',
        
        [Parameter()]
        [switch]$WriteToHost
    )
    
    process {
        Write-PatchingLog -Message $Message -Level ([LogLevel]::Warning) -Category $Category -WriteToHost:$WriteToHost
    }
}

<#
.SYNOPSIS
    Writes an error message to the log.

.PARAMETER Message
    The message to log

.PARAMETER Exception
    Optional exception object to include details from

.PARAMETER Category
    Optional category for the log entry

.PARAMETER WriteToHost
    Whether to also write to the console host
#>
function Write-PatchingError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,
        
        [Parameter()]
        [System.Exception]$Exception,
        
        [Parameter()]
        [string]$Category = 'General',
        
        [Parameter()]
        [switch]$WriteToHost
    )
    
    process {
        $fullMessage = $Message
        if ($Exception) {
            $fullMessage += " Exception: $($Exception.Message)"
            if ($Exception.InnerException) {
                $fullMessage += " Inner Exception: $($Exception.InnerException.Message)"
            }
        }
        
        Write-PatchingLog -Message $fullMessage -Level ([LogLevel]::Error) -Category $Category -WriteToHost:$WriteToHost
    }
}

<#
.SYNOPSIS
    Writes a verbose message to the log.

.PARAMETER Message
    The message to log

.PARAMETER Category
    Optional category for the log entry
#>
function Write-PatchingVerbose {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,
        
        [Parameter()]
        [string]$Category = 'General'
    )
    
    process {
        Write-PatchingLog -Message $Message -Level ([LogLevel]::Verbose) -Category $Category
        Write-Verbose $Message
    }
}

<#
.SYNOPSIS
    Logs the start of an operation with timing information.

.PARAMETER OperationName
    Name of the operation being started

.PARAMETER Category
    Optional category for the log entry

.OUTPUTS
    Stopwatch object for measuring operation duration
#>
function Start-PatchingOperation {
    [CmdletBinding()]
    [OutputType([System.Diagnostics.Stopwatch])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName,
        
        [Parameter()]
        [string]$Category = 'Operation'
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-PatchingInfo -Message "Starting operation: $OperationName" -Category $Category -WriteToHost
    return $stopwatch
}

<#
.SYNOPSIS
    Logs the completion of an operation with timing information.

.PARAMETER OperationName
    Name of the operation being completed

.PARAMETER Stopwatch
    Stopwatch object from Start-PatchingOperation

.PARAMETER Success
    Whether the operation completed successfully

.PARAMETER Category
    Optional category for the log entry
#>
function Complete-PatchingOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName,
        
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Stopwatch]$Stopwatch,
        
        [Parameter()]
        [bool]$Success = $true,
        
        [Parameter()]
        [string]$Category = 'Operation'
    )
    
    $Stopwatch.Stop()
    $duration = $Stopwatch.Elapsed.ToString("hh\:mm\:ss\.fff")
    $status = if ($Success) { "completed successfully" } else { "failed" }
    $level = if ($Success) { [LogLevel]::Information } else { [LogLevel]::Error }
    
    Write-PatchingLog -Message "Operation '$OperationName' $status. Duration: $duration" -Level $level -Category $Category -WriteToHost
}

#endregion

#region Helper Functions

<#
.SYNOPSIS
    Removes old log files to maintain log file count limit.

.PARAMETER LogPath
    Path containing log files

.PARAMETER ScriptName
    Name of the script to clean logs for

.PARAMETER MaxFiles
    Maximum number of files to retain
#>
function Remove-OldLogFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        
        [Parameter()]
        [int]$MaxFiles = 10
    )
    
    try {
        $logFiles = Get-ChildItem -Path $LogPath -Filter "$ScriptName*.log" | 
                   Sort-Object LastWriteTime -Descending
        
        if ($logFiles.Count -gt $MaxFiles) {
            $filesToRemove = $logFiles | Select-Object -Skip $MaxFiles
            foreach ($file in $filesToRemove) {
                Remove-Item -Path $file.FullName -Force
                Write-Verbose "Removed old log file: $($file.Name)"
            }
        }
    }
    catch {
        Write-Warning "Failed to clean up old log files: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Gets the current log file path.

.OUTPUTS
    String path to the current log file
#>
function Get-CurrentLogFile {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    return $script:CurrentLogFile
}

<#
.SYNOPSIS
    Finalizes logging and writes closing information.

.PARAMETER Success
    Whether the overall script execution was successful
#>
function Complete-PatchingLog {
    [CmdletBinding()]
    param(
        [Parameter()]
        [bool]$Success = $true
    )
    
    if ($script:LoggingEnabled -and -not [string]::IsNullOrEmpty($script:CurrentLogFile)) {
        $status = if ($Success) { "COMPLETED SUCCESSFULLY" } else { "COMPLETED WITH ERRORS" }
        $logFooter = @"

================================================================================
Script execution $status
End time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Log file: $script:CurrentLogFile
================================================================================
"@
        
        Add-Content -Path $script:CurrentLogFile -Value $logFooter -Encoding UTF8
    }
}

#endregion

# Import required modules
if (Get-Module -ListAvailable -Name PatchingCommon) {
    Import-Module PatchingCommon -ErrorAction SilentlyContinue
}

# Export all functions
Export-ModuleMember -Function @(
    'Initialize-PatchingLog',
    'Write-PatchingLog',
    'Write-PatchingInfo',
    'Write-PatchingWarning',
    'Write-PatchingError',
    'Write-PatchingVerbose',
    'Start-PatchingOperation',
    'Complete-PatchingOperation',
    'Get-CurrentLogFile',
    'Complete-PatchingLog'
)
#Requires -Version 5.1

<#
.SYNOPSIS
    Configures SNMP service on local or remote Windows computers.

.DESCRIPTION
    This script enables and configures the SNMP service on Windows computers,
    including setting community strings, access rights, and permitted hosts.
    It supports both local and remote computer configuration with proper
    credential handling and error checking.

.PARAMETER ComputerName
    Target computer name for SNMP configuration (use 'localhost' or '.' for local computer)

.PARAMETER ComputerListFile
    Path to a text file containing a list of computer names (one per line)

.PARAMETER Credential
    PSCredential object for remote computer authentication

.PARAMETER Username
    Username for remote computer authentication (will prompt for password)

.PARAMETER CommunityName
    SNMP community string (default: 'public')

.PARAMETER AccessType
    SNMP access type: None(1), Notify(2), ReadOnly(4), ReadWrite(8), ReadCreate(16)

.PARAMETER PermittedHosts
    Array of hostnames or IP addresses allowed to query SNMP

.PARAMETER ConfigureOnly
    Only configure SNMP settings without enabling the service (assumes SNMP is already enabled)

.PARAMETER LogPath
    Custom path for log files (default: %TEMP%\PatchingLogs)

.EXAMPLE
    .\Set-SNMPConfiguration.ps1 -ComputerName localhost -CommunityName "public" -AccessType ReadOnly -PermittedHosts @("192.168.1.100", "server01")

.EXAMPLE
    .\Set-SNMPConfiguration.ps1 -ComputerListFile "C:\computers.txt" -Username "domain\admin" -CommunityName "monitoring" -AccessType ReadWrite

.EXAMPLE
    .\Set-SNMPConfiguration.ps1 -ComputerName "server01" -ConfigureOnly -CommunityName "readonly" -AccessType ReadOnly

.NOTES
    Version: 2.0.0
    Author: Patching Scripts Collection
    Requires: PowerShell 5.1+, Administrative privileges (for local), WinRM (for remote)
    
    Access Type Values:
    - None: 1
    - Notify: 2  
    - ReadOnly: 4
    - ReadWrite: 8
    - ReadCreate: 16
#>

[CmdletBinding(DefaultParameterSetName = 'SingleComputer', SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'SingleComputer')]
    [string]$ComputerName,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ComputerList')]
    [ValidateScript({
        if (-not (Test-Path -Path $_ -PathType Leaf)) {
            throw "Computer list file does not exist: $_"
        }
        return $true
    })]
    [string]$ComputerListFile,
    
    [Parameter(ParameterSetName = 'SingleComputer')]
    [Parameter(ParameterSetName = 'ComputerList')]
    [System.Management.Automation.PSCredential]$Credential,
    
    [Parameter(ParameterSetName = 'SingleComputer')]
    [Parameter(ParameterSetName = 'ComputerList')]
    [string]$Username,
    
    [Parameter()]
    [string]$CommunityName = 'public',
    
    [Parameter()]
    [ValidateSet(1, 2, 4, 8, 16)]
    [int]$AccessType = 4,  # ReadOnly by default
    
    [Parameter()]
    [string[]]$PermittedHosts = @(),
    
    [Parameter()]
    [switch]$ConfigureOnly,
    
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

Write-PatchingInfo "Starting SNMP configuration process" -WriteToHost

# Configure secure connection defaults
Set-SecureConnectionDefaults

# Handle credentials
if ($Username -and -not $Credential) {
    $Credential = Get-Credential -UserName $Username -Message "Enter password for $Username"
}

# Get computer list
$computers = @()
if ($PSCmdlet.ParameterSetName -eq 'SingleComputer') {
    $computers = @($ComputerName)
} else {
    try {
        $computers = Get-Content -Path $ComputerListFile -ErrorAction Stop | Where-Object { $_.Trim() -ne '' }
        Write-PatchingInfo "Loaded $($computers.Count) computers from file: $ComputerListFile"
    } catch {
        Write-PatchingError "Failed to read computer list file: $($_.Exception.Message)" -WriteToHost
        Complete-PatchingLog -Success $false
        exit 1
    }
}

# Display configuration summary
Write-PatchingInfo "SNMP Configuration Summary:"
Write-PatchingInfo "  Target Computers: $($computers.Count)"
Write-PatchingInfo "  Community Name: $CommunityName"
Write-PatchingInfo "  Access Type: $AccessType ($(Get-AccessTypeName -AccessType $AccessType))"
Write-PatchingInfo "  Permitted Hosts: $($PermittedHosts -join ', ')"
Write-PatchingInfo "  Configure Only: $ConfigureOnly"

#endregion

#region Helper Functions

<#
.SYNOPSIS
    Gets the friendly name for an SNMP access type value.
#>
function Get-AccessTypeName {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$AccessType
    )
    
    switch ($AccessType) {
        1 { return "None" }
        2 { return "Notify" }
        4 { return "ReadOnly" }
        8 { return "ReadWrite" }
        16 { return "ReadCreate" }
        default { return "Unknown" }
    }
}

<#
.SYNOPSIS
    Tests connectivity to a remote computer.
#>
function Test-ComputerConnectivity {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )
    
    try {
        $result = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction Stop
        return $result
    } catch {
        Write-PatchingVerbose "Connectivity test failed for $ComputerName`: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Checks if SNMP service is installed and gets its status.
#>
function Get-SNMPServiceStatus {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        $scriptBlock = {
            try {
                $service = Get-Service -Name 'SNMP' -ErrorAction Stop
                return [PSCustomObject]@{
                    Installed = $true
                    Status = $service.Status
                    StartType = $service.StartType
                }
            } catch {
                return [PSCustomObject]@{
                    Installed = $false
                    Status = 'Not Installed'
                    StartType = 'Unknown'
                }
            }
        }
        
        if ($ComputerName -eq 'localhost' -or $ComputerName -eq '.') {
            return & $scriptBlock
        } else {
            $invokeParams = @{
                ComputerName = $ComputerName
                ScriptBlock = $scriptBlock
                ErrorAction = 'Stop'
            }
            
            if ($Credential) {
                $invokeParams.Credential = $Credential
            }
            
            return Invoke-Command @invokeParams
        }
    } catch {
        Write-PatchingVerbose "Failed to get SNMP service status for $ComputerName`: $($_.Exception.Message)"
        return [PSCustomObject]@{
            Installed = $false
            Status = 'Error'
            StartType = 'Unknown'
        }
    }
}

<#
.SYNOPSIS
    Enables the SNMP service feature on Windows.
#>
function Enable-SNMPService {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        $scriptBlock = {
            try {
                # Enable SNMP feature using DISM
                $result = Start-Process -FilePath 'DISM.exe' -ArgumentList '/online', '/enable-feature', '/FeatureName:SNMP' -Wait -PassThru -NoNewWindow
                return $result.ExitCode -eq 0 -or $result.ExitCode -eq 3010
            } catch {
                return $false
            }
        }
        
        if ($ComputerName -eq 'localhost' -or $ComputerName -eq '.') {
            return & $scriptBlock
        } else {
            $invokeParams = @{
                ComputerName = $ComputerName
                ScriptBlock = $scriptBlock
                ErrorAction = 'Stop'
            }
            
            if ($Credential) {
                $invokeParams.Credential = $Credential
            }
            
            return Invoke-Command @invokeParams
        }
    } catch {
        Write-PatchingError "Failed to enable SNMP service on $ComputerName`: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Configures SNMP community strings and access rights.
#>
function Set-SNMPCommunityConfiguration {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [string]$CommunityName,
        
        [Parameter(Mandatory = $true)]
        [int]$AccessType,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        $scriptBlock = {
            param($Community, $Access)
            
            try {
                $registryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities'
                
                # Ensure registry path exists
                if (-not (Test-Path -Path $registryPath)) {
                    New-Item -Path $registryPath -Force | Out-Null
                }
                
                # Set community string with access rights
                Set-ItemProperty -Path $registryPath -Name $Community -Value $Access -Type DWord -ErrorAction Stop
                
                return $true
            } catch {
                return $false
            }
        }
        
        if ($ComputerName -eq 'localhost' -or $ComputerName -eq '.') {
            return & $scriptBlock -Community $CommunityName -Access $AccessType
        } else {
            $invokeParams = @{
                ComputerName = $ComputerName
                ScriptBlock = $scriptBlock
                ArgumentList = @($CommunityName, $AccessType)
                ErrorAction = 'Stop'
            }
            
            if ($Credential) {
                $invokeParams.Credential = $Credential
            }
            
            return Invoke-Command @invokeParams
        }
    } catch {
        Write-PatchingError "Failed to configure SNMP community on $ComputerName`: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Configures SNMP permitted managers (hosts allowed to query).
#>
function Set-SNMPPermittedManagers {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [string[]]$PermittedHosts,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    if ($PermittedHosts.Count -eq 0) {
        Write-PatchingVerbose "No permitted hosts specified for $ComputerName"
        return $true
    }
    
    try {
        $scriptBlock = {
            param($Hosts)
            
            try {
                $registryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\PermittedManagers'
                
                # Remove existing permitted managers key
                if (Test-Path -Path $registryPath) {
                    Remove-Item -Path $registryPath -Recurse -Force
                }
                
                # Create new permitted managers key
                New-Item -Path $registryPath -Force | Out-Null
                
                # Add each permitted host
                for ($i = 0; $i -lt $Hosts.Count; $i++) {
                    Set-ItemProperty -Path $registryPath -Name ($i + 1).ToString() -Value $Hosts[$i] -Type String
                }
                
                return $true
            } catch {
                return $false
            }
        }
        
        if ($ComputerName -eq 'localhost' -or $ComputerName -eq '.') {
            return & $scriptBlock -Hosts $PermittedHosts
        } else {
            $invokeParams = @{
                ComputerName = $ComputerName
                ScriptBlock = $scriptBlock
                ArgumentList = @(,$PermittedHosts)
                ErrorAction = 'Stop'
            }
            
            if ($Credential) {
                $invokeParams.Credential = $Credential
            }
            
            return Invoke-Command @invokeParams
        }
    } catch {
        Write-PatchingError "Failed to configure SNMP permitted managers on $ComputerName`: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Starts and configures the SNMP service startup type.
#>
function Start-SNMPService {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    try {
        $scriptBlock = {
            try {
                # Set service startup type to Automatic
                Set-Service -Name 'SNMP' -StartupType Automatic -ErrorAction Stop
                
                # Start the service
                Start-Service -Name 'SNMP' -ErrorAction Stop
                
                return $true
            } catch {
                return $false
            }
        }
        
        if ($ComputerName -eq 'localhost' -or $ComputerName -eq '.') {
            return & $scriptBlock
        } else {
            $invokeParams = @{
                ComputerName = $ComputerName
                ScriptBlock = $scriptBlock
                ErrorAction = 'Stop'
            }
            
            if ($Credential) {
                $invokeParams.Credential = $Credential
            }
            
            return Invoke-Command @invokeParams
        }
    } catch {
        Write-PatchingError "Failed to start SNMP service on $ComputerName`: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Configures SNMP on a single computer.
#>
function Set-ComputerSNMPConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [string]$CommunityName,
        
        [Parameter(Mandatory = $true)]
        [int]$AccessType,
        
        [Parameter()]
        [string[]]$PermittedHosts,
        
        [Parameter()]
        [switch]$ConfigureOnly,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    $operation = Start-PatchingOperation -OperationName "SNMP Configuration for $ComputerName"
    $result = [PSCustomObject]@{
        ComputerName = $ComputerName
        Success = $false
        Message = ''
        SNMPEnabled = $false
        ConfigurationApplied = $false
    }
    
    try {
        Write-PatchingInfo "Configuring SNMP on computer: $ComputerName"
        
        # Test connectivity
        if ($ComputerName -ne 'localhost' -and $ComputerName -ne '.') {
            Write-PatchingInfo "Testing connectivity to $ComputerName"
            if (-not (Test-ComputerConnectivity -ComputerName $ComputerName)) {
                $result.Message = "Computer not reachable"
                Write-PatchingWarning "Computer $ComputerName is not reachable"
                Complete-PatchingOperation -OperationName "SNMP Configuration for $ComputerName" -Stopwatch $operation -Success $false
                return $result
            }
            Write-PatchingInfo "Connectivity test passed"
        }
        
        # Check SNMP service status
        $snmpStatus = Get-SNMPServiceStatus -ComputerName $ComputerName -Credential $Credential
        Write-PatchingInfo "SNMP service status: $($snmpStatus.Status) (Installed: $($snmpStatus.Installed))"
        
        # Enable SNMP if not installed and not in configure-only mode
        if (-not $snmpStatus.Installed -and -not $ConfigureOnly) {
            Write-PatchingInfo "Enabling SNMP service on $ComputerName"
            $enableSuccess = Enable-SNMPService -ComputerName $ComputerName -Credential $Credential
            
            if ($enableSuccess) {
                Write-PatchingInfo "SNMP service enabled successfully"
                $result.SNMPEnabled = $true
                
                # Wait a moment for service to be available
                Start-Sleep -Seconds 5
            } else {
                $result.Message = "Failed to enable SNMP service"
                Write-PatchingError "Failed to enable SNMP service on $ComputerName"
                Complete-PatchingOperation -OperationName "SNMP Configuration for $ComputerName" -Stopwatch $operation -Success $false
                return $result
            }
        } elseif (-not $snmpStatus.Installed -and $ConfigureOnly) {
            $result.Message = "SNMP service not installed (configure-only mode requires SNMP to be already enabled)"
            Write-PatchingWarning "SNMP not installed on $ComputerName and configure-only mode specified"
            Complete-PatchingOperation -OperationName "SNMP Configuration for $ComputerName" -Stopwatch $operation -Success $false
            return $result
        } else {
            Write-PatchingInfo "SNMP service is already installed"
            $result.SNMPEnabled = $true
        }
        
        # Configure SNMP community
        Write-PatchingInfo "Configuring SNMP community '$CommunityName' with access type $AccessType"
        $communitySuccess = Set-SNMPCommunityConfiguration -ComputerName $ComputerName -CommunityName $CommunityName -AccessType $AccessType -Credential $Credential
        
        if (-not $communitySuccess) {
            $result.Message = "Failed to configure SNMP community"
            Write-PatchingError "Failed to configure SNMP community on $ComputerName"
            Complete-PatchingOperation -OperationName "SNMP Configuration for $ComputerName" -Stopwatch $operation -Success $false
            return $result
        }
        
        Write-PatchingInfo "SNMP community configured successfully"
        
        # Configure permitted managers
        if ($PermittedHosts.Count -gt 0) {
            Write-PatchingInfo "Configuring permitted hosts: $($PermittedHosts -join ', ')"
            $managersSuccess = Set-SNMPPermittedManagers -ComputerName $ComputerName -PermittedHosts $PermittedHosts -Credential $Credential
            
            if (-not $managersSuccess) {
                $result.Message = "Failed to configure SNMP permitted managers"
                Write-PatchingWarning "Failed to configure SNMP permitted managers on $ComputerName"
            } else {
                Write-PatchingInfo "SNMP permitted managers configured successfully"
            }
        }
        
        # Start SNMP service
        Write-PatchingInfo "Starting SNMP service on $ComputerName"
        $serviceSuccess = Start-SNMPService -ComputerName $ComputerName -Credential $Credential
        
        if ($serviceSuccess) {
            Write-PatchingInfo "SNMP service started successfully"
            $result.ConfigurationApplied = $true
            $result.Success = $true
            $result.Message = "SNMP configuration completed successfully"
        } else {
            $result.Message = "SNMP configured but failed to start service"
            Write-PatchingWarning "SNMP configured on $ComputerName but failed to start service"
        }
        
        Complete-PatchingOperation -OperationName "SNMP Configuration for $ComputerName" -Stopwatch $operation -Success $result.Success
        return $result
        
    } catch {
        $result.Message = "Error during SNMP configuration: $($_.Exception.Message)"
        Write-PatchingError "Error configuring SNMP on $ComputerName" -Exception $_.Exception
        Complete-PatchingOperation -OperationName "SNMP Configuration for $ComputerName" -Stopwatch $operation -Success $false
        return $result
    }
}

#endregion

#region Main Execution

try {
    $totalComputers = $computers.Count
    $successCount = 0
    $failureCount = 0
    $results = @()
    
    Write-PatchingInfo "Processing $totalComputers computer(s)" -WriteToHost
    
    foreach ($computer in $computers) {
        $computer = $computer.Trim()
        if ([string]::IsNullOrEmpty($computer)) {
            continue
        }
        
        Write-PatchingInfo "Processing computer $($computers.IndexOf($computer) + 1) of $totalComputers`: $computer" -WriteToHost
        
        $result = Set-ComputerSNMPConfiguration -ComputerName $computer -CommunityName $CommunityName -AccessType $AccessType -PermittedHosts $PermittedHosts -ConfigureOnly:$ConfigureOnly -Credential $Credential
        $results += $result
        
        if ($result.Success) {
            $successCount++
            Write-PatchingInfo "✓ $computer`: $($result.Message)" -WriteToHost
        } else {
            $failureCount++
            Write-PatchingWarning "✗ $computer`: $($result.Message)" -WriteToHost
        }
        
        # Small delay between computers to avoid overwhelming remote systems
        if ($totalComputers -gt 1 -and $computer -ne $computers[-1]) {
            Start-Sleep -Seconds 1
        }
    }
    
    # Summary
    Write-PatchingInfo "" -WriteToHost
    Write-PatchingInfo "SNMP Configuration Summary:" -WriteToHost
    Write-PatchingInfo "  Total computers processed: $totalComputers" -WriteToHost
    Write-PatchingInfo "  Successful configurations: $successCount" -WriteToHost
    Write-PatchingInfo "  Failed configurations: $failureCount" -WriteToHost
    
    if ($failureCount -gt 0) {
        Write-PatchingInfo "" -WriteToHost
        Write-PatchingInfo "Failed computers:" -WriteToHost
        $results | Where-Object { -not $_.Success } | ForEach-Object {
            Write-PatchingInfo "  $($_.ComputerName): $($_.Message)" -WriteToHost
        }
    }
    
    $overallSuccess = $failureCount -eq 0
    Complete-PatchingLog -Success $overallSuccess
    
    if (-not $overallSuccess) {
        exit 1
    }
    
} catch {
    Write-PatchingError "Critical error during SNMP configuration process" -Exception $_.Exception -WriteToHost
    Complete-PatchingLog -Success $false
    exit 1
}

#endregion
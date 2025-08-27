# Migration Guide: Legacy Scripts to Version 2.0

This guide helps you migrate from the legacy PowerShell scripts to the new organized and modernized version 2.0 structure.

## Overview of Changes

### Repository Structure
- **NEW**: Organized folder structure with logical categories
- **NEW**: Shared PowerShell modules for common functionality
- **NEW**: Centralized logging and error handling
- **CHANGED**: Script names follow PowerShell best practices
- **MOVED**: Deprecated scripts moved to `./Archived/` directory

## Script Migration Map

### Windows Patching & System Repair

| **Legacy Script** | **New Script** | **Status** |
|-------------------|----------------|------------|
| `Patch and Repair.ps1` | `Scripts/WindowsPatching/Invoke-SystemMaintenanceAndPatching.ps1` | ✅ Modernized |
| `PatchWinREScript_2004plus.ps1` | `Scripts/WindowsPatching/Invoke-WinREPatching2004Plus.ps1` | ✅ Modernized |
| `PatchWinREScript_General.ps1` | `Scripts/WindowsPatching/Invoke-WinREPatchingGeneral.ps1` | 🔄 In Progress |
| `Patching - WinRE.ps1` | `Scripts/WindowsPatching/Invoke-WinREPatching2004Plus.ps1` | ✅ Consolidated |

### Application Updates

| **Legacy Script** | **New Script** | **Status** |
|-------------------|----------------|------------|
| `Chrome - Update to Latest.ps1` | `Scripts/ApplicationUpdates/Update-GoogleChrome.ps1` | ✅ Modernized |
| `Firefox - Update to Latest.ps1` | `Scripts/ApplicationUpdates/Update-Firefox.ps1` | 🔄 In Progress |
| `Edge - Update to Latest.ps1` | `Scripts/ApplicationUpdates/Update-MicrosoftEdge.ps1` | 🔄 In Progress |
| `Adobe Reader Updater.ps1` | `Scripts/ApplicationUpdates/Update-AdobeReader.ps1` | 🔄 In Progress |
| `Office Updater.ps1` | `Scripts/ApplicationUpdates/Update-MicrosoftOffice.ps1` | 🔄 In Progress |

### Driver Updates

| **Legacy Script** | **New Script** | **Status** |
|-------------------|----------------|------------|
| `Patching - Invoke-HPDriverUpdate.ps1` | `Scripts/DriverUpdates/Update-HPDrivers.ps1` | ✅ Modernized |
| `Patching - Dell Drivers.ps1` | `Scripts/DriverUpdates/Update-DellDrivers.ps1` | 🔄 In Progress |
| `Patching - Lenovo Drivers.ps1` | `Scripts/DriverUpdates/Update-LenovoDrivers.ps1` | 🔄 In Progress |
| `NVIDIA - Update Driver.ps1` | `Scripts/DriverUpdates/Update-NVIDIADrivers.ps1` | 🔄 In Progress |

### System Configuration

| **Legacy Script** | **New Script** | **Status** |
|-------------------|----------------|------------|
| `Configure-SNMP.ps1` | `Scripts/SystemConfiguration/Set-SNMPConfiguration.ps1` | ✅ Modernized |
| `Secure Boot Enable.ps1` | `Scripts/SystemConfiguration/Enable-SecureBoot.ps1` | 🔄 In Progress |
| `Bitlocker - DMA Bus Fix.ps1` | `Scripts/SystemConfiguration/Set-BitLockerDMAProtection.ps1` | 🔄 In Progress |

### System Maintenance

| **Legacy Script** | **New Script** | **Status** |
|-------------------|----------------|------------|
| `Bloatware - Remove Default Apps.ps1` | `Scripts/SystemMaintenance/Remove-BloatwareApps.ps1` | 🔄 In Progress |
| `Disable - Fast Start and Hibernation.ps1` | `Scripts/SystemMaintenance/Disable-FastStartup.ps1` | 🔄 In Progress |
| `RPC Error Fix.ps1` | `Scripts/SystemMaintenance/Repair-RPCService.ps1` | 🔄 In Progress |

### Deprecated Scripts (Archived)

| **Archived Script** | **Reason** | **Alternative** |
|---------------------|------------|-----------------|
| `DEPRECATED - Adobe Reader Updater.ps1` | Superseded by newer version | Use new Adobe Reader updater |
| `DEPRECATED Teams - Update to Latest.ps1` | Teams Classic discontinued | Use Microsoft 365 Apps management |

## Migration Steps

### 1. Update Script Calls

**Before (Legacy):**
```powershell
.\Patch and Repair.ps1
```

**After (Version 2.0):**
```powershell
.\Scripts\WindowsPatching\Invoke-SystemMaintenanceAndPatching.ps1 -IncludeDriverUpdates
```

### 2. Update Parameters

Many scripts now have improved parameter names and validation:

**Before:**
```powershell
.\Configure-SNMP.ps1 -h localhost -communityName public -snmpType 4
```

**After:**
```powershell
.\Scripts\SystemConfiguration\Set-SNMPConfiguration.ps1 -ComputerName localhost -CommunityName public -AccessType ReadOnly
```

### 3. Leverage New Features

**Centralized Logging:**
```powershell
# All scripts now support custom log paths
.\Scripts\WindowsPatching\Invoke-SystemMaintenanceAndPatching.ps1 -LogPath "C:\Logs\Patching"
```

**Batch Processing:**
```powershell
# Many scripts now support multiple computers
.\Scripts\SystemConfiguration\Set-SNMPConfiguration.ps1 -ComputerListFile "C:\computers.txt"
```

**Enhanced Error Handling:**
```powershell
# All scripts now have comprehensive error handling and recovery
.\Scripts\DriverUpdates\Update-HPDrivers.ps1 -Force  # Force reinstall on errors
```

## Breaking Changes

### Parameter Names
- **SNMP Configuration**: `-h` → `-ComputerName`, `-snmpType` → `-AccessType`
- **HP Drivers**: `-RunMode` removed (automatic staging), added `-WorkingDirectory`
- **Chrome Update**: Simplified parameters, added `-DownloadPath` and `-Silent`

### Function Names
- All internal functions now use approved PowerShell verbs
- Logging functions standardized across all scripts

### File Paths
- Scripts moved to categorized folders
- Modules separated into their own directory structure
- Log files now centralized in `%TEMP%\PatchingLogs` by default

### Requirements
- All scripts now require PowerShell 5.1+
- Administrative privileges explicitly checked where needed
- Module dependencies clearly documented

## Quick Migration Examples

### Example 1: System Maintenance
```powershell
# Legacy approach
.\Patch and Repair.ps1

# Modern approach with same functionality
.\Scripts\WindowsPatching\Invoke-SystemMaintenanceAndPatching.ps1

# Modern approach with additional features
.\Scripts\WindowsPatching\Invoke-SystemMaintenanceAndPatching.ps1 `
    -IncludeDriverUpdates `
    -IncludeBloatwareRemoval `
    -IncludeOfficeUpdates `
    -LogPath "C:\Logs"
```

### Example 2: Chrome Updates
```powershell
# Legacy approach
.\Chrome - Update to Latest.ps1

# Modern approach
.\Scripts\ApplicationUpdates\Update-GoogleChrome.ps1

# Modern approach with options
.\Scripts\ApplicationUpdates\Update-GoogleChrome.ps1 -Force -Silent
```

### Example 3: HP Driver Updates
```powershell
# Legacy approach
.\Patching - Invoke-HPDriverUpdate.ps1 -RunMode Stage
.\Patching - Invoke-HPDriverUpdate.ps1 -RunMode Execute

# Modern approach (automatic staging)
.\Scripts\DriverUpdates\Update-HPDrivers.ps1

# Modern approach with downloads only
.\Scripts\DriverUpdates\Update-HPDrivers.ps1 -DownloadsOnly
```

## Testing Your Migration

### 1. Test Individual Scripts
```powershell
# Use WhatIf when available
.\Scripts\SystemConfiguration\Set-SNMPConfiguration.ps1 -ComputerName localhost -WhatIf

# Check help documentation
Get-Help .\Scripts\ApplicationUpdates\Update-GoogleChrome.ps1 -Full
```

### 2. Verify Logging
```powershell
# Run a script and check the log output
.\Scripts\WindowsPatching\Invoke-SystemMaintenanceAndPatching.ps1
# Check log at: %TEMP%\PatchingLogs\
```

### 3. Test Error Handling
```powershell
# Test with invalid parameters to verify error handling
.\Scripts\SystemConfiguration\Set-SNMPConfiguration.ps1 -ComputerName "InvalidComputer"
```

## Support and Troubleshooting

### Common Issues

1. **Module Import Errors**
   - Ensure PowerShell execution policy allows module loading
   - Verify file paths are correct relative to script location

2. **Permission Errors**
   - Run PowerShell as Administrator for system-level changes
   - Verify WinRM is enabled for remote computer management

3. **Parameter Validation Errors**
   - Check new parameter names and types
   - Use `Get-Help` to see current parameter requirements

### Getting Help

```powershell
# Get detailed help for any script
Get-Help .\Scripts\CategoryName\ScriptName.ps1 -Full

# Get examples
Get-Help .\Scripts\CategoryName\ScriptName.ps1 -Examples

# Get parameter details
Get-Help .\Scripts\CategoryName\ScriptName.ps1 -Parameter *
```

## Benefits of Migration

### Improved Reliability
- Comprehensive error handling and recovery
- Automatic retry mechanisms where appropriate
- Better validation of prerequisites and parameters

### Enhanced Monitoring
- Detailed logging with multiple levels
- Operation timing and performance metrics
- Centralized log management

### Better Security
- Administrative privilege validation
- Secure credential handling for remote operations
- TLS 1.2+ enforcement for downloads

### Easier Maintenance
- Modular design with shared functions
- Consistent coding standards
- Comprehensive documentation

---

**Need Help?** Check the main README.md for detailed usage examples and troubleshooting tips.
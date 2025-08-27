# Patching Scripts Collection

A comprehensive collection of modernized PowerShell scripts for automated Windows system patching, application updates, driver management, and system configuration.

## 🚀 Overview

This repository contains organized, enterprise-ready PowerShell scripts designed to automate various aspects of Windows system maintenance and patching. All scripts have been modernized with the latest PowerShell best practices, comprehensive error handling, and centralized logging.

## 📁 Repository Structure

```
├── Modules/                          # Shared PowerShell modules
│   ├── Common/                       # Common utility functions
│   │   ├── PatchingCommon.psm1      # System info, validation, utilities
│   │   └── PatchingCommon.psd1      # Module manifest
│   └── Logging/                      # Centralized logging
│       ├── PatchingLogging.psm1     # Logging functions
│       └── PatchingLogging.psd1     # Module manifest
├── Scripts/                          # Organized script categories
│   ├── WindowsPatching/              # Windows updates & system repair
│   ├── ApplicationUpdates/           # Third-party app updates
│   ├── DriverUpdates/                # Hardware driver updates
│   ├── SystemConfiguration/          # Configuration scripts
│   ├── SystemMaintenance/            # Cleanup & optimization
│   └── SecurityAndCompliance/        # Security-related scripts
├── Archived/                         # Deprecated scripts
├── Docs/                            # Documentation & examples
└── README.md                        # This file
```

## 🛠 Features

### Modern PowerShell Practices
- **PowerShell 5.1+** compatibility with modern cmdlets
- **Requires statements** for version and privilege validation
- **Advanced parameter validation** with proper error handling
- **Consistent coding standards** following PowerShell best practices
- **Comprehensive help documentation** with examples

### Centralized Functionality
- **Shared modules** for common functions across all scripts
- **Unified logging system** with structured log levels
- **Consistent error handling** and reporting
- **System information detection** and validation
- **Secure connection defaults** (TLS 1.2+)

### Enterprise Ready
- **Administrative privilege checks** where required
- **Remote computer support** with proper credential handling
- **Batch processing capabilities** for multiple systems
- **Detailed progress reporting** and operation timing
- **Cleanup and recovery mechanisms** for failed operations

## 📖 Script Categories

### Windows Patching
Scripts for Windows system updates and repairs:

- **Invoke-SystemMaintenanceAndPatching.ps1** - Comprehensive system maintenance including Windows updates, WinGet app updates, system file repair, and optional driver updates
- **Invoke-WinREPatching2004Plus.ps1** - Windows Recovery Environment patching for Windows 10 2004+ and Windows 11

### Application Updates
Scripts for updating third-party applications:

- **Update-GoogleChrome.ps1** - Downloads and installs latest Google Chrome Enterprise
- *More application updaters coming...*

### Driver Updates
Scripts for hardware driver management:

- **Update-HPDrivers.ps1** - HP driver updates using HP Image Assistant and HPCMSL
- *Dell and Lenovo driver updaters coming...*

### System Configuration
Scripts for system configuration and setup:

- **Set-SNMPConfiguration.ps1** - SNMP service configuration with community strings and access control
- *More configuration scripts coming...*

### System Maintenance
Scripts for system cleanup and optimization:

- *System cleanup and optimization scripts coming...*

### Security and Compliance
Scripts for security configurations and compliance:

- *Security and compliance scripts coming...*

## 🔧 Prerequisites

### System Requirements
- **Windows 10** version 1607 or later
- **Windows Server 2016** or later
- **PowerShell 5.1** or later
- **Administrative privileges** (for most scripts)

### PowerShell Modules
The scripts will automatically install required modules:
- **PSWindowsUpdate** - For Windows updates
- **HPCMSL** - For HP driver management (HP systems only)
- **LSUClient** - For Lenovo driver management (Lenovo systems only)

### Network Requirements
- **Internet connectivity** for downloading updates and modules
- **WinRM enabled** for remote computer management
- **TLS 1.2+** support for secure downloads

## 🚦 Getting Started

### 1. Clone or Download
```powershell
# Clone the repository
git clone https://github.com/w159/_Patching.git
cd _Patching
```

### 2. Import Modules (Optional)
```powershell
# Import common modules for direct use
Import-Module .\Modules\Common\PatchingCommon.psm1
Import-Module .\Modules\Logging\PatchingLogging.psm1
```

### 3. Run Scripts
```powershell
# Example: Comprehensive system maintenance
.\Scripts\WindowsPatching\Invoke-SystemMaintenanceAndPatching.ps1 -IncludeDriverUpdates

# Example: Update Google Chrome
.\Scripts\ApplicationUpdates\Update-GoogleChrome.ps1 -Silent

# Example: Configure SNMP
.\Scripts\SystemConfiguration\Set-SNMPConfiguration.ps1 -ComputerName localhost -CommunityName "monitoring" -AccessType ReadOnly
```

## 📋 Usage Examples

### Comprehensive System Maintenance
```powershell
# Full system maintenance with all options
.\Scripts\WindowsPatching\Invoke-SystemMaintenanceAndPatching.ps1 `
    -IncludeDriverUpdates `
    -IncludeBloatwareRemoval `
    -IncludeOfficeUpdates `
    -IncludeStoreAppUpdates `
    -LogPath "C:\Logs\Patching"
```

### Application Updates
```powershell
# Force Chrome update even if current
.\Scripts\ApplicationUpdates\Update-GoogleChrome.ps1 -Force -Silent

# Custom download location
.\Scripts\ApplicationUpdates\Update-GoogleChrome.ps1 -DownloadPath "C:\Temp\Chrome"
```

### Driver Updates
```powershell
# HP driver updates with custom working directory
.\Scripts\DriverUpdates\Update-HPDrivers.ps1 -WorkingDirectory "C:\HPDrivers"

# Download HP drivers only (no installation)
.\Scripts\DriverUpdates\Update-HPDrivers.ps1 -DownloadsOnly
```

### System Configuration
```powershell
# Configure SNMP on multiple computers
.\Scripts\SystemConfiguration\Set-SNMPConfiguration.ps1 `
    -ComputerListFile "C:\computers.txt" `
    -Username "domain\admin" `
    -CommunityName "monitoring" `
    -AccessType ReadOnly `
    -PermittedHosts @("192.168.1.100", "monitor01")
```

## 📊 Logging and Monitoring

### Centralized Logging
All scripts use a centralized logging system that provides:

- **Structured log levels**: Verbose, Information, Warning, Error, Critical
- **Timestamped entries** with millisecond precision
- **Operation timing** for performance monitoring
- **Automatic log rotation** to manage disk space
- **Console and file output** options

### Log Locations
Default log location: `%TEMP%\PatchingLogs`

Log files are named: `{ScriptName}_{Timestamp}.log`

### Sample Log Output
```
================================================================================
Log initialized for: Update-GoogleChrome
Timestamp: 2024-01-15 14:30:15
Computer: WORKSTATION01
OS: Windows 10 Pro (Build 19045)
PowerShell Version: 5.1.19041.3803
Is Administrator: True
Log File: C:\Users\admin\AppData\Local\Temp\PatchingLogs\Update-GoogleChrome_20240115_143015.log
================================================================================
[2024-01-15 14:30:15.123] [INFO] [General] Starting Google Chrome update process
[2024-01-15 14:30:15.234] [INFO] [Operation] Starting operation: Chrome Version Lookup
[2024-01-15 14:30:16.456] [INFO] [General] Latest Chrome version: 120.0.6099.224
[2024-01-15 14:30:16.567] [INFO] [Operation] Operation 'Chrome Version Lookup' completed successfully. Duration: 00:00:01.333
```

## 🛡 Security Considerations

### Administrative Privileges
Most scripts require administrative privileges for:
- Installing Windows updates
- Modifying system configurations
- Installing/updating drivers
- Managing system services

### Remote Access
For remote computer management:
- **WinRM** must be enabled on target computers
- **Proper credentials** must be provided
- **Network connectivity** must allow WinRM traffic
- **Firewall rules** may need configuration

### Downloaded Content
Scripts handle downloaded content securely:
- **TLS 1.2+** for all web requests
- **File signature verification** where available
- **Temporary file cleanup** after operations
- **Unblocking downloaded files** before execution

## 🔄 Version History

### Version 2.0.0 (Current)
- **Complete reorganization** of repository structure
- **Modern PowerShell practices** implementation
- **Centralized logging and error handling**
- **Comprehensive documentation** and examples
- **Modular architecture** with shared functions
- **Enhanced parameter validation** and help text

### Version 1.x (Legacy)
- Original collection of individual scripts
- Mixed coding standards and practices
- No centralized logging or error handling
- Scripts archived in `./Archived/` directory

## 🤝 Contributing

### Code Standards
- Follow PowerShell best practices and style guidelines
- Use approved PowerShell verbs for function names
- Implement comprehensive error handling with try/catch blocks
- Add proper parameter validation and help documentation
- Use the centralized logging system for all output
- Test scripts on multiple Windows versions when possible

### Script Requirements
- Must support PowerShell 5.1+
- Must use centralized modules for common functions
- Must include comprehensive help documentation
- Must implement proper error handling and logging
- Must follow the established repository structure

## 📞 Support

### Documentation
- **Script help**: Use `Get-Help .\scriptname.ps1 -Full` for detailed help
- **Module help**: Use `Get-Help ModuleName` for module documentation
- **Examples**: Check individual script help for usage examples

### Issues
- Check script logs for detailed error information
- Verify prerequisites and system requirements
- Test with `-WhatIf` parameter when available
- Review security and firewall settings for remote operations

## ⚠️ Important Notes

### Testing
- **Always test scripts** in a non-production environment first
- **Use `-WhatIf` parameter** when available to preview changes
- **Review logs carefully** for any warnings or errors
- **Backup systems** before making significant changes

### Vendor Changes
Scripts rely on vendor APIs and download URLs that may change:
- **Google Chrome**: Uses Google's Version History API
- **HP Drivers**: Uses HP Image Assistant and HPCMSL
- **Windows Updates**: Uses Microsoft's PowerShell modules

### Compatibility
Scripts are tested on:
- **Windows 10** versions 1607, 1809, 2004, 20H2, 21H1, 21H2, 22H2
- **Windows 11** versions 21H2, 22H2, 23H2
- **Windows Server 2016, 2019, 2022**

## 📜 License

This project is provided as-is for educational and professional use. Please review and test thoroughly before using in production environments.

---

**⚡ Quick Start**: Run `.\Scripts\WindowsPatching\Invoke-SystemMaintenanceAndPatching.ps1` for comprehensive system maintenance!

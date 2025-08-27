@{
    # Module manifest for PatchingLogging
    RootModule = 'PatchingLogging.psm1'
    ModuleVersion = '2.0.0'
    GUID = 'b2c3d4e5-f6g7-8901-bcde-f23456789012'
    Author = 'Patching Scripts Collection'
    CompanyName = 'Unknown'
    Copyright = '(c) 2024. All rights reserved.'
    Description = 'Centralized logging module for the Patching PowerShell script collection'
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
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
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Required modules
    RequiredModules = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('Patching', 'Logging', 'Windows', 'Utilities')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial release of PatchingLogging module with centralized logging functionality'
        }
    }
}
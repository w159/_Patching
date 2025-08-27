@{
    # Module manifest for PatchingCommon
    RootModule = 'PatchingCommon.psm1'
    ModuleVersion = '2.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'Patching Scripts Collection'
    CompanyName = 'Unknown'
    Copyright = '(c) 2024. All rights reserved.'
    Description = 'Common functions and utilities for the Patching PowerShell module collection'
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
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
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('Patching', 'Windows', 'Utilities', 'Common')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial release of PatchingCommon module with essential utility functions'
        }
    }
}
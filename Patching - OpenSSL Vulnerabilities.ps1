
<#
.SYNOPSIS
The purpose of this script is to check any underlying .DLL that are using a vulnerable version of OpenSSL

In most cases these are found in the driver store or Microsoft Office ODBC drivers

These are known issues with Microsoft Office installs due to the Salesforce Add-In that used to be bundled with
some versions of the Office installers.

#>

Start-Transcript -Path 'C:\Utils\Patching_OpenSSLVulnerabilities.log' -IncludeInvocationHeader

$ProgressPreference = 'SilentlyContinue'
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12


## Office 16 Vulnerable OpenSSL File Check
$OpenSSL_VulnerableFilesCHECK = @('c:\program files\windowsapps\ad2f1837.hppchardwarediagnosticswindows_2.2.0.0_x64__v10z8vjag6ke6\libcrypto-3-x64.dll'
    'c:\windows\system32\driverstore\filerepository\asussci2.inf_amd64_60af290ae625a8bf\asuslinknear\libcrypto-3-x64.dll'
    'c:\windows\system32\driverstore\filerepository\asussci2.inf_amd64_aeff025f0108fb44\asuslinknear\libcrypto-3-x64.dll'
    'c:\program files\gimp 2\32\bin\libcrypto-3.dll'
    'c:\program files\gimp 2\32\bin\libssl-3.dll'
    'c:\program files\gimp 2\bin\libcrypto-3-x64.dll'
    'c:\program files\gimp 2\bin\libssl-3-x64.dll')

foreach ($File in $OpenSSL_VulnerableFilesCHECK)
{

    $FileCheck = Test-Path $File
    If ($FileCheck -eq $true)
    {

        "Vulnerable files found - Deleting $File"
        Remove-Item $File -Force -ErrorAction SilentlyContinue -Verbose
    }
    else
    {

        'No Vulnerable files found'
    }
}


Stop-Transcript

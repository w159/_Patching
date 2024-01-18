If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) 
    {
        Write-Warning "You are not running as Admin."
        Break
    }
 

#uninstall apps
& "$PSScriptRoot\uninstall_apps.ps1"

#get lenovo vantage service uninstall string to uninstall service
$lvs = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | where DisplayName -eq "Lenovo Vantage Service"
If (!([string]::IsNullOrEmpty($lvs.QuietUninstallString)))
{
   $uninstall = "cmd /c " + $lvs.QuietUninstallString
   Write-Host $uninstall
   Invoke-Expression $uninstall
}
 

#uninstall ImController service
Invoke-Expression -Command 'cmd.exe /c "c:\windows\system32\ImController.InfInstaller.exe" -uninstall'

#remove vantage associated registry keys
Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\E046963F.LenovoCompanion_k1h2ywk1493x8' -Recurse -ErrorAction SilentlyContinue
Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\ImController' -Recurse -ErrorAction SilentlyContinue
Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\Lenovo Vantage' -Recurse -ErrorAction SilentlyContinue
Remove-Item 'HKLM:\SOFTWARE\Policies\Lenovo\Commercial Vantage' -Recurse -ErrorAction SilentlyContinue
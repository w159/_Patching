$ServerIP = ""

Get-NetConnectionProfile | Where NetworkCategory -EQ Public | Set-NetConnectionProfile -NetworkCategory Private
Set-Service -Name RemoteRegistry -StartupType Automatic
Start-Service -Name RemoteRegistry
Enable-PSRemoting -Force

Set-NetFirewallRule -Name 'WINRM-HTTP-In-TCP' -RemoteAddress $ServerIP
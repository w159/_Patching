Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Scope Process
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -Force
Install-Module -Name PSWindowsUpdate -Force
Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -Install

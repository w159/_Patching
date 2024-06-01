



#!ps
#maxlength=50000
#timeout=900000
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
Set-ExecutionPolicy Bypass -Scope Process -Force
$folders = @(
     'C:\Windows\Temp\LSUPackages',
     'C:\Windows\Temp\*',
     'C:\Drivers',
     'C:\Users\itderek',
     'C:\Users\wa-velarde',
     'C:\Users\ADMIN',
     'C:\Users\s5ladmin',
     'C:\Users\ladmin',
     'C:\Users\da-evelarde',
     'C:\wazuh-agent'
)
foreach ($folder in $folders) {
     Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
}
Install-Module -Name 'LSUClient'
Import-Module -Name 'LSUClient'
$updates = Get-LSUpdate -All | Where-Object { $_.IsApplicable -eq 'True' -and $_.IsInstalled -eq 'False' }
$updates | Save-LSUpdate -Verbose
$updates | Install-LSUpdate -Verbose









#!ps
#maxlength=50000
#timeout=900000
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
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
Get-LSUpdate
$updates = Get-LSUpdate
$updates | Save-LSUpdate -Verbose
$updates | Install-LSUpdate -Verbose







Install-Module -Name 'LSUClient'
Import-Module -Name 'LSUClient'
$updates = Get-LSUpdate | Where-Object { $_.Installer.Unattended }
$updates | Save-LSUpdate -Verbose
$updates | Install-LSUpdate -Verbose


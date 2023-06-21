[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://onedrive.live.com/download?cid=AF928892EBCFB343&resid=AF928892EBCFB343%21108581&authkey=AHxfpxkbaZaxFyQ" -OutFile "C:\utils\Dell-Command-Update-Application_XM3K1_WIN_4.2.1_A00.EXE"
Start-Process C:\utils\Dell-Command-Update-Application_XM3K1_WIN_4.2.1_A00.EXE -ArgumentList "/s /e=C:\utils\dcu_exe" -WindowStyle Hidden
Unblock-File C:\utils\Dell-Command-Update-Application_XM3K1_WIN_4.2.1_A00.EXE -Confirm:$false
Start-Process C:\utils\dcu_exe\DCU_Setup_4_2_1.exe -ArgumentList "/S /v/qn" -WindowStyle Hidden
Start-Service -Name DellClientManagementService
Start-Process "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/applyUpdates" -WindowStyle Hidden
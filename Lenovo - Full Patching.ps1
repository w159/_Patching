New-Item -Path C:\ -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue
Invoke-WebRequest -UseBasicParsing 'https://download.lenovo.com/pccbbs/thinkvantage_en/system_update_5.07.0140.exe' -OutFile 'C:\utils\system_update_5.07.0140.exe'
Start-Process "C:\utils\system_update_5.07.0140.exe" -ArgumentList "/VERYSILENT /NORESTART" -WindowStyle Hidden
Start-Process "C:\Program Files (x86)\Lenovo\System Update\Tvsu.exe" -ArgumentList "/CM -search A -action INSTALL -noicon -includerebootpackages 1,3,4 -noreboot" -WindowStyle Hidden
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -Force
Install-Module -Name PSWindowsUpdate -Force
Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -Install

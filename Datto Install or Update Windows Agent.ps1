[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://cf-dl.datto.com/dwa/DattoWindowsAgent.exe" -OutFile C:\DattoAgent.exe
Unblock-File C:\DattoAgent.exe -Confirm:$false
C:\DattoAgent.exe /install /quiet /norestart
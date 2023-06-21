$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Invoke-WebRequest -UseBasicParsing 'https://ftp.hp.com/pub/softpaq/sp146001-146500/sp146042.exe' -OutFile 'C:\utils\HPSupportAssistant.exe'
Start-Process "C:\utils\HPSupportAssistant.exe" -ArgumentList '/s /e /f "C:\Utils\HPSupportAssistant"' -WindowStyle Hidden -Wait
Start-Process "C:\utils\HPSupportAssistant\msiinstaller.exe" -ArgumentList '/S /v/qn' -WindowStyle Hidden -Wait


Start-Process "C:\Utils\HPImageAssistant\HPImageAssistant.exe" -ArgumentList '/Operation:DownloadSoftPaqs /Action:Extract /ReportFolder:c:\Utils\HPIA\Report /SoftPaqDownloadFolder:"c:\Utils\HPIA\download" /RunHidden' -WindowStyle Hidden -Wait

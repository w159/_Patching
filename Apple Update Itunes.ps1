New-Item -Path C:\ -Name Utils -ItemType Directory -Force
Invoke-WebRequest -Uri "https://3pp.ltinternal.com/files/Apple/AppleMobileDeviceSupport64-16.0.0.30.msi" -OutFile "C:\Utils\AppleMobileDeviceSupport64-16.0.0.30.msi"
Invoke-WebRequest -Uri "https://3pp.ltinternal.com/files/Apple/iTunes64-12.12.6.1.msi" -OutFile "C:\iTunes64-12.12.6.1.msi"
Invoke-WebRequest -Uri "https://3pp.ltinternal.com/files/Apple/AppleApplicationSupport64-8.6.msi" -OutFile "C:\AppleApplicationSupport64-8.6.msi"
Invoke-WebRequest -Uri "https://3pp.ltinternal.com/files/Apple/Bonjour64-3.1.0.1.msi" -OutFile "C:\Bonjour64-3.1.0.1.msi"

msiexec.exe /qn /norestart /i "C:\Bonjour64-3.1.0.1.msi"
msiexec.exe /qn /norestart /i "C:\AppleApplicationSupport64-8.6.msi"
msiexec.exe /qn /norestart /i "C:\iTunes64-12.12.6.1.msi"
msiexec.exe /qn /norestart /i "C:\Utils\AppleMobileDeviceSupport64-16.0.0.30.msi"
pushd 
@echo off
goto check_Permissions

:check_Permissions
 net session >nul 2>&1
 if %errorLevel% == 0 (
 echo Success: Administrative permissions confirmed.
 ) else (
 echo Fail: re-run this script as Administrator
goto exit
 )

powershell.exe -ExecutionPolicy Bypass -File "%~dp0uninstall_all.ps1"

echo Must reboot to take effect

:exit
popd

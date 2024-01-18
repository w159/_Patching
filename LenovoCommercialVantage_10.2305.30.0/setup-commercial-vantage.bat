pushd %~dp0

rem unblock all Files....
powershell -command "dir -Path .\ -Recurse | Unblock-File"

rem UNINSTALL ANY PREVIOUS VERSION OF VANTAGE/COMPANION/SETTINGS
powershell -executionpolicy bypass -file .\uninstall_vantage_v8\uninstall_apps.ps1

rem DEPLOY THE POLICY CONFIGURATION (optional - see deployment guide)
rem regedit /s sample-policy-config.reg
rem regedit /s VantageDisableAutomaticSystemUpdates.reg

rem INSTALL THE APPLICATION - COMMERCIAL VANTAGE
powershell -executionpolicy bypass -file lenovo-commercial-vantage-install.ps1

rem SKIP THE INSTALLATION/CONFIGURATION OF LSIF ON ARM MACHINES
IF "%PROCESSOR_ARCHITECTURE%"=="ARM64" (goto InstallVantageService)

rem CONFIGURE LSIF SO THAT ONLY COMMERCIAL VANTAGE PLUGINS ARE INSTALLED (required)
regedit /s SifRequireAppAssociation.reg

rem DISABLE LSIF SELF-UPDATES (optional - see deployment guide)
rem regedit /s SifDisableSelfUpdate.reg

rem INSTALL/UPDATE LSIF
System-Interface-Foundation-Update-64.exe /verysilent /NORESTART

rem UPDATE LSIF PLUGINS
net stop imcontrollerservice
del %programdata%\lenovo\imcontroller\ImControllerSubscription.xml
del %programdata%\lenovo\imcontroller\temp\ImControllerSubscription.xml
%windir%\lenovo\imcontroller\service\lenovo.modern.imcontroller.exe /installsubscription .\plugins\ImControllerSubscription-1.1.xml
mkdir %programdata%\lenovo\imcontroller\temp
copy /Y %programdata%\lenovo\imcontroller\ImControllerSubscription.xml %programdata%\lenovo\imcontroller\temp\ImControllerSubscription.xml
attrib +r %programdata%\lenovo\imcontroller\ImControllerSubscription.xml
attrib +r %programdata%\lenovo\imcontroller\temp\ImControllerSubscription.xml
%windir%\lenovo\imcontroller\service\lenovo.modern.imcontroller.exe /installpackageswithreboot .\plugins
net start imcontrollerservice
attrib -r %programdata%\lenovo\imcontroller\temp\ImControllerSubscription.xml
attrib -r %programdata%\lenovo\imcontroller\ImControllerSubscription.xml

:InstallVantageService
rem INSTALL VANTAGE SERVICE
powershell -executionpolicy bypass -file .\VantageService\Install-VantageService.ps1

rem INSTALL VANTAGE SERVICE ADDINS
net stop LenovoVantageService
rem wait 3 seconds
ping -n 4 127.0.0.1 > nul
rem ensure addins not running
taskkill /im LenovoVantage* /f
if exist .\LVSAddins (
xcopy .\LVSAddins\*  %PROGRAMDATA%\Lenovo\Vantage\ /s /y
)

rem post copy deployment (update addin lists)
powershell -executionpolicy bypass -file .\VantageService\Update-AddinComponents.ps1

net start LenovoVantageService

popd
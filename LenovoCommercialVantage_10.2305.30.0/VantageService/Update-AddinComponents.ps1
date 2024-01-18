# update the registry key 
#  HKLM\SOFTWARE\LENOVO\VantageService  32bitview
#  IsProloadInstallCompleted = "false"
pushd $PSScriptRoot

# update hypothesis and config servcie.
&./VantageComponentUpdater.exe

popd
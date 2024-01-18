#1 extract service cab file
pushd $PSScriptRoot
$svcCab = Get-ChildItem "VantageService.*.ms.cab"

$svcCab.Name -match "\d+\.\d+\.\d+\.0"
$version = $Matches[0]
$svcCab.FullName
if(Test-Path $version)
{
	Remove-Item $version -Recurse -Force
}

mkdir $version
$targetDir = Get-Item $version
&expand.exe "$($svcCab.FullName)" -F:*  "$($targetDir.FullName)"

mkdir "C:\Program Files (x86)\Lenovo\VantageService\$version"
#2 copy files to C:\Program Files (x86)\Lenovo\VantageService\#Version\
get-item "$version\*" | 
Copy-Item -Destination "C:\Program Files (x86)\Lenovo\VantageService\$version\" -Recurse

#3 execute SignedExeLauncher.exe , pass the full path of the exe and the parameters.
$installerHelper = Get-ChildItem "C:\Program Files (x86)\Lenovo\VantageService\$version\Lenovo.VantageService.InstallerHelper.exe"

if($installerHelper.Exists)
{
	# execute installer helper.
    &.\SignedExeLauncher.exe "`"$($installerHelper.FullName)`"" "/Install" "TmpFolder: " "`"InstFolder:`"`"C:\Program Files (x86)\Lenovo\VantageService\$version\`"" "InstParam: "
}

popd
#need to modify these for every new version
$path = "AppPackage"
$bundleName = "f45a091fae124a98955c1445cabbdeae"

#should not need to modify these very often
$frameworkName = "Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x64__8wekyb3d8bbwe.appx"
$runtimeName = "Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x64__8wekyb3d8bbwe.appx"
$vcLibsName = "Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe.appx"

#should never need to modify anything below this
$bundlePath = ".\" + $path + "\" + $bundleName + ".msixbundle"
$licensePath = ".\" + $path + "\" + $bundleName + "_License1.xml"
$frameworkPath = ".\" + $path + "\" + $frameworkName
$runtimePath = ".\" + $path + "\" + $runtimeName
$vcLibsPath = ".\" + $path + "\" + $vcLibsName

$command = "Add-AppxProvisionedPackage -Online -PackagePath $bundlePath -LicensePath $licensePath -DependencyPackagePath $frameworkPath,$runtimePath,$vcLibsPath -Region all"
$command
Invoke-Expression $command
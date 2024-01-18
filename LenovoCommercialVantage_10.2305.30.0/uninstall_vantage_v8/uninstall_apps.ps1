$AppList = "E046963F.LenovoCompanion",           
           "LenovoCorporation.LenovoSettings",
           "E046963F.LenovoSettingsforEnterprise"

ForEach ($App in $AppList)
{
   $PackageFullName = (Get-AppxPackage -allusers $App).PackageFullName
   $ProPackageFullName = (Get-AppxProvisionedPackage -online | where {$_.Displayname -eq $App}).PackageName
  
   ForEach ($AppToRemove in $PackageFullName)
   {
     Write-Host "Removing Package: $AppToRemove"
     try
     {
        remove-AppxPackage -package $AppToRemove -allusers
     }
     catch
     {
        # Starting in Win10 20H1, bundle apps (like Vantage) have to be removed a different way
        $PackageBundleName = (Get-AppxPackage -packagetypefilter bundle -allusers $App).PackageFullName
        ForEach ($BundleAppToRemove in $PackageBundleName)
        {
           remove-AppxPackage -package $BundleAppToRemove -allusers
        }
     }
   }

   ForEach ($AppToRemove in $ProPackageFullName)
   {
     Write-Host "Removing Provisioned Package: $AppToRemove"
     try
     {
        Remove-AppxProvisionedPackage -online -packagename $AppToRemove
     }
     catch
     {
        # bundled/provisioned apps are already removed by "remove-AppxPackage -allusers"
     }
   }

}
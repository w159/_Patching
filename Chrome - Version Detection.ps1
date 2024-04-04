$ChromiumTeamGitAPI = Invoke-RestMethod -UseBasicParsing 'https://versionhistory.googleapis.com/v1/chrome/platforms/all/channels/all/versions/'
$ChromeCurrentVersion = $ChromiumTeamGitAPI.Versions | Where-Object { $_.name -like 'chrome/platforms/win64/channels/stable/versions/*' } | Sort-Object -Descending | Select-Object -First 1 | Select-Object -ExpandProperty version
$ChromeVersion = Get-WmiObject win32_product | Where-Object Name -Like *Chrome* | Select-Object -ExpandProperty Version -ErrorAction SilentlyContinue
$ChromeInstalledVersionX86 = (Get-Item 'C:\Program Files (x86)\Google\Chrome\Application\Chrome.exe' -ErrorAction SilentlyContinue).VersionInfo | Select-Object -ExpandProperty ProductVersion
$ChromeInstalledVersion = (Get-Item 'C:\Program Files\Google\Chrome\Application\Chrome.exe' -ErrorAction SilentlyContinue).VersionInfo | Select-Object -ExpandProperty ProductVersion
$Versions = @(
     @{Name = 'Chrome WMI'; Version = $ChromeVersion },
     @{Name = 'Chrome 64-bit'; Version = $ChromeInstalledVersion },
     @{Name = 'Chrome 32-bit'; Version = $ChromeInstalledVersionX86 }
)

$VersionsToUpdate = $Versions | Where-Object { !([string]::IsNullOrEmpty($_.Version) -or $_.Version -eq $ChromeCurrentVersion) }

if ($VersionsToUpdate)
{
     Write-Host "Not Compliant - Updating Chrome to the latest version $ChromeCurrentVersion."
     Exit 1
}
else
{
     Write-Host "Compliant - All versions of Chrome installed on this computer match the latest version of $ChromeCurrentVersion."
     Exit 0
}

$webContent = Invoke-WebRequest -UseBasicParsing "https://www.java.com/en/download/manual.jsp"
$content = $webContent.Content

# Regular expressions to extract the download URLs
$pattern32Bit = '<a href="(https:\/\/javadl\.oracle\.com\/webapps\/download\/AutoDL\?BundleId=[^"]+)".*?title="Download Java software for Windows Offline">'
$pattern64Bit = '<a href="(https:\/\/javadl\.oracle\.com\/webapps\/download\/AutoDL\?BundleId=[^"]+)".*?title="Download Java software for Windows \(64-bit\)">'

$latestVersionURL32Bit = [regex]::Match($content, $pattern32Bit).Groups[1].Value
$latestVersionURL64Bit = [regex]::Match($content, $pattern64Bit).Groups[1].Value

Write-Host "Latest 32-bit Java version: $latestVersionURL32Bit"
Write-Host "Latest 64-bit Java version: $latestVersionURL64Bit"




$latestVersionUrl = "https://www.java.com/en/download/manual.jsp"
$webContent = Invoke-WebRequest -UseBasicParsing $latestVersionUrl

# Get 32-bit version
$pattern32 = '(?<=Windows Offline<\/a><\/strong><\/p><p><strong>Version )[\d._]+(?=<\/strong><\/p>)'
$match32 = [regex]::Match($webContent.Content, $pattern32)
$latestVersion32 = $match32.Value

# Get 64-bit version
$pattern64 = '(?<=Windows Offline \(64-bit\)<\/a><\/strong><\/p><p><strong>Version )[\d._]+(?=<\/strong><\/p>)'
$match64 = [regex]::Match($webContent.Content, $pattern64)
$latestVersion64 = $match64.Value

Write-Host "Latest 32-bit Java version: $latestVersion32"
Write-Host "Latest 64-bit Java version: $latestVersion64"


# Get the latest Java version information from Oracle API
$latestVersionUrl = "$apiUrl/java-se-v1/release-version"
$latestVersionResponse = Invoke-RestMethod -Uri $latestVersionUrl
$latestVersion = $latestVersionResponse.release_version

# Check if Java is already installed
$javaInstalled = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "Java*" }

if ($javaInstalled) {
    Write-Host "Java is already installed. Checking the installed versions..."

    foreach ($java in $javaInstalled) {
        $installedVersion = $java.Name -replace "Java ", ""

        if ($installedVersion -ne $latestVersion) {
            Write-Host "Uninstalling Java version $installedVersion..."
            $uninstallString = $java.UninstallString
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/x `"$uninstallString`" /qn" -Wait
            Write-Host "Java version $installedVersion uninstalled."
        }
    }
}

Write-Host "Installing the latest Java version: $latestVersion"
$installerUrl = "$apiUrl/java-se-v1/downloads"
$installerRequestBody = @{ feature = "jdk" } | ConvertTo-Json
$installerResponse = Invoke-RestMethod -Uri $installerUrl -Method Post -Body $installerRequestBody -ContentType "application/json"
$installerPath = "$env:TEMP\java_installer.msi"
Invoke-WebRequest -Uri $installerResponse.uri -OutFile $installerPath
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn" -Wait
Write-Host "Java version $latestVersion installed successfully."

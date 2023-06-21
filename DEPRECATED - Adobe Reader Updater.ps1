
<#

.DESCRIPTION
This checks for Adobe Reader install status
If installed the current latest version is checked and compared to what's installed
If it's not the latest version, then the application is then updated

#>

$CurrentReaderVersion = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Where-Object { $_.DisplayName -like "*Adobe*" -and $_.DisplayName -like "*Reader*" }

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'

# If reader is installed then...
If ($null -ne $CurrentReaderVersion) {

    # Cleanup version number
    $CurrentReaderVersion = ($CurrentReaderVersion.DisplayVersion.ToString()).Replace(".", "")
    # Set download folder and ftp folder variables
    $DownloadFolder = "C:\Windows\Temp\"
    $FTPFolderUrl = "ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/"
    # Connect to Adobe ftp, and get directory listing
    $FTPRequest = [System.Net.FtpWebRequest]::Create("$FTPFolderUrl")
    $FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
    $FTPResponse = $FTPRequest.GetResponse()
    $ResponseStream = $FTPResponse.GetResponseStream()
    $FTPReader = New-Object System.IO.Streamreader -ArgumentList $ResponseStream
    $DirList = $FTPReader.ReadToEnd()

    # From Directory Listing get last entry in list, but skip one to avoid the 'misc' dir
    $LatestUpdate = $DirList -split '[\r\n]' | Where-Object { $_ } | Select-Object -Last 1 -Skip 1

    # Compare latest availiable update version to currently installed version.
    If ($LatestUpdate -ne $CurrentReaderVersion) {
        # Build file name
        $LatestFile = "AcroRdrDC" + $LatestUpdate + "_en_US.exe"
        # Build download url for latest file
        $DownloadURL = "$FTPFolderUrl$LatestUpdate/$LatestFile"
        # Build filepath
        $FilePath = "$DownloadFolder$LatestFile"
        "1. Downloading latest Reader version."
        (New-Object System.Net.WebClient).DownloadFile($DownloadURL, $FilePath)
        "2. Installing."
        Start-Process $FilePath /sAll -NoNewWindow -Wait
        "3. Cleaning."
        Remove-Item -Path $FilePath
    }
    Else
    { "Latest version already installed." }
}
Else
{ "Reader not installed." }


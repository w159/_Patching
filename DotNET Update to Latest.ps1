# Get the latest version of .NET from the Microsoft website

$webrequest = Invoke-RestMethod -UseBasicParsing 'https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json' | Select-Object -ExpandProperty releases-index
$LatestDotNetVersion = $webrequest | Where-Object 'support-Phase' -EQ 'active' | Select-Object -ExpandProperty releases.json | ForEach-Object {
    Invoke-RestMethod -UseBasicParsing $_ | Select-Object -ExpandProperty 'latest-release'
}

Write-Host "Latest .NET version is $LatestDotNetVersion"

# Get a list of installed .NET versions
$InstalledDotNetVersions = Get-ItemPropertyValue -LiteralPath 'HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release
switch ($release)
{
    { $_ -ge 533320 } { $version = '4.8.1 or later'; break }
    { $_ -ge 528040 } { $version = '4.8'; break }
    { $_ -ge 461808 } { $version = '4.7.2'; break }
    { $_ -ge 461308 } { $version = '4.7.1'; break }
    { $_ -ge 460798 } { $version = '4.7'; break }
    { $_ -ge 394802 } { $version = '4.6.2'; break }
    { $_ -ge 394254 } { $version = '4.6.1'; break }
    { $_ -ge 393295 } { $version = '4.6'; break }
    { $_ -ge 379893 } { $version = '4.5.2'; break }
    { $_ -ge 378675 } { $version = '4.5.1'; break }
    { $_ -ge 378389 } { $version = '4.5'; break }
    default { $version = $null; break }
}



if ($version)
{
    Write-Host -Object ".NET Framework Version: $version"
}
else
{
    Write-Host -Object '.NET Framework Version 4.5 or later is not detected.'
}


Write-Host 'Installed .NET versions:'
Write-Host $InstalledDotNetVersions

# Update each installed .NET version to the latest version
ForEach ($CurrentDotNetVersion in $InstalledDotNetVersions)
{
    if ($CurrentDotNetVersion -lt $LatestDotNetVersion)
    {
        Write-Host "Current .NET version is $($CurrentDotNetVersion), the latest version is $($LatestDotNetVersion). Updating..."

        # Download the latest .NET version
        $DownloadUrl = "https://download.visualstudio.microsoft.com/download/pr/87ed84da-c05d-4251-9430-b14e538e8a4a/d05deada5bdc51b68cb3e3f673b06807/runtime-desktop-$LatestDotNetVersion-windows-x64.exe"
        $DownloadPath = "$env:TEMP\dotnet.exe"
        Unblock-File $DownloadPath -ErrorAction SilentlyContinue
        New-Item -Path C:\ -Name Utils -Force -ErrorAction SilentlyContinue
        Invoke-WebRequest -UseBasicParsing $DownloadUrl -OutFile $DownloadPath

        # Install the latest .NET version
        Start-Process -FilePath $DownloadPath -ArgumentList '/quiet /norestart' -Wait
        Remove-Item $DownloadPath
    }
    else
    {
        Write-Host "Current .NET version $($CurrentDotNetVersion) is up to date."
    }
}


function InstallDotNetRuntimes
{
    try
    {
        # Check the internet connection
        $Parameters = @{
            Uri              = 'https://www.google.com'
            Method           = 'Head'
            DisableKeepAlive = $true
            UseBasicParsing  = $true
        }
        if (-not (Invoke-WebRequest @Parameters).StatusDescription)
        {
            return
        }

        if ([System.Version](Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction Ignore).Version -ge [System.Version]'1.17')
        {
            # https://github.com/microsoft/winget-pkgs/tree/master/manifests/m/Microsoft/DotNet/DesktopRuntime/6
            # .NET Desktop Runtime 6 x86
            winget install --id=Microsoft.DotNet.DesktopRuntime.6 --architecture x86 --exact --accept-source-agreements
            # .NET Desktop Runtime 6 x64
            winget install --id=Microsoft.DotNet.DesktopRuntime.6 --architecture x64 --exact --accept-source-agreements

            # https://github.com/microsoft/winget-pkgs/tree/master/manifests/m/Microsoft/DotNet/DesktopRuntime/7
            # .NET Desktop Runtime 7 x86
            winget install --id=Microsoft.DotNet.DesktopRuntime.7 --architecture x86 --exact --accept-source-agreements
            # .NET Desktop Runtime 7 x64
            winget install --id=Microsoft.DotNet.DesktopRuntime.7 --architecture x64 --exact --accept-source-agreements

            # PowerShell 5.1 (7.3 too) interprets 8.3 file name literally, if an environment variable contains a non-latin word
            Get-ChildItem -Path "$env:TEMP\WinGet" -Force -ErrorAction Ignore | Remove-Item -Recurse -Force -ErrorAction Ignore
        }
        else
        {
            # Install .NET Desktop Runtime 6
            # https://github.com/dotnet/core/blob/main/release-notes/releases-index.json
            $Parameters = @{
                Uri             = 'https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/6.0/releases.json'
                Verbose         = $true
                UseBasicParsing = $true
            }
            $LatestRelease = (Invoke-RestMethod @Parameters).'latest-release'
            $DownloadsFolder = Get-ItemPropertyValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

            # .NET Desktop Runtime 6 x86
            $Parameters = @{
                Uri             = "https://dotnetcli.azureedge.net/dotnet/Runtime/$LatestRelease/dotnet-runtime-$LatestRelease-win-x86.exe"
                OutFile         = "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x86.exe"
                UseBasicParsing = $true
                Verbose         = $true
            }
            Invoke-WebRequest @Parameters

            Start-Process -FilePath "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x86.exe" -ArgumentList '/install /passive /norestart' -Wait

            # .NET Desktop Runtime 6 x64
            $Parameters = @{
                Uri             = "https://dotnetcli.azureedge.net/dotnet/Runtime/$LatestRelease/dotnet-runtime-$LatestRelease-win-x64.exe"
                OutFile         = "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x64.exe"
                UseBasicParsing = $true
                Verbose         = $true
            }
            Invoke-WebRequest @Parameters

            Start-Process -FilePath "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x64.exe" -ArgumentList '/install /passive /norestart' -Wait

            # PowerShell 5.1 (7.3 too) interprets 8.3 file name literally, if an environment variable contains a non-latin word
            $Paths = @(
                "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x86.exe",
                "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x64.exe",
                "$env:TEMP\Microsoft_.NET_Runtime*.log"
            )
            Get-ChildItem -Path $Paths -Force -ErrorAction Ignore | Remove-Item -Recurse -Force -ErrorAction Ignore

            # .NET Desktop Runtime 7
            # https://github.com/dotnet/core/blob/main/release-notes/releases-index.json
            $Parameters = @{
                Uri             = 'https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/7.0/releases.json'
                Verbose         = $true
                UseBasicParsing = $true
            }
            $LatestRelease = (Invoke-RestMethod @Parameters).'latest-release'
            $DownloadsFolder = Get-ItemPropertyValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -Name '{374DE290-123F-4565-9164-39C4925E467B}'

            # .NET Desktop Runtime 7 x86
            $Parameters = @{
                Uri             = "https://dotnetcli.azureedge.net/dotnet/Runtime/$LatestRelease/dotnet-runtime-$LatestRelease-win-x86.exe"
                OutFile         = "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x86.exe"
                UseBasicParsing = $true
                Verbose         = $true
            }
            Invoke-WebRequest @Parameters

            Start-Process -FilePath "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x86.exe" -ArgumentList '/install /passive /norestart' -Wait

            # .NET Desktop Runtime 7 x64
            $Parameters = @{
                Uri             = "https://dotnetcli.azureedge.net/dotnet/Runtime/$LatestRelease/dotnet-runtime-$LatestRelease-win-x64.exe"
                OutFile         = "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x64.exe"
                UseBasicParsing = $true
                Verbose         = $true
            }
            Invoke-WebRequest @Parameters

            Start-Process -FilePath "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x64.exe" -ArgumentList '/install /passive /norestart' -Wait

            # PowerShell 5.1 (7.3 too) interprets 8.3 file name literally, if an environment variable contains a non-latin word
            $Paths = @(
                "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x86.exe",
                "$DownloadsFolder\dotnet-runtime-$LatestRelease-win-x64.exe",
                "$env:TEMP\Microsoft_.NET_Runtime*.log"
            )
            Get-ChildItem -Path $Paths -Force -ErrorAction Ignore | Remove-Item -Recurse -Force -ErrorAction Ignore
        }
    }
    catch [System.Net.WebException]
    {
        Write-Warning -Message $Localization.NoInternetConnection
        Write-Error -Message $Localization.NoInternetConnection -ErrorAction SilentlyContinue

        Write-Error -Message ($Localization.RestartFunction -f $MyInvocation.Line.Trim()) -ErrorAction SilentlyContinue
    }
}


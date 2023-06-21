
$Manufacturer = Get-WmiObject win32_bios | Select-Object -ExpandProperty Manufacturer
New-Item -Path C:\ -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue

If ($Manufacturer -like '*Dell*') {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                New-Item -Path C:\ -Name Utils -ItemType Directory -Force -ErrorAction SilentlyContinue

                $userAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
                Invoke-WebRequest -UseBasicParsing 'https://dl.dell.com/FOLDER09622916M/1/Dell-Command-Update-Application_714J9_WIN_4.8.0_A00.EXE' -UserAgent $userAgent -OutFile 'C:\utils\Dell-Command.EXE'
                Remove-Item "C:\Utils\dcu_exe" -Recurse -Force
                Start-Process "C:\utils\Dell-Command.EXE" -ArgumentList "/s /e=C:\utils\dcu_exe" -WindowStyle Hidden -Wait
                Unblock-File "C:\utils\Dell-Command.EXE" -Confirm:$false
                Start-Process "C:\utils\dcu_exe\DCU_Setup*.exe" -ArgumentList "/S /v/qn" -WindowStyle Hidden -Wait
                Start-Service -Name "DellClientManagementService"

        $DCU_x86 = "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
        $DCU_x64 = "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"

     If ($DCU_x86 -eq $true){

        Start-Process "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/configure -userConsent=disable -updatesNotification=disable -autoSuspendBitLocker=enable -updateSeverity=security,critical,recommended -updateType=bios,firmware,driver -lockSettings=enable" -WindowStyle Hidden -Wait
        Start-Process "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/applyUpdates -silent -forceUpdate=enable -reboot=disable" -WindowStyle Hidden -Wait -Wait

                        }

     If ($DCU_x64 -eq $true){

        Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/configure -userConsent=disable -updatesNotification=disable -autoSuspendBitLocker=enable -updateSeverity=security,critical,recommended -updateType=bios,firmware,driver -lockSettings=enable" -WindowStyle Hidden -Wait
        Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/applyUpdates -silent -forceUpdate=enable -reboot=disable" -WindowStyle Hidden -Wait

                        }
                                 }

If ($Manufacturer -like '*Lenovo*') {

        Invoke-WebRequest -UseBasicParsing 'https://download.lenovo.com/pccbbs/thinkvantage_en/system_update_5.07.0140.exe' -OutFile 'C:\utils\system_update_5.07.0140.exe'
                    Start-Process "C:\utils\system_update_5.07.0140.exe" -ArgumentList "/VERYSILENT /NORESTART" -WindowStyle Hidden -Wait
                    Start-Sleep -Seconds 60
                    Start-Process "C:\Program Files (x86)\Lenovo\System Update\Tvsu.exe" -ArgumentList "/CM -search A -action INSTALL -noicon -includerebootpackages 1,3,4,5 -noreboot" -WindowStyle Hidden -Wait

}

If ($Manufacturer -like '*HP*' -xor '*Hewlett*') {

        Invoke-WebRequest -UseBasicParsing 'https://ftp.hp.com/pub/softpaq/sp114001-114500/sp114036.exe' -OutFile 'C:\utils\sp114036.exe'
                    Start-Process "C:\utils\sp114036.exe" -ArgumentList '/s /e /f "C:\Utils\HPSA8"' -WindowStyle Hidden -Wait
                    Start-Sleep -Seconds 60
                    Start-Process "C:\Utils\HPSA8\InstallHPSA.exe" -ArgumentList "/S /v/qn" -WindowStyle Hidden -Wait

}


# Install Windows updates, postpone reboot
# Installs ALL available updates, including optional and drivers

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -Force
Install-Module -Name PSWindowsUpdate -Force
Import-Module PSWindowsUpdate; Install-WindowsUpdate -AcceptAll -Install -AutoReboot:$false

# Prompt user for reboot
# Do prompt until time end is reached

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | out-null
$TimeStart = Get-Date
$TimeEnd = $timeStart.addminutes(360)

Do
{
    $TimeNow = Get-Date
    if ($TimeNow -ge $TimeEnd)
    {
        
        Unregister-Event -SourceIdentifier click_event -ErrorAction SilentlyContinue
        Remove-Event click_event -ErrorAction SilentlyContinue
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        Exit
    }
    else
    {
        $Balloon = new-object System.Windows.Forms.NotifyIcon
        $Balloon.Icon = [System.Drawing.SystemIcons]::Information
        $Balloon.BalloonTipText = "IT is requiring a reboot in order to maintain system stability supporting IT security measures. Please reboot at your earliest convenience."
        $Balloon.BalloonTipTitle = "Reboot Required"
        $Balloon.BalloonTipIcon = "Warning"
        $Balloon.Visible = $true;
        $Balloon.ShowBalloonTip(20000);
        $Balloon_MouseOver = [System.Windows.Forms.MouseEventHandler]{ $Balloon.ShowBalloonTip(20000) }
        $Balloon.add_MouseClick($Balloon_MouseOver)
        Unregister-Event -SourceIdentifier click_event -ErrorAction SilentlyContinue
        Register-ObjectEvent $Balloon BalloonTipClicked -sourceIdentifier click_event -Action {
            Add-Type -AssemblyName Microsoft.VisualBasic
            
            If ([Microsoft.VisualBasic.Interaction]::MsgBox('Would you like to reboot your machine now?', 'YesNo,MsgBoxSetForeground,Question', 'System Maintenance') -eq "NO")
            { }
            else
            {
                shutdown -r -f
            }
            
        } | Out-Null
        
        Wait-Event -timeout 3600 -sourceIdentifier click_event > $null
        Unregister-Event -SourceIdentifier click_event -ErrorAction SilentlyContinue
        $Balloon.Dispose()
    }

}

Until ($TimeNow -ge $TimeEnd)
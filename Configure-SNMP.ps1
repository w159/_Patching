function Configure-SNMP
{

    <#
    EX - Configure-SNMP -h localhost -communityName public -snmpType 4 -permittedHost DeviceName
    #>

    param (
        [string]$h, [string]$f, [string]$username, [string]$pass, [string]$onlyConfigure, [string]$communityName, [int]   $snmpType, [string]$permittedHost, [string]$debug
    )

    #This function will check and enable SNMP on local and remote machines.
    function EnableSNMPandConfigure
    {
        param([string]$h, [System.Management.Automation.PSCredential]$Credential, [int]$islocal, [string]$communityName, [int]$snmpType, [string]$permittedHost, [string]$onlyConfigure)
        Write-Host "Checking the host's SNMP configuration " $h -ForegroundColor Cyan

        if (Test-Connection -ComputerName $h -Count 1 -Quiet)
        {
            try
            {
                $dbefore = 1

                $isfresh = [int]0
                if ($islocal -eq 1)
                {
                    $dbefore = Get-WmiObject -Class win32_service | Where-Object { $_.DisplayName -eq 'SNMP Service' } | Select-Object displayname, state
                }
                else
                {
                    $dbefore = Invoke-Command -ComputerName $h -script { Get-WmiObject -Class win32_service | Where-Object { $_.DisplayName -eq 'SNMP Service' } | Select-Object displayname, state } -Credential $Credential -ErrorAction Stop
                }
                if ($Global:debugGlobal) { Write-Host "win32_service entries for SNMP $dbefore" -ForegroundColor Gray }


                if ($null -eq $dbefore)
                {
                    if ($onlyConfigure -eq 'true')
                    {
                        Write-Host "The configuration process failed because the SNMP service has not been enabled in the local/ remote device. Please use the '-onlyConfigure true' option, if SNMP has already enabled." -ForegroundColor Red
                        exitProcess
                    }
                    Write-Host 'Enabling SNMP......' -ForegroundColor Magenta
                    if ($islocal -eq 1)
                    {
                        if ($Global:debugGlobal) { Write-Host 'Enabling SNMP in the localhost machine' -ForegroundColor Gray }
                        & 'C:\Windows\System32\Dism.exe' /online /enable-feature /FeatureName:SNMP
                    }
                    else
                    {
                        if ($Global:debugGlobal) { Write-Host " Enabling SNMP in the remote host -$h" -ForegroundColor Gray }
                        Invoke-Command -ComputerName $h -script { & 'C:\Windows\System32\Dism.exe' /online /enable-feature /FeatureName:SNMP } -Credential $Credential
                    }
                    Write-Host "The SNMP Service has been enabled in the host successfully- $h" -ForegroundColor Green

                    try
                    {
                        if ($islocal -eq 1)
                        {
                            if ($Global:debugGlobal) { Write-Host ' Enabling Server-RSAT-SNMP in the localhost' -ForegroundColor Gray }
                            & 'C:\Windows\System32\Dism.exe' /online /enable-feature /FeatureName:Server-RSAT-SNMP /ALL
                        }
                        else
                        {
                            if ($Global:debugGlobal) { Write-Host " Enabling Server-RSAT-SNMP in the remote host -$h" -ForegroundColor Gray }
                            Invoke-Command -ComputerName $h -script { & 'C:\Windows\System32\Dism.exe' /online /enable-feature /FeatureName:Server-RSAT-SNMP /ALL } -Credential $Credential
                        }
                        Write-Host 'Server-RSAT-SNMP Service has been enabled.' -ForegroundColor Green
                    }
                    catch [Exception]
                    {
                        Write-Host 'Failed to enable the server-RSAT-SNMP service due to ' $_.Exception.Message -ForegroundColor Red
                        Write-Host 'Proceeding with the configuration...' -ForegroundColor Cyan
                    }
                    $isfresh = [int]1
                }
                else
                {
                    Write-Host "SNMP has already been enabled in the host - $h" -ForegroundColor Magenta
                }

                if ($Global:debugGlobal) { Write-Host "Is SNMP enabled now? - $isfresh" -ForegroundColor Gray }


                if ($islocal -eq 1)
                {
                    if ($Global:debugGlobal) { Write-Host 'Configuring SNMP settings in the localhost machine' -ForegroundColor Gray }
                    checkandUpdtesnmpTypeandcommunityName -h $h -snmpType $snmpType -communityName $communityName -isfresh $isfresh -islocal $islocal -deviceName $permittedHost
                    restartService
                }
                else
                {
                    if ($Global:debugGlobal) { Write-Host "Configuring SNMP settings in the remote machine- $h" -ForegroundColor Gray }
                    Invoke-Command -ComputerName $h -ScriptBlock ${Function:checkandUpdtesnmpTypeandcommunityName} -Credential $Credential -ArgumentList $h, $snmpType, $communityName, $isfresh, $islocal, $permittedHost -ErrorAction Stop
                    Invoke-Command -ComputerName $h -ScriptBlock ${Function:restartService} -Credential $Credential -ErrorAction Stop
                }
            }
            catch [Exception]
            {
                if ($_.Exception.Message -match 'Access Denied')
                {
                    Write-Host "Incorrect credentials for '$h" -ForegroundColor Red
                }
                elseif ($_.Exception.Message -match 'about_Remote_Troubleshooting')
                {
                    Write-Host "There was an error in establishing connection with $h. Please Enable PSremoting in remote machine $h and try again. (Command Ex. 'Enable-PSRemoting -Force')" -ForegroundColor Red
                }
                elseif ($_.Exception.Message -match 'missing mandatory parameters')
                {
                    Write-Host 'Credentials are empty ' -ForegroundColor Red
                }
                else
                {
                    Write-Host $_.Exception.Message -ForegroundColor Red
                }
            }
        }
        else
        {
            Write-Host "`nMachine' $h  'is not reachable" -ForegroundColor Red
        }
    }

    #This function is used to Start/Restart the SNMPservice
    function restartService()
    {
        $dafter = Get-WmiObject -Class win32_service | Where-Object { $_.DisplayName -eq 'SNMP Service' } | Select-Object displayname, state
        if ($Global:debugGlobal) { Write-Host "Current status of SNMP on- $h - $dafter.state" -ForegroundColor Gray }
        if ($dafter.state -eq 'Running')
        {
            Write-Host 'SNMP service is running. Restarting the SNMP Service after configuration' -ForegroundColor Cyan
            Stop-Service -Name SNMP
            Start-Service -Name SNMP
            Write-Host "The SNMP service has re-started`n" -ForegroundColor Green
        }
        else
        {
            Write-Host 'SNMP service is not running. Starting the SNMP service after configuration' -ForegroundColor Cyan
            Start-Service -Name SNMP
            Write-Host "The SNMP service has started`n" -ForegroundColor Green
        }
    }

    #This function is used to check and add/update the SNMPType, CommunityName, PermittedManager
    function checkandUpdtesnmpTypeandcommunityName
    {
        param([string]$h, [string]$snmpType, [string]$communityName, [int]$isfresh, [int]$islocal, [string]$deviceName)
        try
        {
            Write-Host 'Checking and configuring Communities and Permittedhosts' -ForegroundColor Cyan
            $c1 = New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities -Name $communityName -Value $snmpType -PropertyType 'Dword' -Force
            $c2 = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ValidCommunities -Name $communityName
            if ($c2.$communityName -eq $snmpType)
            {
                Write-Host "`nSNMP community string '$communityName' with '$snmpType' ('1'-NONE / '2'-NOTIFY / '4'-READONLY / '8'-READWRITE / '16' -READCREATE) access added/updated succesfully for host - $env:COMPUTERNAME`n" -ForegroundColor Green
            }
            else
            {
                Write-Host "`nFailed to add/update SNMP community string '$communityName' with '$snmpType' ('1'-NONE / '2'-NOTIFY / '4'-READONLY / '8'-READWRITE / '16' -READCREATE) - $env:COMPUTERNAME `n" -ForegroundColor Green
            }

            $permittedManagers = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers
            if (($isfresh -eq 1) -or (($isfresh -eq 0) -and $permittedManagers -ne $null))
            {
                Write-Host "Adding a host-$deviceName in the Permitted Hosts list" -ForegroundColor Magenta
                $permittedHost = New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers -Name "OpMan-$deviceName" -Value $deviceName -PropertyType 'String' -Force
                $permittedManagers = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers
                Write-Host "Added 'OpMan-$deviceName' Vs '$deviceName' as a permitted manager in the host -$env:COMPUTERNAME" -ForegroundColor Green
            }
            else
            {
                #not for fresh and open to all
                Write-Host 'Permitted Manager is already set as open to all the devices.' -ForegroundColor Green
            }
        }
        catch [Exception]
        {
            if ($_.Exception.Message -match 'Access Denied')
            {
                Write-Host "Credentials are incorrect for '$h" -ForegroundColor Red
            }
            elseif ($_.Exception.Message -match 'about_Remote_Troubleshooting')
            {
                Write-Host "There was error in establishing connection with $h. Please Enable PSremoting in the remote machine $h and try again. (Command Ex. 'Enable-PSRemoting -Force')" -ForegroundColor Red
            }
            elseif ($_.Exception.Message -match 'missing mandatory parameters')
            {
                Write-Host 'Credentials are empty ' -ForegroundColor Red
            }
            else
            {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        }
    }

    #This function is used to print command formats
    function helpCommands()
    {
        Write-Host "`n`n----------------------Syntax of the inputs params------------------`n" -ForegroundColor Red
        Write-Host '1. Enable and configure(with default options) SNMP in the Local Machine' -ForegroundColor Green
        Write-Host "`tCommand To Use      : .\SNMPEnabler.ps1 -h localhost" -ForegroundColor Magenta
        Write-Host '-----------------------------------------------------------------' -ForegroundColor Yellow
        Write-Host '2. Enable and configure(with default options) SNMP in the Remote Machine' -ForegroundColor Green
        Write-Host "`tCommand To Use      : .\SNMPEnabler.ps1 -h <Remote_MachineName> -username <username>" -ForegroundColor Magenta
        Write-Host '-----------------------------------------------------------------' -ForegroundColor Yellow
        Write-Host '3. Enable and configure(with custom input options) SNMP in the Local Machine' -ForegroundColor Green
        Write-Host "`tCommand To Use      : .\SNMPEnabler.ps1 -h localhost -communityName <communityName> -snmpType <snmpType> -permittedHost <permittedHost>" -ForegroundColor Magenta
        Write-Host '-----------------------------------------------------------------' -ForegroundColor Yellow
        Write-Host '4. Enable and configure(with custom input options) SNMP in the Remote Machine' -ForegroundColor Green
        Write-Host "`tCommand To Use      : .\SNMPEnabler.ps1 -h <Remote_MachineName> -username <username> -communityName <communityName> -snmpType <snmpType> -permittedHost <permittedHost>" -ForegroundColor Magenta
        Write-Host '-----------------------------------------------------------------' -ForegroundColor Yellow
        Write-Host '5. Configure the community and permitted host on an SNMP enabled Local Machine' -ForegroundColor Green
        Write-Host "`tCommand To Use      : .\SNMPEnabler.ps1 -h localhost -onlyConfigure true -communityName <communityName> -snmpType <snmpType> -permittedHost <permittedHost>" -ForegroundColor Magenta
        Write-Host '-----------------------------------------------------------------' -ForegroundColor Yellow
        Write-Host '6.Configure the community and permitted host on an SNMP enabled Remote Machine' -ForegroundColor Green
        Write-Host "`tCommand To Use      : .\SNMPEnabler.ps1 -h <Remote_MachineName> -username <username> -pass <password> -onlyConfigure true -communityName <communityName> -snmpType <snmpType> -permittedHost <permittedHost>`n" -ForegroundColor Magenta
        Write-Host '_________________________________________________________________' -ForegroundColor Yellow
        Write-Host '7. For Bulk Enabling' -ForegroundColor Green
        Write-Host "`t(NOTE : You must give Domain credentials to enable SNMP in multiple servers.)" -ForegroundColor Magenta
        Write-Host "`t_________________________________________________________________" -ForegroundColor Yellow
        Write-Host "`t7.1 Bulk enabling and configuring(with default options) SNMP in Local/Remote Machines" -ForegroundColor Green
        Write-Host "`t`tCommand To Use : .\SNMPEnabler.ps1 -f<filepath> -username <username>" -ForegroundColor Magenta
        Write-Host "`t-----------------------------------------------------------------" -ForegroundColor Yellow
        Write-Host "`t7.2 Bulk enabling and configuring(with custom options) SNMP in Local/Remote Machines" -ForegroundColor Green
        Write-Host "`t`tCommand To Use : .\SNMPEnabler.ps1 -f <filepath> -username <username>�-communityName <communityName> -snmpType <snmpType> -permittedHost <permittedHost>" -ForegroundColor Magenta
        Write-Host "`t-----------------------------------------------------------------" -ForegroundColor Yellow
        Write-Host "`t7.3 Bulk configuring with the community and permitted hosts on SNMP enabled Local/Remote Machines" -ForegroundColor Green
        Write-Host "`t`tCommand To Use : .\SNMPEnabler.ps1 -f <filepath> -username <username>�-onlyConfigure true -communityName <communityName> -snmpType <snmpType> -permittedHost <permittedHost>
" -ForegroundColor Magenta
        Write-Host "----------------------Syntax of the inputs params------------------`n" -ForegroundColor Red
    }

    #This function is used to exit the process
    function exitProcess()
    {
        if ($debug) { Write-Host "`nExiting Process" -ForegroundColor Cyan }
        Write-Host '*********************************************' -ForegroundColor Cyan
        Exit
    }


    #****************************************************************************************************
    [string]$Global:debugGlobal = $null
    Write-Host "**************************************************`n        SNMP Enabler`n**************************************************" -ForegroundColor Cyan

    # Validate Input Params
    if (($debug -ne $null) -and $debug -eq 'true')
    {
        $Global:debugGlobal = [int]1
    }
    else
    {
        $Global:debugGlobal = $null
    }
    if ($Global:debugGlobal) { Write-Host "Input params with Default values : host-$h, filepath-$f, username-$username, pass-$pass, communityName-$communityName, snmpType-$snmpType, permittedHost-$permittedHost, onlyConfigure-$onlyConfigure`n" -ForegroundColor Gray }
    if (($h -and $f) -or (!$h -and !$f))
    {
        Write-Host 'Either host or file path needs to passed as arguments' -ForegroundColor Red
        helpCommands
        exitProcess
    }

    if ($h -and !(Test-Connection -ComputerName $h -Count 1 -Quiet))
    {
        Write-Host "The host Machine -'$h' is not reachable. Please make sure '$h' is up and running and try again" -ForegroundColor Red
        exitProcess
    }

    if (($f -and !($h) -and (!$username)))
    {
        Write-Host 'For SNMP Bulk Enabling -username param is required.' -ForegroundColor Red
        helpCommands
        exitProcess
    }

    if ($f -and !(Test-Path $f))
    {
        Write-Host "`nThe input file '$f' does not exist. Please try again with a valid path" -ForegroundColor Red
        exitProcess
    }

    if (!$communityName)
    {
        $communityName = [string]'public'
    }

    if (!$snmpType)
    {
        $snmpType = [int]4
    }
    elseif (!($snmpType -eq 1 -or $snmpType -eq 2 -or $snmpType -eq 4 -or $snmpType -eq 8 -or $snmpType -eq 16))
    {
        Write-Host "The entered snmpType value is not acceptable`nPlease retry with the appropriate integer value : '1' -NONE / '2' -NOTIFY / '4' -READONLY / '8' -READWRITE / '16' -READCREATE `nOpManager's prefered snmpType value is 4. (IE.  -snmpType 4 )" -ForegroundColor Red
        exitProcess
    }

    if (!$permittedHost)
    {
        $permittedHost = $env:COMPUTERNAME
    }
    elseif (!(Test-Connection -ComputerName $permittedHost -Count 1 -Quiet))
    {
        Write-Host "The permittedHost -'$permittedHost' is not reachable. Please Make sure it is up and running and try again" -ForegroundColor Red
        exitProcess
    }

    if (!$onlyConfigure)
    {
        $onlyConfigure = [string]'false'
    }
    elseif (!($onlyConfigure -eq 'true' -or $onlyConfigure -eq 'false'))
    {
        Write-Host "The onlyConfigure -'$onlyConfigure' param should be true/false. (IE. '-onlyConfigure false')" -ForegroundColor Red
        exitProcess
    }
    if ($Global:debugGlobal) { Write-Host "Input params with default values : host-$h, filepath-$f, username-$username, pass-$pass, communityName-$communityName, snmpType-$snmpType, permittedHost-$permittedHost, onlyConfigure-$onlyConfigure, debug-$Global:debugGlobal" -ForegroundColor Gray }


    if ($Global:debugGlobal) { Write-Host "`nValidation done on input purams" -ForegroundColor Gray }

    if ($h)
    {
        Write-Host "`n        Enabling SNMP for host $h`n**************************************************" -ForegroundColor Cyan
        $islocal = [int]0

        $a = (Test-Connection ::1)[0] | Select-Object IPV4Address
        if ($h -eq 'localhost' -or $h -eq $env:COMPUTERNAME -or ($a.IPV4Address -eq $h) )
        {
            $islocal = [int]1
            if ($Global:debugGlobal) { Write-Host "$h is a Localhost Machine" -ForegroundColor Gray }
            EnableSNMPandConfigure -h $h -Credential $Credential -islocal $islocal -communityName $communityName -snmpType $snmpType -permittedHost $permittedHost
        }
        elseif ($username)
        {
            if ($Global:debugGlobal) { Write-Host "$h is a Remote Machine" -ForegroundColor Gray }
            if (!$pass)
            {
                $securedPass = Read-Host "Enter password for $username " -AsSecureString
            }
            else
            {
                $securedPass = ConvertTo-SecureString -String $pass -AsPlainText -Force
            }
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securedPass

            EnableSNMPandConfigure -h $h -Credential $Credential -islocal $islocal -communityName $communityName -snmpType $snmpType -permittedHost $permittedHost -onlyConfigure $onlyConfigure
        }
        else
        {
            Write-Host "`nFormat to enable SNMP in a remote machine : .\SNMPEnabler.ps1 -h<Remote_MachineName> -username <username>" -ForegroundColor Red
            helpCommands
        }
    }
    elseif ($f -and (!$h) -and ($onlyConfigure -eq 'false'))
    {
        Write-Host "`nBulk enabling SNMP for hosts from the input file $f`n**************************************************" -ForegroundColor Cyan

        $path = Get-Content -Path $f
        if (!$pass)
        {
            $securedPass = Read-Host "Enter the password for $username " -AsSecureString
        }
        else
        {
            $securedPass = ConvertTo-SecureString -String $pass -AsPlainText -Force
        }
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $securedPass
        foreach ($h in $path)
        {
            $a = (Test-Connection ::1)[0] | Select-Object IPV4Address
            $islocal = [int]0
            Write-Host "`n        Enabling SNMP for host-$h" -ForegroundColor Green
            Write-Host '**************************************************' -ForegroundColor Cyan
            if ($h -eq 'localhost' -or $h -eq $env:COMPUTERNAME -or ($a.IPV4Address -eq $h) )
            {
                $islocal = [int]1
                if ($Global:debugGlobal) { Write-Host "$h is Local Machine" -ForegroundColor Gray }
            }
            try
            {
                if ($Global:debugGlobal) { Write-Host "Processing with host $h" -ForegroundColor Gray }
                EnableSNMPandConfigure -h $h -Credential $Credential -islocal $islocal -communityName $communityName -snmpType $snmpType -permittedHost $permittedHost -onlyConfigure $onlyConfigure
                Write-Host '_________________________________________________' -ForegroundColor Cyan
            }
            catch [Exception]
            {
                Write-Host "SNMP enabling failed for $h - " $_.Exception.Message -ForegroundColor Cyan
            }
        }
    }
    else
    {
        helpcommands
    }
}
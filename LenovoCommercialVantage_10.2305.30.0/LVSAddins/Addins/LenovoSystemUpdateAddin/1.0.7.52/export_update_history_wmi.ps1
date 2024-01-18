﻿########################################################################### 
#    Version 1.0 - 07/16/2018
#    Version 1.1 - 07/20/2018
#
#    ti_update_status.ps1: 
#
#    This script is designed to parse the most recent ThinInstaller log 
#    file and populate the Lenovo_Updates WMI class with status of updates
#    processed by ThinInstaller.  This class can then be inventoried by 
#    SCCM. 
#
#    Copyright Lenovo. All Rights Reserved.
########################################################################### 

###########################################################################
#    Functions
###########################################################################

#####################################
# Function to create class.
#####################################
function createclass {
    #make sure the Lenovo namespace exists
    $ns = [wmiclass]'root:__namespace'
    $sc = $ns.CreateInstance()
    $sc.Name = 'Lenovo'
    $sc.Put()

    #create Lenovo_Updates class insance in the Lenovo namespace 
    $myclass = New-Object System.Management.ManagementClass ("root\Lenovo", [string]::Empty, $null)
    $myclass["__CLASS"] = "Lenovo_Updates"
    $myclass.Qualifiers.Add("SMS_Report", $true)
    $myclass.Qualifiers.Add("SMS_Group_Name", "Lenovo_Updates")
    $myclass.Qualifiers.Add("SMS_Class_Id", "Lenovo_Updates")

    $myclass.Properties.Add("PackageID", [System.Management.CimType]::String, $false)
    $myclass.Properties.Add("Title", [System.Management.CimType]::String, $false)
    $myclass.Properties.Add("Status", [System.Management.CimType]::String, $false)
    $myclass.Properties.Add("AdditionalInfo", [System.Management.CimType]::String, $false)
	$myclass.Properties.Add("Version", [System.Management.CimType]::String, $false)
    $myclass.Properties.Add("Severity", [System.Management.CimType]::String, $false)
    $myclass.Properties.Add("InstallDate", [System.Management.CimType]::String, $false)
    
    $myclass.Properties["PackageID"].Qualifiers.Add("Key", $true)
    $myclass.Properties["PackageID"].Qualifiers.Add("SMS_Report", $true)
    $myclass.Properties["Title"].Qualifiers.Add("SMS_Report", $true)
    $myclass.Properties["Status"].Qualifiers.Add("SMS_Report", $true)
    $myclass.Properties["AdditionalInfo"].Qualifiers.Add("SMS_Report", $true)
	$myclass.Properties["Version"].Qualifiers.Add("SMS_Report", $true)
	$myclass.Properties["Severity"].Qualifiers.Add("SMS_Report", $true)
    $myclass.Properties["InstallDate"].Qualifiers.Add("SMS_Report", $true)


    $myclass.Put()
}

#####################################
# Function to add all update statuses 
# from log file to the WMI class
#####################################
function addstatus {
    # get current log file and parse

    # following path will need to be modified before implementing in production
    $updateHistory = "update_history.txt"

    Get-Content $updateHistory | ForEach-Object {
        $oneRecord = $_ -split " %-% "
        $packageid = $oneRecord[0]
        $title = $oneRecord[1]
        $status = $oneRecord[2]
        $additionalInfo = $oneRecord[3]
        $version = $oneRecord[4]
        $Severity = $oneRecord[5]
        $InstallDate = formatDate($oneRecord[6])
        try {
            $update = Get-WmiObject -Namespace root\Lenovo -Class Lenovo_Updates -Filter "PackageID = '$packageid'"
            if ($update.PackageID -eq $packageid) {
                if ($update.Status -ne $status -or $update.Title -ne $title -or $update.AdditionalInfo -ne $additionalInfo -or $update.Version -ne $version -or $update.Severity -ne $Severity -or $update.InstallDate -ne $InstallDate) {
                    $update.Status = $status
                    $update.Title = $title
                    $update.AdditionalInfo = $additionalInfo
                    $update.Version = $version
                    $update.Severity = $Severity
                    $update.InstallDate = $InstallDate
                    $update.Put()
                }
            }
            else {
                Set-WmiInstance -Namespace root\Lenovo -Class Lenovo_updates -Arguments @{PackageID = $packageid; Title = $title; Status = $status; AdditionalInfo = $additionalInfo; Version = $version; Severity = $Severity; InstallDate = $InstallDate} -PutType CreateOnly
            }
        }
        catch {
            "Did not add"
            $packageid + " " + $title + " " + $status
        }
    }

}

function formatDate ($date) {
    if($date -imatch ""){
        try{
            $dateLong = [long]$date
            if($dateLong -gt 0){
                $dateString = Get-Date -Date $dateLong -Format (Get-Culture).DateTimeFormat.ShortDatePattern
                $timeString = Get-Date -Date $dateLong -Format (Get-Culture).DateTimeFormat.ShortTimePattern
                return $dateString + ' ' + $timeString
            }
        }catch{}
    }
    return ""
}

function addOldData ($oldData) {
    if($oldData) {
        foreach($item in $oldData) {
            $packageid = $item.PackageID
            $title = $item.Title
            $status = $item.Status
            $additionalInfo = $item.AdditionalInfo
            $version = $item.Version
            $Severity = $item.Severity
            try {
                Set-WmiInstance -Namespace root\Lenovo -Class Lenovo_updates -Arguments @{PackageID = $packageid; Title = $title; Status = $status; AdditionalInfo = $additionalInfo; Version = $version; Severity = $Severity; InstallDate = ''} -PutType CreateOnly
            }
            catch {
                "Did not add"
                $packageid + " " + $title + " " + $status
            }
        }      
    }
}

function HasInstallDateProperty {
    $obj = Get-WmiObject -Namespace root\Lenovo -Class Lenovo_Updates -List
    if($obj -eq $null)
    {
        return $true
    }
	else
	{
		foreach($property in $obj.Properties) 
		{ 
			if ( $property.Name -eq 'InstallDate') 
			{ 
				return $true 
			} 
		} 
	}
    return $false
}


###########################################################################
#    Main
###########################################################################

# Create custom class if needed
[void](Get-WMIObject -Namespace root\Lenovo Lenovo_Updates -ErrorAction SilentlyContinue -ErrorVariable wmiclasserror)
if ($wmiclasserror) {
    try { 
        createclass 
    }
    catch {
        "Could not create WMI class"
        Exit 1
    }
}

$isSeverityExists = $false
$isSeverityExists = HasInstallDateProperty

if($isSeverityExists -ne $true) {
    $OldData = Get-WmiObject -Namespace root\Lenovo -Class Lenovo_Updates -ErrorAction SilentlyContinue | Select-Object -Property PackageID,Title,Status,AdditionalInfo,Version,Severity
    Remove-WmiObject -Namespace root\Lenovo -Class Lenovo_Updates -ErrorAction SilentlyContinue
    try { 
        createclass 
    }
    catch {
        "Could not create WMI class"
        Exit 1
    }
    addOldData $oldData
}

addstatus

# Optional to execute a H/W inventory cycle - requires CM Client installed
#$SMSCli = [wmiclass] "\\.\root\ccm:SMS_Client"
#$SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}")

# SIG # Begin signature block
# MIIttwYJKoZIhvcNAQcCoIItqDCCLaQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAChqTKfa4doIM7
# MUPwQd8DvV5gPtljPV+yIgcRxXl4FqCCJrowggWNMIIEdaADAgECAhAOmxiO+dAt
# 5+/bUOIIQBhaMA0GCSqGSIb3DQEBDAUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0yMjA4MDEwMDAwMDBa
# Fw0zMTExMDkyMzU5NTlaMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lD
# ZXJ0IFRydXN0ZWQgUm9vdCBHNDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAL/mkHNo3rvkXUo8MCIwaTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3E
# MB/zG6Q4FutWxpdtHauyefLKEdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKy
# unWZanMylNEQRBAu34LzB4TmdDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsF
# xl7sWxq868nPzaw0QF+xembud8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU1
# 5zHL2pNe3I6PgNq2kZhAkHnDeMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJB
# MtfbBHMqbpEBfCFM1LyuGwN1XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObUR
# WBf3JFxGj2T3wWmIdph2PVldQnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6
# nj3cAORFJYm2mkQZK37AlLTSYW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxB
# YKqxYxhElRp2Yn72gLD76GSmM9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5S
# UUd0viastkF13nqsX40/ybzTQRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+x
# q4aLT8LWRV+dIPyhHsXAj6KxfgommfXkaS+YHS312amyHeUbAgMBAAGjggE6MIIB
# NjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwP
# TzAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzAOBgNVHQ8BAf8EBAMC
# AYYweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwRQYDVR0fBD4wPDA6oDigNoY0
# aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDARBgNVHSAECjAIMAYGBFUdIAAwDQYJKoZIhvcNAQEMBQADggEBAHCgv0Nc
# Vec4X6CjdBs9thbX979XB72arKGHLOyFXqkauyL4hxppVCLtpIh3bb0aFPQTSnov
# Lbc47/T/gLn4offyct4kvFIDyE7QKt76LVbP+fT3rDB6mouyXtTP0UNEm0Mh65Zy
# oUi0mcudT6cGAxN3J0TU53/oWajwvy8LpunyNDzs9wPHh6jSTEAZNUZqaVSwuKFW
# juyk1T3osdz9HNj0d1pcVIxv76FQPfx2CWiEn2/K2yCNNWAcAgPLILCsWKAOQGPF
# mCLBsln1VWvPJ6tsds5vIy30fnFqI2si/xK4VC0nftg62fC2h5b9W9FcrBjDTZ9z
# twGpn1eqXijiuZQwggWQMIIDeKADAgECAhAFmxtXno4hMuI5B72nd3VcMA0GCSqG
# SIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMx
# GTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRy
# dXN0ZWQgUm9vdCBHNDAeFw0xMzA4MDExMjAwMDBaFw0zODAxMTUxMjAwMDBaMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAL/mkHNo3rvkXUo8MCIw
# aTPswqclLskhPfKK2FnC4SmnPVirdprNrnsbhA3EMB/zG6Q4FutWxpdtHauyefLK
# EdLkX9YFPFIPUh/GnhWlfr6fqVcWWVVyr2iTcMKyunWZanMylNEQRBAu34LzB4Tm
# dDttceItDBvuINXJIB1jKS3O7F5OyJP4IWGbNOsFxl7sWxq868nPzaw0QF+xembu
# d8hIqGZXV59UWI4MK7dPpzDZVu7Ke13jrclPXuU15zHL2pNe3I6PgNq2kZhAkHnD
# eMe2scS1ahg4AxCN2NQ3pC4FfYj1gj4QkXCrVYJBMtfbBHMqbpEBfCFM1LyuGwN1
# XXhm2ToxRJozQL8I11pJpMLmqaBn3aQnvKFPObURWBf3JFxGj2T3wWmIdph2PVld
# QnaHiZdpekjw4KISG2aadMreSx7nDmOu5tTvkpI6nj3cAORFJYm2mkQZK37AlLTS
# YW3rM9nF30sEAMx9HJXDj/chsrIRt7t/8tWMcCxBYKqxYxhElRp2Yn72gLD76GSm
# M9GJB+G9t+ZDpBi4pncB4Q+UDCEdslQpJYls5Q5SUUd0viastkF13nqsX40/ybzT
# QRESW+UQUOsxxcpyFiIJ33xMdT9j7CFfxCBRa2+xq4aLT8LWRV+dIPyhHsXAj6Kx
# fgommfXkaS+YHS312amyHeUbAgMBAAGjQjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYD
# VR0PAQH/BAQDAgGGMB0GA1UdDgQWBBTs1+OC0nFdZEzfLmc/57qYrhwPTzANBgkq
# hkiG9w0BAQwFAAOCAgEAu2HZfalsvhfEkRvDoaIAjeNkaA9Wz3eucPn9mkqZucl4
# XAwMX+TmFClWCzZJXURj4K2clhhmGyMNPXnpbWvWVPjSPMFDQK4dUPVS/JA7u5iZ
# aWvHwaeoaKQn3J35J64whbn2Z006Po9ZOSJTROvIXQPK7VB6fWIhCoDIc2bRoAVg
# X+iltKevqPdtNZx8WorWojiZ83iL9E3SIAveBO6Mm0eBcg3AFDLvMFkuruBx8lbk
# apdvklBtlo1oepqyNhR6BvIkuQkRUNcIsbiJeoQjYUIp5aPNoiBB19GcZNnqJqGL
# FNdMGbJQQXE9P01wI4YMStyB0swylIQNCAmXHE/A7msgdDDS4Dk0EIUhFQEI6FUy
# 3nFJ2SgXUE3mvk3RdazQyvtBuEOlqtPDBURPLDab4vriRbgjU2wGb2dVf0a1TD9u
# KFp5JtKkqGKX0h7i7UqLvBv9R0oN32dmfrJbQdA75PQ79ARj6e/CVABRoIoqyc54
# zNXqhwQYs86vSYiv85KZtrPmYQ/ShQDnUBrkG5WdGaG5nLGbsQAe79APT0JsyQq8
# 7kP6OnGlyE0mpTX9iV28hWIdMtKgK1TtmlfB2/oQzxm3i0objwG2J5VT6LaJbVu8
# aNQj6ItRolb58KaAoNYes7wPD1N1KarqE3fk3oyBIa0HEEcRrYc9B9F1vM/zZn4w
# ggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbS
# g9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9
# /UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXn
# HwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0
# VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4f
# sbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40Nj
# gHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0
# QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvv
# mz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T
# /jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk
# 42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5r
# mQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcG
# CCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNV
# HSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIB
# AH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxp
# wc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIl
# zpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQ
# cAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfe
# Kuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+j
# Sbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJsh
# IUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6
# OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDw
# N7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR
# 81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2
# VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIGsDCCBJigAwIBAgIQ
# CK1AsmDSnEyfXs2pvZOu2TANBgkqhkiG9w0BAQwFADBiMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjEwNDI5MDAw
# MDAwWhcNMzYwNDI4MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGln
# aUNlcnQsIEluYy4xQTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgQ29kZSBT
# aWduaW5nIFJTQTQwOTYgU0hBMzg0IDIwMjEgQ0ExMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEA1bQvQtAorXi3XdU5WRuxiEL1M4zrPYGXcMW7xIUmMJ+k
# jmjYXPXrNCQH4UtP03hD9BfXHtr50tVnGlJPDqFX/IiZwZHMgQM+TXAkZLON4gh9
# NH1MgFcSa0OamfLFOx/y78tHWhOmTLMBICXzENOLsvsI8IrgnQnAZaf6mIBJNYc9
# URnokCF4RS6hnyzhGMIazMXuk0lwQjKP+8bqHPNlaJGiTUyCEUhSaN4QvRRXXegY
# E2XFf7JPhSxIpFaENdb5LpyqABXRN/4aBpTCfMjqGzLmysL0p6MDDnSlrzm2q2AS
# 4+jWufcx4dyt5Big2MEjR0ezoQ9uo6ttmAaDG7dqZy3SvUQakhCBj7A7CdfHmzJa
# wv9qYFSLScGT7eG0XOBv6yb5jNWy+TgQ5urOkfW+0/tvk2E0XLyTRSiDNipmKF+w
# c86LJiUGsoPUXPYVGUztYuBeM/Lo6OwKp7ADK5GyNnm+960IHnWmZcy740hQ83eR
# Gv7bUKJGyGFYmPV8AhY8gyitOYbs1LcNU9D4R+Z1MI3sMJN2FKZbS110YU0/EpF2
# 3r9Yy3IQKUHw1cVtJnZoEUETWJrcJisB9IlNWdt4z4FKPkBHX8mBUHOFECMhWWCK
# ZFTBzCEa6DgZfGYczXg4RTCZT/9jT0y7qg0IU0F8WD1Hs/q27IwyCQLMbDwMVhEC
# AwEAAaOCAVkwggFVMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFGg34Ou2
# O/hfEYb7/mF7CIhl9E5CMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9P
# MA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDAzB3BggrBgEFBQcB
# AQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggr
# BgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwHAYDVR0gBBUwEzAH
# BgVngQwBAzAIBgZngQwBBAEwDQYJKoZIhvcNAQEMBQADggIBADojRD2NCHbuj7w6
# mdNW4AIapfhINPMstuZ0ZveUcrEAyq9sMCcTEp6QRJ9L/Z6jfCbVN7w6XUhtldU/
# SfQnuxaBRVD9nL22heB2fjdxyyL3WqqQz/WTauPrINHVUHmImoqKwba9oUgYftzY
# gBoRGRjNYZmBVvbJ43bnxOQbX0P4PpT/djk9ntSZz0rdKOtfJqGVWEjVGv7XJz/9
# kNF2ht0csGBc8w2o7uCJob054ThO2m67Np375SFTWsPK6Wrxoj7bQ7gzyE84FJKZ
# 9d3OVG3ZXQIUH0AzfAPilbLCIXVzUstG2MQ0HKKlS43Nb3Y3LIU/Gs4m6Ri+kAew
# Q3+ViCCCcPDMyu/9KTVcH4k4Vfc3iosJocsL6TEa/y4ZXDlx4b6cpwoG1iZnt5Lm
# Tl/eeqxJzy6kdJKt2zyknIYf48FWGysj/4+16oh7cGvmoLr9Oj9FpsToFpFSi0HA
# SIRLlk2rREDjjfAVKM7t8RhWByovEMQMCGQ8M4+uKIw8y4+ICw2/O/TOHnuO77Xr
# y7fwdxPm5yg/rBKupS8ibEH5glwVZsxsDsrFhsP2JjMMB0ug0wcCampAMEhLNKhR
# ILutG4UI4lkNbcoFUCvqShyepf2gpx8GdOfy1lKQ/a+FSCH5Vzu0nAPthkX0tGFu
# v2jiJmCG6sivqf6UHedjGzqGVnhOMIIGwDCCBKigAwIBAgIQDE1pckuU+jwqSj0p
# B4A9WjANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGln
# aUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5
# NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTIyMDkyMTAwMDAwMFoXDTMzMTEy
# MTIzNTk1OVowRjELMAkGA1UEBhMCVVMxETAPBgNVBAoTCERpZ2lDZXJ0MSQwIgYD
# VQQDExtEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMiAtIDIwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDP7KUmOsap8mu7jcENmtuh6BSFdDMaJqzQHFUeHjZt
# vJJVDGH0nQl3PRWWCC9rZKT9BoMW15GSOBwxApb7crGXOlWvM+xhiummKNuQY1y9
# iVPgOi2Mh0KuJqTku3h4uXoW4VbGwLpkU7sqFudQSLuIaQyIxvG+4C99O7HKU41A
# gx7ny3JJKB5MgB6FVueF7fJhvKo6B332q27lZt3iXPUv7Y3UTZWEaOOAy2p50dIQ
# kUYp6z4m8rSMzUy5Zsi7qlA4DeWMlF0ZWr/1e0BubxaompyVR4aFeT4MXmaMGgok
# vpyq0py2909ueMQoP6McD1AGN7oI2TWmtR7aeFgdOej4TJEQln5N4d3CraV++C0b
# H+wrRhijGfY59/XBT3EuiQMRoku7mL/6T+R7Nu8GRORV/zbq5Xwx5/PCUsTmFnta
# fqUlc9vAapkhLWPlWfVNL5AfJ7fSqxTlOGaHUQhr+1NDOdBk+lbP4PQK5hRtZHi7
# mP2Uw3Mh8y/CLiDXgazT8QfU4b3ZXUtuMZQpi+ZBpGWUwFjl5S4pkKa3YWT62SBs
# GFFguqaBDwklU/G/O+mrBw5qBzliGcnWhX8T2Y15z2LF7OF7ucxnEweawXjtxojI
# sG4yeccLWYONxu71LHx7jstkifGxxLjnU15fVdJ9GSlZA076XepFcxyEftfO4tQ6
# dwIDAQABo4IBizCCAYcwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwFgYD
# VR0lAQH/BAwwCgYIKwYBBQUHAwgwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJYIZI
# AYb9bAcBMB8GA1UdIwQYMBaAFLoW2W1NhS9zKXaaL3WMaiCPnshvMB0GA1UdDgQW
# BBRiit7QYfyPMRTtlwvNPSqUFN9SnDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hBMjU2
# VGltZVN0YW1waW5nQ0EuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDAkBggrBgEFBQcw
# AYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFgGCCsGAQUFBzAChkxodHRwOi8v
# Y2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRSU0E0MDk2U0hB
# MjU2VGltZVN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQBVqioa80bz
# eFc3MPx140/WhSPx/PmVOZsl5vdyipjDd9Rk/BX7NsJJUSx4iGNVCUY5APxp1Mqb
# KfujP8DJAJsTHbCYidx48s18hc1Tna9i4mFmoxQqRYdKmEIrUPwbtZ4IMAn65C3X
# CYl5+QnmiM59G7hqopvBU2AJ6KO4ndetHxy47JhB8PYOgPvk/9+dEKfrALpfSo8a
# OlK06r8JSRU1NlmaD1TSsht/fl4JrXZUinRtytIFZyt26/+YsiaVOBmIRBTlClmi
# a+ciPkQh0j8cwJvtfEiy2JIMkU88ZpSvXQJT657inuTTH4YBZJwAwuladHUNPeF5
# iL8cAZfJGSOA1zZaX5YWsWMMxkZAO85dNdRZPkOaGK7DycvD+5sTX2q1x+DzBcNZ
# 3ydiK95ByVO5/zQQZ/YmMph7/lxClIGUgp2sCovGSxVK05iQRWAzgOAj3vgDpPZF
# R+XOuANCR+hBNnF3rf2i6Jd0Ti7aHh2MWsgemtXC8MYiqE+bvdgcmlHEL5r2X6cn
# l7qWLoVXwGDneFZ/au/ClZpLEQLIgpzJGgV8unG1TnqZbPTontRamMifv427GFxD
# 9dAq6OJi7ngE273R+1sKqHB+8JeEeOMIA11HLGOoJTiXAdI/Otrl5fbmm9x+LMz/
# F0xNAKLY1gEOuIvu5uByVYksJxlh9ncBjDCCB2cwggVPoAMCAQICEAsQSWworhxS
# ZKuTk32n9IYwDQYJKoZIhvcNAQELBQAwaTELMAkGA1UEBhMCVVMxFzAVBgNVBAoT
# DkRpZ2lDZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENv
# ZGUgU2lnbmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMTAeFw0yMjA2MjkwMDAw
# MDBaFw0yMzA5MTQyMzU5NTlaMGwxCzAJBgNVBAYTAlVTMRcwFQYDVQQIEw5Ob3J0
# aCBDYXJvbGluYTEUMBIGA1UEBxMLTW9ycmlzdmlsbGUxDzANBgNVBAoTBkxlbm92
# bzEMMAoGA1UECxMDRzA4MQ8wDQYDVQQDEwZMZW5vdm8wggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDCH59WT/EIDs7Fq+EEBfJOHMZtfaen56vYcuCqjg+S
# EDNPivB6fwpwVWAh0Pb9I6uffIES1sgf4nHkCQn7So/lG5v1tlTkAaj51OiAIMnL
# vr2rG78d+rGglGhVXBmPjk0ZdkQ0ExPU+qdnWRZl9Y5RfP5IwhIcXV076wY/6RYq
# UcW1dcjHAQ+s7AisoYzu6/8c6TqeswPMr7+LOd91RsL9m/bAzSGxASG6bFIWam+T
# lXKO9sxm194hTo8xoUUzbZAzIov8oxLyjV2c2Msz1omu6dKmlIxDFwcD0jIAtvHq
# jAbtVnoOoIOJuBsaSRbFofdHPooVoY+kE58uhlcrKL2uEHA+o6GymSwa4uK5wL9+
# W0dvYZpNGe6JZR4NqgBmrHvZyWIpwxv628vDX2MKWj/Q/GFCBDQe/KqJ0GKGYCsd
# 1y0i8lOvF76iVp8PDB/SjlcM4VMtirLKSc9Wpc6Rh5/OlWq74PCdCqpS15ih2ES7
# 5MMGOFdesdbxD/FaVeQgjfgXncsjhOcKcKpqVh27KcV9YR6keGy6We+rEYJivSUo
# X+jIQdJmUh+yRlRsv/PCKp7QnVZ73lw41JX4+L6pwu5CuQi/+vQnr1UOhpqVFm8t
# TUqt43W5eiF67849uoJXniV3SqWFC+XPdDR8COa5FiMloepXv4RjKKOBIqPrOLOs
# pQIDAQABo4ICBjCCAgIwHwYDVR0jBBgwFoAUaDfg67Y7+F8Rhvv+YXsIiGX0TkIw
# HQYDVR0OBBYEFD7qKXTVOY14lQ6o5/yOG+bn+5BzMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzCBtQYDVR0fBIGtMIGqMFOgUaBPhk1odHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRDb2RlU2lnbmluZ1JT
# QTQwOTZTSEEzODQyMDIxQ0ExLmNybDBToFGgT4ZNaHR0cDovL2NybDQuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0
# MjAyMUNBMS5jcmwwPgYDVR0gBDcwNTAzBgZngQwBBAEwKTAnBggrBgEFBQcCARYb
# aHR0cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMIGUBggrBgEFBQcBAQSBhzCBhDAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFwGCCsGAQUFBzAC
# hlBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkRzRD
# b2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNydDAMBgNVHRMBAf8EAjAA
# MA0GCSqGSIb3DQEBCwUAA4ICAQBwP3WSks361Ok4H7kWdpp4vvn0ESeS6XEv+v4n
# YCHLEoDiEBdaK5PUV+5jCnsYdKZVXQca/mYGGuDOZHAaAeSzavGJouFb8tANTbwW
# hgc6CQxeV/mkZDiSG6p32Dd+QXVMZeCZT9SpGracRST/DacGwkph6w9LF13L3Xqj
# LLNYlv71P2ontg8UDsi8WdsS9whD+7t0mvQ8r3MJlRNUbUBtryjczg72HM7oK2aq
# yoXHc1Y8gF4/s7f59OBRg2+fF4e3j4XmtZAoVYTK6zmYNtKC0yooV1x9K52ohz/K
# Hp5I3xx02Ojd6V4RsE1VvLPS6c7tZUZtyNoQLFe/inSE7japxtuN0gGUvkQL8qDW
# uNHqM92j/yuPE6M/CS/20oF5VPm3r2a2mP/cAkhUULIjPjXJZ1HNVcJUwMKAnFF7
# yk0k6ml8EBNWBipNxDQMl4TtbTSycEYUc3U298C+OrlvjSWhQaIOmForn7cMuRyn
# 7zZKfjggXfZKlX7CergjVjW/CB00OVY7QiO6mGbyQcYjjVDGvI7UM7AHwACoijWo
# LlMGdVYbQ1bPcOOW8yLrGdrHFaZckHIeYqnGc6wyucTXHvmSC5gpCcNGGvW3GunG
# G6XSWqNqHksEjMVgHBKCGlc4qAE3rWlz4IgDhs7G7+PbieLUfaj3DuesNdCAUtC4
# drmsIjGCBlMwggZPAgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2ln
# bmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQCxBJbCiuHFJkq5OTfaf0hjAN
# BglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqG
# SIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3
# AgEVMC8GCSqGSIb3DQEJBDEiBCBYVMHplmpwaAsdniMk6u94VAPgIhhrnOzjqYJg
# /pWAuTANBgkqhkiG9w0BAQEFAASCAgC90PksKBlzGY6iZLFTGNqo6zx3whwxLnER
# q/u4Wkrcze3fsL+rxQwt5EbKa1NiiMXxW9BwGyqm4y233bndJ4BnVA8oj1Sk06dk
# 5dFknqZQSZ/rktO63/A/kh1+bf+XK4OhWkwJg/5J6yTap8NaEJXIcJar0kAHWyA/
# rgYtG1yRF7CiZtb4Ja3Q9vcGrIpqAvKKjG/Pg5saR7k50TUtizy4qqDllPIncAiD
# BiEwRB+l6IHWo6/p/8gOW0Y9oj0iBCmxe54WJZp5iVF1Of73jAGSfxuQsSmYRUP1
# WGcWIGvrQL4T63tzIw3XB8IUtpmzQcrM9lqnUHHO30qADIYdtnGLAYDOuoZbTjv6
# NAZ5U5fh9kK4jLjpjkXmnYL/WVPz6v91rwSZiARyLN5NztC8CM7tAlR/9oZTPAuh
# 1zDi2L0Hl5Nn6Lw8ILELfw/LhEEsLRQSCVdja6TzD6kBnrYr6NC1FdlA5Z3k49Cd
# mcVpYBmWBIELZeX/nOY9Zz6yCoF7/gD2wssf3H5OOJNT6aziye8Ca3p2Cl60TxPt
# pWM2lIPXorTB89sFQl/DdqT4KHeMTedawfEHxMqwFbrmOeoLfnaDKTlh8RBKp5JN
# Gy40SZpGu/oAhhMJv4eJXYQOP50DbgvTMfnEXSsqKgn/Zjz0qNqyPGWWvn26Cvx7
# muT/09e8sqGCAyAwggMcBgkqhkiG9w0BCQYxggMNMIIDCQIBATB3MGMxCzAJBgNV
# BAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNl
# cnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0ECEAxN
# aXJLlPo8Kko9KQeAPVowDQYJYIZIAWUDBAIBBQCgaTAYBgkqhkiG9w0BCQMxCwYJ
# KoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMzA2MDIwOTQ2MDlaMC8GCSqGSIb3
# DQEJBDEiBCBegHQYdOZqp4f3DND6kyjpPOHVkx9Cw5E395gcqFrABDANBgkqhkiG
# 9w0BAQEFAASCAgCL1l2vt9TgKBiSgfJ1nGY1KfZJi5BnCWPFxTBt5HRa6IYkKzF+
# 3miG99nUAcsYGNRrgFNetf7Ixieez0pnxMPmBpC7dow6+qrs3B/Z3Lt+Q09C7/7u
# bTsfExAsEFIWzBlG60bAtP6uJKZxrIaQ0aG7mPvOHaek74TPEKtlQpTBYtpN5R6m
# GjvV+rrLkJK9ynz6P07TkxUZbpCIvFzQwvhJaQS4HPYti1uGsLo72dMaHPzRjBrM
# +ERNUZyWJrspSz58wLAJODaNk5JwBIxZmF+e+gKxnxmGOTQ/jZEV/u0z/I4Xku97
# IRKLMKwyGIwvZbraOrgDqYoVHVcDNRF01pptW9zZpJ+tFgA+3yaHaVQik57UrQ9s
# pHyeylSoYf0WhXaDagAlVfhe2+u6CdP8AApFh6LHY4S8/Lvdmwix/45DOvLWDTnY
# IJq5YIZfbZWyDEQyduMis45uPgDrpcKyIzl80LgfsdmrTFQB5cphh3PxfiLzVaLA
# 87ST9wtaOg/hMaFUGtr/bDW2cX0x0Jre2fQZka8PI/oG4uIMWE1DzOkkUHOTOuBq
# yqTC0P9zrse2WHpIiis1DqTlP3de0J3n0oqFllDLbxTqN6k51+hOmR8MXpLAgIuF
# gMsHqpA2epBqHT+KtR3HZgGhk2rkL/6YEo1YqFGXJaP736mMVR+Sbou1Cw==
# SIG # End signature block

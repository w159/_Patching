$EgnyteMapDrives = @"
## Group design layout outlined in Word document below
## https://s5logiccom.sharepoint.com/:w:/s/Customers/EVVLDzbECXVLt4pcMvRU8twB8xKGNIgZ48jbswTth7Mung?e=iFddQc

# Get Current User, SSO AzureAD
Import-Module AzureAD
`$UserPrincipalName = whoami -upn
Connect-AzureAD -AccountId `$userPrincipalName

# Get AzureAD User Information
`$GroupMemberships = Get-AzureADUserMembership -ObjectId `$UserPrincipalName | Select-Object DisplayName

`$EgnyteEXE = "C:\Program Files (x86)\Egnyte Connect\EgnyteClient.exe"

        foreach (`$GroupMembership in `$GroupMemberships) {

                `$Arguments_AccountingDrive = '-command add -l "Accounting" -d Griffco -t Q -sso use_sso -m "/Shared/Accounting" -c connect_immediately'
                `$Arguments_CommercialConstructionDrive = '-command add -l "Commercial Construction" -d Griffco -t O -sso use_sso -m "/Shared/Commercial Construction" -c connect_immediately'
                `$Arguments_DesignDrive = '-command add -l "Design" -d Griffco -t R -sso use_sso -m "/Shared/Design" -c connect_immediately'
                `$Arguments_ExecutiveDrive = '-command add -l "Executive" -d Griffco -t X -sso use_sso -m "/Shared/Executive" -c connect_immediately'
                `$Arguments_FoodandIndustrialDrive = '-command add -l "Food and Industrial" -d Griffco -t F -sso use_sso -m "/Shared/Food and Industrial" -c connect_immediately'
                `$Arguments_ManagementDrive = '-command add -l "Management" -d Griffco -t M -sso use_sso -m "/Shared/Management" -c connect_immediately'
                `$Arguments_ProjectsDrive = '-command add -l "Projects" -d Griffco -t P -sso use_sso -m "/Shared/Projects" -c connect_immediately'
                `$Arguments_SalesDrive = '-command add -l "Sales" -d Griffco -t S -sso use_sso -m "/Shared/Sales" -c connect_immediately'
                `$Arguments_SuperintendentsDrive = '-command add -l "Superintendents" -d Griffco -t U -sso use_sso -m "/Shared/Superintendents" -c connect_immediately'
                `$Arguments_TechDrive = '-command add -l "Tech" -d Griffco -t T -sso use_sso -m "/Shared/Tech" -c connect_immediately'
                `$Arguments_MarketingDrive = '-command add -l "Marketing" -d Griffco -t Y -sso use_sso -m "/Shared/Marketing" -c connect_immediately'

                Start-Process `$EgnyteEXE -ArgumentList '--auto-silent'
                Start-Process `$EgnyteEXE -ArgumentList '-command add -l "Personal Drive" -d Griffco -t Z -sso use_sso -m "/Private/::egnyte_username::" -c connect_immediately'
                Start-Process `$EgnyteEXE -ArgumentList '-command add -l "General" -d Griffco -t G -sso use_sso -m "/Shared/General" -c connect_immediately'
                Start-Process `$EgnyteEXE -ArgumentList '-command add -l "Egnyte Templates" -d Griffco -t N -sso use_sso -m "/Shared/Egnyte Templates" -c connect_immediately'

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Commercial-Construction-Management") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ManagementDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_CommercialConstructionDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_TechDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SuperintendentsDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Commercial-Construction-Project-Managers") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_CommercialConstructionDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SuperintendentsDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Commercial-Construction-Superintendents") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_CommercialConstructionDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SuperintendentsDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Commercial-Construction") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_CommercialConstructionDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SuperintendentsDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Food-and-Industrial-Management") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_FoodandIndustrialDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ManagementDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_TechDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SuperintendentsDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Food-and-Industrial-Project-Managers") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_FoodandIndustrialDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SuperintendentsDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Food-and-Industrial-Superintendents") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_FoodandIndustrialDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SuperintendentsDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Food-and-Industrial") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_FoodandIndustrialDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Marketing-Management") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ManagementDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_TechDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_MarketingDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Marketing") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_MarketingDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Business-Development-Management") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ManagementDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_TechDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SuperintendentsDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Business-Development") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Accounting-Management") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ManagementDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_AccountingDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_TechDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Accounting") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_AccountingDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Design-Management") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ManagementDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_DesignDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_TechDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Design") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_DesignDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive

                        }

                        If (`$GroupMembership.DisplayName -eq "Egnyte-Share-Executives") {

                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ManagementDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ProjectsDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_SalesDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_TechDrive
                                Start-Process `$EgnyteEXE -ArgumentList `$Arguments_ExecutiveDrive

                        }
        }
"@

New-Item -Path "C:\Windows\Utils" -Name EgnyteMapDrives.ps1 -ItemType File -Value $EgnyteMapDrives -Force

$Trigger = (New-ScheduledTaskTrigger -AtLogOn)

$Action =  (New-ScheduledTaskAction -Execute "POWERSHELL" -Argument '-ExecutionPolicy Bypass -Command "& {[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12}"'),
           (New-ScheduledTaskAction -Execute "POWERSHELL" -Argument '-ExecutionPolicy Bypass -File "C:\Windows\Utils\EgnyteMapDrives.ps1"')

$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartOnIdle

Register-ScheduledTask -TaskName "Egnyte Map Drives" `
  -Trigger $Trigger `
  -Action $Action `
  -Settings $Settings `
  –Force `
  -Description "This maps Egnyte drives based on the user's current Azure AD group memberships. `n-Created by JM with S5 Logic; Last updated 1/3/23"
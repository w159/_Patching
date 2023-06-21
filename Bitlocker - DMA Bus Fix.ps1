$tmpfile = "$($env:TEMP)\AllowBuses.reg"
'Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DmaSecurity\AllowedBuses]'`
| Out-File $tmpfile
(Get-PnPDevice -InstanceId PCI* `
| Format-Table -Property FriendlyName,InstanceId -HideTableHeaders -AutoSize `
| Out-String -Width 300).trim() `
-split "`r`n" `
-replace '&SUBSYS.*', '' `
-replace '\s+PCI\\', '"="PCI\\' `
| Foreach-Object{ "{0}{1}{2}" -f '"',$_,'"' } `
| Out-File $tmpfile -Append
regedit /s $tmpfile
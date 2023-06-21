(Get-WmiObject win32_product | Where-Object Name -Like *Chrome*).Version

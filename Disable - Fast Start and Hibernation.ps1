
New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0 -PropertyType DWord -Force -ea SilentlyContinue;

$Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
$Name = "HibernateEnabled"
$Value = 1

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $Name
    $RegistryCheck = Test-Path HKLM:\SYSTEM\CurrentControlSet\Control\Power\HibernateEnabled
    If (($Registry -eq $Value) -or ($RegistryCheck -eq $false)) {
        Write-Output "Compliant"
        Exit 0
    }
    New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'HibernateEnabled' `
        -Name 'HibernateEnabled' -Value 0 -PropertyType DWord -Force
}
Catch {
    New-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'HibernateEnabled' `
        -Name 'HibernateEnabled' -Value 0 -PropertyType DWord -Force
}
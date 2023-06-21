$Version = (Get-WmiObject win32_product | Where-Object Name -Like *Chrome*).Version
$Build = '111.0.5563.65'

if ($Version -eq $Build) {
    write-output "Detected"
    exit 0
}
else {
    exit 1
}
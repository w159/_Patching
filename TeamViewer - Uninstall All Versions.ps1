

$APPS = Get-WmiObject win32_product
$TeamViewer = $APPS | Where-Object Name -Like "*TeamViewer*"
$TeamViewer.Uninstall()

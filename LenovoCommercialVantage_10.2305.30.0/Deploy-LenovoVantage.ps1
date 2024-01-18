$url = 'https://support.lenovo.com/us/en/solutions/hf003321-lenovo-vantage-for-enterprise'
$response = Invoke-RestMethod -Uri $url
$downloadLink = $response.Links | Where-Object { $_.href -match 'LenovoCommercialVantage.*\.zip' } | Select-Object -ExpandProperty href

$downloadLink

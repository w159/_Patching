$webResponse = (Invoke-WebRequest -UseBasicParsing 'https://product-details.mozilla.org/1.0/firefox_versions.json').Content
$GetLatest = $webResponse | ConvertFrom-Json 
$GetLatest | Select-Object -ExpandProperty "LATEST_FIREFOX_VERSION"
$jarfilenames = "log4j-core-2.17.0.jar"

Set-Location C:\
New-Item -Path C:\ -ItemType Directory -Name 7zip
Invoke-WebRequest -UseBasicParsing "https://onedrive.live.com/download?cid=AF928892EBCFB343&resid=AF928892EBCFB343%21107502&authkey=AOqF-gkw5Yoexm0" -OutFile C:\7zip\7z.exe
Invoke-WebRequest -UseBasicParsing "https://onedrive.live.com/download?cid=AF928892EBCFB343&resid=AF928892EBCFB343%21107501&authkey=AOIuaQpswaQvVO4" -OutFile C:\7zip\7z.dll


foreach ($jarfilename in $jarfilenames){


$searchinfolder = 'C:\*'

$jarfilepaths = Get-ChildItem -Path $searchinfolder -Filter $jarfilename -Recurse | %{$_.FullName}

foreach($jarfilepath in $jarfilepaths){
Set-ItemProperty $jarfilepath -Name IsReadOnly -Value $false}

c:\7zip\7z d jdbcserver.jar org/apache/logging/log4j/core/lookup/JndiLookup.class -r

foreach($jarfilepath in $jarfilepaths){
Set-ItemProperty $jarfilepath -Name IsReadOnly -Value $true}


}
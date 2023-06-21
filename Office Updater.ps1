


$OfficeX64Path = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
$OfficeX32Path = "C:\Program Files (x86)\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
$UpdateCommand = "/update user"
$OfficeX64Test = Test-Path $OfficeX64Path
$OfficeX32Test = Test-Path $OfficeX32Path

If ($OfficeX32Test -eq  $true){
    Start-Process $OfficeX32Path -ArgumentList $UpdateCommand -Wait -WindowStyle Hidden
}

If ($OfficeX64Test -eq $true){
    Start-Process $OfficeX64Path -ArgumentList $UpdateCommand -Wait -WindowStyle Hidden
}



cd ${env:commonprogramfiles(x86)}
$serviceName = "Morpheus Windows Agent"
Start-Transcript -Path "${env:commonprogramfiles(x86)}\morpheus_install_script.log" -Append -Force
$msiPath = "C:\Users\Administrator\Downloads\MorpheusAgentSetup-4_5.msi"
$expectedMD5 = "034720B6626490C53FD0C220562D8ED6"

# Check if the MSI file exists
if (Test-Path $msiPath) {
    echo "Using existing MSI file from $msiPath..."
    
    # Calculate MD5 hash
    $hash = Get-FileHash -Path $msiPath -Algorithm MD5
    echo "Calculated MD5 hash: $($hash.Hash)"
    
    # Verify the hash (case-insensitive comparison)
    if ($hash.Hash -eq $expectedMD5 -or $hash.Hash.ToLower() -eq $expectedMD5) {
        echo "MD5 checksum verification passed."
        
        # Copy the MSI file to the destination folder
        $df = "${env:commonprogramfiles(x86)}\MorpheusAgentSetup.msi"
        Copy-Item -Path $msiPath -Destination $df -Force
        echo "Agent MSI copied to installation directory..."
        $dS = $true
    } else {
        echo "ERROR: MD5 checksum verification failed. The file may be corrupted or modified."
        echo "Expected: $expectedMD5"
        echo "Actual: $($hash.Hash)"
        exit 1
    }
} else {
    echo "Error: MSI file not found at $msiPath"
    exit 1
}

Wait-Process -name msiexec -ErrorAction SilentlyContinue
if(Get-Service $serviceName -ErrorAction SilentlyContinue) {
    Stop-Service -displayname $serviceName -ErrorAction SilentlyContinue
    Stop-Process -Force -processname Morpheus* -ErrorAction SilentlyContinue
    Stop-Process -Force -processname Morpheus* -ErrorAction SilentlyContinue
    Start-Sleep -s 5
    try {
        $serviceId = (get-wmiobject Win32_Product -Filter "Name = 'Morpheus Windows Agent'" | Format-Wide -Property IdentifyingNumber | Out-String).Trim()    
    } 
    Catch {
        $serviceId = $df
    }
    
    cmd.exe /c "msiexec /x $serviceId /q /passive"
}
echo "Running Msi"
$MSIArguments= @(
    "/i"
    "MorpheusAgentSetup.msi"
    "/qn"
    "/norestart"
    "/l*v"
    "morpheus_install.log"
    "apiKey=`"xxxxxxxxxxx`""                  # MODIFY THIS LINE
    "host=`"https://xxxxxxxxxxxx/`""          # MODIFY THIS LINE
    "username=`".\LocalSystem`""
    "vmMode=`"true`"" 
    "verifySsl=`"true`""
    "logLevel=`"3`""
)
$installResults = Start-Process msiexec.exe -Verb runAs -Wait -ArgumentList $MSIArguments
$a = 0
$f = 0
Do {
    try {
        Get-Service $serviceName -ea silentlycontinue -ErrorVariable err
        if([string]::isNullOrEmpty($err)) {
            $f = 1
            Break    
        } else {
            start-sleep -s 10
            $a++
        }
    }
    Catch {
        start-sleep -s 10
        $a++
    }
}
While ($a -ne 6)
Set-Service $serviceName -startuptype "automatic"
$service = Get-WmiObject -Class Win32_Service -Filter "Name='$serviceName'"
& sc.exe failure "$serviceName" reset= 30 actions= restart/30000/restart/30000/restart/4000
if ($service -And $service.State -ne "Running") {Restart-Service -displayname $serviceName}

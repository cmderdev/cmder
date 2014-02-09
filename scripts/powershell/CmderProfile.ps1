if ($env:CMDER_START) {
   Set-Location $env:CMDER_START
}

# Autoinclude every .ps1 script in the autorun folder.
$autoRunFolder = "$PSScriptRoot\autorun\"

if (Test-Path $autoRunFolder) {
    
    Get-ChildItem -Filter *.ps1 -Path $autoRunFolder | ForEach-Object {
        . $_.FullName
    }
    
}
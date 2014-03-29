if ($env:CMDER_START) {
   Set-Location $env:CMDER_START
}

# Autoinclude every .ps1 script in the autorun folder.
$thisDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$autoRunFolder = Join-Path $thisDir "autorun"

if (Test-Path $autoRunFolder) {
    
    Get-ChildItem -Filter *.ps1 -Path $autoRunFolder | ForEach-Object {
        . $_.FullName
    }
    
}
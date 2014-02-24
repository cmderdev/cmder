<#
    Samuel Vasko
    Part of Cmder project
    This script builds dependencies from current vendor/sources.json
    file and unpacks them.
#>

# Configs
$sourcesPath = "..\vendor\sources.json"
$saveTo = "..\vendor\"
# -------

# Check for requirements
Ensure-Exists $sourcesPath
Ensure-Executable "7z"

$sources = Get-Content $sourcesPath | ConvertTo-Json

foreach ($s in $sources) {
    $ext = $s.url.Split('.')[-1]
    Delete-Existing $saveTo + $($s.name)
    Delete-Existing $saveTo + $($s.name) + "." + $ext

    Write-Host "-- Downloading $($s.name) --"
    New-Object System.Net.WebClient
    $wc.DownloadFile($s.url, "..\vendor\" + $s.name + "." + $ext)
    Invoke-Item "7z x " + $s.name + "." + $ex
    if ($LastExitCode != 0) {
        Write-Error "Failied to extract " + $s.name;
        exit 1
    }
}

Write-Host "All good and done!"

function Ensure-Exists ($item) {
    if (!Test-Path $item) {
        Write-Error "Missing required $($item) file"
        exit 1
    }
}

function Delete-Existing ($item) {
    if (Test-Path $item) { Remove-Item $item }
}

function Ensure-Executable ($command) {
    if (!Get-Command $command) {
       Write-Error "Missing $($command)! Ensure it is installed and on in the PATH"
       exit 1
    }
}
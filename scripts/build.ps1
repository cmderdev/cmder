<#
.Synopsis
    Build Cmder
.DESCRIPTION
    Use this script to build your own edition of Cmder

    This script builds dependencies from current vendor/sources.json file and unpacks them.

    You will need to make this script executable by setting your Powershell Execution Policy to Remote signed
    Then unblock the script for execution with UnblockFile .\build.ps1
.EXAMPLE
    .\build.ps1

    Executes the default build for cmder, this is equivalent to the "minimum" style package in the releases
.EXAMPLE
    .\build -verbose

    Execute the build and see what's going on.
.EXAMPLE
    .\build.ps1 -SourcesPath '~/custom/vendors.json'

    Build cmder with your own packages. See vendor/sources.json for the syntax you need to copy.
.NOTES
    AUTHORS
    Samuel Vasko, Jack Bennett
    Part of the Cmder project.
.LINK
    https://github.com/bliker/cmder - Project Home
#>
[CmdletBinding(SupportsShouldProcess=$true)]
Param(
    # CmdletBinding will give us;
    # -verbose switch to turn on logging and
    # -whatif switch to not actually make changes

    # Path to the vendor configuration source file
    [string]$sourcesPath = "..\vendor\sources.json"

    , # Vendor folder locaton
    [string]$saveTo = "..\vendor\"
)

function Ensure-Exists ($item) {
    if (-not (Test-Path $item)) {
        Write-Error "Missing required $item file"
        exit 1
    }
}

function Ensure-Executable ($command) {
    try { Get-Command $command -ErrorAction Stop > $null}
    catch{
       Write-Error "Missing $command! Ensure it is installed and on in the PATH"
       exit 1
    }
}

function Delete-Existing ($path) {
    Write-Verbose "Remove $path"
    Remove-Item -Recurse -force $path -ErrorAction SilentlyContinue
}

# Check for archives that were not extracted correctly
# when the folder contains another folder
function Flatten-Directory ($name) {
    $child = (Get-Childitem $name)[0]
    Rename-Item $name -NewName "$($name)_moving"
    Move-Item -Path "$($name)_moving\$child" -Destination $name
    Remove-Item -Recurse "$($name)_moving"
}

$ErrorActionPreference = "Stop"

# Check for requirements
Ensure-Exists $sourcesPath
Ensure-Executable "7z"

Push-Location -Path $saveTo
$sources = Get-Content $sourcesPath | Out-String | Convertfrom-Json

foreach ($s in $sources) {
    Write-Host "Getting $($s.name) from URL $($s.url)"

    # We do not care about the extensions/type of archive
    $tempArchive = "$($s.name).tmp"
    Delete-Existing $tempArchive
    Delete-Existing $s.name

    Invoke-WebRequest -Uri $s.url -OutFile $tempArchive -ErrorAction Stop
    Invoke-Expression "7z x -y -o$($s.name) $tempArchive"
    Remove-Item $tempArchive

    if ((Get-Childitem $s.name).Count -eq 1) {
        Flatten-Directory($s.name)
    }

}

Pop-Location
Write-Host "All good and done!"

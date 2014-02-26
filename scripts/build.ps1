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
function Delete-Existing ($name) {
    Write-Verbose "Change directory to $($name.path)"
    Push-Location -Path $name.path

    Write-Verbose "Remove $($name.name)"
    Remove-Item -Recurse -force $name.name -ErrorAction SilentlyContinue

    Pop-Location
}

function Expand-Download{
    [CmdletBinding()]
    Param(
        [psobject]$name
    )
    Push-Location -Path $name.path
    Write-Verbose "Extract $($name.package)"

    # As if 7-zip doesn't have a silent output option. Append > `&null to the end to silence it.
    # Also silences the error output
    Invoke-Expression "7z x -y -o$($name.name) $($name.package)"

    Write-Verbose "Delete downloaded archive: $($name.package)"
    Remove-Item $name.package

    Pop-Location
}

# Check for requirements
Ensure-Exists $sourcesPath
Ensure-Executable "7z"

$sources = Get-Content $sourcesPath | Out-String | Convertfrom-Json

foreach ($s in $sources) {
    $s | Add-Member -MemberType NoteProperty -Name 'path' -Value $saveTo
    if( -not $s.package){
        $filename = $s.name + '.' + $s.url.Split('.')[-1]
        $s | Add-Member -MemberType NoteProperty -Name 'package' -Value $filename
    }
    Write-Verbose "URL $($s.url) has package $($s.package)"

    Delete-Existing $s
    Invoke-WebRequest -Uri $s.url -OutFile "H:\src\cmder\vendor\$($s.package)"
    Expand-download $s -ErrorAction SilentlyContinue
}

Write-Host "All good and done!"

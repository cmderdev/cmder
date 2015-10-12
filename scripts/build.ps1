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

    Executes the default build for Cmder; Conemu, clink. This is equivalent to the "minimum" style package in the releases
.EXAMPLE
    .\build.ps1 -Full

    Executes a full build for Cmder, including git. This is equivalent to the "full" style package in the releases
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
    [string]$sourcesPath = "..\vendor\sources.json",

    # Vendor folder location
    [string]$saveTo = "..\vendor\",

    # Launcher folder location
    [string]$launcher = "..\launcher",

    # Config folder location
    [string]$config = "..\config",

    # Include git with the package build
    [switch]$Full
)

. "$PSScriptRoot\utils.ps1"
$ErrorActionPreference = "Stop"

Push-Location -Path $saveTo
$sources = Get-Content $sourcesPath | Out-String | Convertfrom-Json

# Check for requirements
Ensure-Exists $sourcesPath
Ensure-Executable "7z"
New-Item -Type Directory -Path (Join-Path $saveTo "/tmp/") -ErrorAction SilentlyContinue >$null

# Preserve modified (by user) ConEmu setting file
if ($config -ne "") {
    $ConEmuXml = Join-Path $saveTo "conemu-maximus5\ConEmu.xml"
    if (Test-Path $ConEmuXml -pathType leaf) {
        $ConEmuXmlSave = Join-Path $config "ConEmu.xml"
        Write-Verbose "Backup '$ConEmuXml' to '$ConEmuXmlSave'"
        Copy-Item $ConEmuXml $ConEmuXmlSave
    } else { $ConEmuXml = "" }
} else { $ConEmuXml = "" }


foreach ($s in $sources) {
    if($Full -eq $false -and $s.name -eq "git-for-windows"){
        Continue
    }

    Write-Verbose "Getting $($s.name) from URL $($s.url)"

    # We do not care about the extensions/type of archive
    $tempArchive = "tmp/$($s.name).tmp"
    Delete-Existing $tempArchive
    Delete-Existing $s.name

    Invoke-WebRequest -Uri $s.url -OutFile $tempArchive -ErrorAction Stop
    Extract-Archive $tempArchive $s.name

    if ((Get-Childitem $s.name).Count -eq 1) {
        Flatten-Directory($s.name)
    }
    # Write current version to .cmderver file, for later.
    "$($s.version)" | Out-File "$($s.name)/.cmderver"
}

# Restore user configuration
if ($ConEmuXml -ne "") {
    Write-Verbose "Restore '$ConEmuXmlSave' to '$ConEmuXml'"
    Copy-Item $ConEmuXmlSave $ConEmuXml
}

Pop-Location

Push-Location -Path $launcher
msbuild CmderLauncher.vcxproj /p:configuration=Release
Pop-Location

Write-Verbose "All good and done!"

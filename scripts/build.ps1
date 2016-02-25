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
    .\build.ps1 -Compile

    Recompile the launcher executable if you have the requisite build tools for C++ installed.
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
    http://cmder.net/ - Project Home
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

    # New launcher if you have MSBuild tools installed
    [switch]$Compile
)

# Dot source util functions into this scope
. ".\utils.ps1"
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

$vend = $pwd
foreach ($s in $sources) {
    Write-Verbose "Getting $($s.name) from URL $($s.url)"

    # We do not care about the extensions/type of archive
    $tempArchive = "tmp/$($s.name).tmp"
    Delete-Existing $tempArchive
    Delete-Existing $s.name

    Download-File -Url $s.url -File $vend\$tempArchive -ErrorAction Stop
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

if($Compile) {
    Push-Location -Path $launcher
    msbuild CmderLauncher.vcxproj /p:configuration=Release
    if ($LastExitCode -ne 0) {
        throw "msbuild failed to build the executable."
    }
    Pop-Location
} else {
    Write-Warning "You are not building a launcher, Use -Compile"
    Write-Warning "This cannot be a release. Test build only!"
}

# Put vendor\cmder.sh in /etc/profile.d so it runs when we start bash or mintty
if ( (Test-Path $($SaveTo + "git-for-windows/etc/profile.d") ) ) {
  write-verbose "Adding cmder.sh /etc/profile.d"
  Copy-Item $($SaveTo + "cmder.sh") $($SaveTo + "git-for-windows/etc/profile.d/cmder.sh")
}

# Replace /etc/profile.d/git-prompt.sh with cmder lambda prompt so it runs when we start bash or mintty
if ( !(Test-Path $($SaveTo + "git-for-windows/etc/profile.d/git-prompt.sh.bak") ) ) {
  write-verbose "Replacing /etc/profile.d/git-prompt.sh with our git-prompt.sh"
  Move-Item $($SaveTo + "git-for-windows/etc/profile.d/git-prompt.sh") $($SaveTo + "git-for-windows/etc/profile.d/git-prompt.sh.bak")
  Copy-Item $($SaveTo + "git-prompt.sh") $($SaveTo + "git-for-windows/etc/profile.d/git-prompt.sh")
}

Write-Verbose "All good and done!"

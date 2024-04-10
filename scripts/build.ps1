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

    Executes the default build for Cmder; ConEmu, clink. This is equivalent to the "minimum" style package in the releases
.EXAMPLE
    .\build.ps1 -Compile

    Recompile the launcher executable if you have the requisite build tools for C++ installed.
.EXAMPLE
    .\build.ps1 -Compile -NoVendor

    Skip all downloads and only build launcher.
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
    http://cmder.app/ - Project Home
#>
[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    # CmdletBinding will give us;
    # -verbose switch to turn on logging and
    # -whatif switch to not actually make changes

    # Path to the vendor configuration source file
    [string]$sourcesPath = "$PSScriptRoot\..\vendor\sources.json",

    # Vendor folder location
    [string]$saveTo = "$PSScriptRoot\..\vendor\",

    # Launcher folder location
    [string]$launcher = "$PSScriptRoot\..\launcher",

    # Config folder location
    [string]$config = "$PSScriptRoot\..\config",

    # Using this option will skip all downloads, if you only need to build launcher
    [switch]$noVendor,

    # Build launcher if you have MSBuild tools installed
    [switch]$Compile
)

# Get the scripts and cmder root dirs we are building in.
$cmder_root = Resolve-Path "$PSScriptRoot\.."

# Dot source util functions into this scope
. "$PSScriptRoot\utils.ps1"
$ErrorActionPreference = "Stop"

if ($Compile) {
    # Check for requirements
    Ensure-Executable "msbuild"

    # Get the version string
    $version = Get-VersionStr

    Push-Location -Path $launcher
    Create-RC $version ($launcher + '\src\version.rc2')

    Write-Verbose "Building the launcher..."

    # Reference: https://docs.microsoft.com/visualstudio/msbuild/msbuild-command-line-reference
    msbuild CmderLauncher.vcxproj /t:Clean,Build /p:configuration=Release /m

    if ($LastExitCode -ne 0) {
        throw "MSBuild failed to build the launcher executable."
    }
    Pop-Location
}

if (-not $noVendor) {
    # Check for requirements
    Ensure-Exists $sourcesPath
    Ensure-Executable "7z"

    # Get the vendor sources
    $sources = Get-Content $sourcesPath | Out-String | ConvertFrom-Json

    Push-Location -Path $saveTo
    New-Item -Type Directory -Path (Join-Path $saveTo "/tmp/") -ErrorAction SilentlyContinue >$null

    $vend = $pwd

    # Preserve modified (by user) ConEmu setting file
    if ($config -ne "") {
        $ConEmuXml = Join-Path $saveTo "conemu-maximus5\ConEmu.xml"
        if (Test-Path $ConEmuXml -pathType leaf) {
            $ConEmuXmlSave = Join-Path $config "ConEmu.xml"
            Write-Verbose "Backup '$ConEmuXml' to '$ConEmuXmlSave'"
            Copy-Item $ConEmuXml $ConEmuXmlSave
        }
        else { $ConEmuXml = "" }
    }
    else { $ConEmuXml = "" }

    # Kill ssh-agent.exe if it is running from the $env:cmder_root we are building
    foreach ($ssh_agent in $(Get-Process ssh-agent -ErrorAction SilentlyContinue)) {
        if ([string]$($ssh_agent.path) -Match [string]$cmder_root.replace('\', '\\')) {
            Write-Verbose $("Stopping " + $ssh_agent.path + "!")
            Stop-Process $ssh_agent.id
        }
    }

    foreach ($s in $sources) {
        Write-Verbose "Getting vendored $($s.name) $($s.version)..."

        # We do not care about the extensions/type of archive
        $tempArchive = "tmp/$($s.name).tmp"
        Delete-Existing $tempArchive
        Delete-Existing $s.name

        Download-File -Url $s.url -File $vend\$tempArchive -ErrorAction Stop
        Extract-Archive $tempArchive $s.name

        if ((Get-ChildItem $s.name).Count -eq 1) {
            Flatten-Directory($s.name)
        }

        # Write current version to .cmderver file, for later.
        "$($s.version)" | Out-File "$($s.name)/.cmderver"
    }

    # Restore ConEmu user configuration
    if ($ConEmuXml -ne "") {
        Write-Verbose "Restore '$ConEmuXmlSave' to '$ConEmuXml'"
        Copy-Item $ConEmuXmlSave $ConEmuXml
    }

    # Put vendor\cmder.sh in /etc/profile.d so it runs when we start bash or mintty
    if ( (Test-Path $($saveTo + "git-for-windows/etc/profile.d") ) ) {
        Write-Verbose "Adding cmder.sh /etc/profile.d"
        Copy-Item $($saveTo + "cmder.sh") $($saveTo + "git-for-windows/etc/profile.d/cmder.sh")
    }

    # Replace /etc/profile.d/git-prompt.sh with cmder lambda prompt so it runs when we start bash or mintty
    if ( !(Test-Path $($saveTo + "git-for-windows/etc/profile.d/git-prompt.sh.bak") ) ) {
        Write-Verbose "Replacing /etc/profile.d/git-prompt.sh with our git-prompt.sh"
        Move-Item $($saveTo + "git-for-windows/etc/profile.d/git-prompt.sh") $($saveTo + "git-for-windows/etc/profile.d/git-prompt.sh.bak")
        Copy-Item $($saveTo + "git-prompt.sh") $($saveTo + "git-for-windows/etc/profile.d/git-prompt.sh")
    }

    Pop-Location
}

if (-not $Compile -or $noVendor) {
    Write-Warning "You are not building the full project, Use -Compile without -noVendor"
    Write-Warning "This cannot be a release. Test build only!"
    return
}

Write-Verbose "Successfully built Cmder v$version!"

if ( $Env:APPVEYOR -eq 'True' ) {
    Add-AppveyorMessage -Message "Building Cmder v$version was successful." -Category Information
}

if ( $Env:GITHUB_ACTIONS -eq 'true' ) {
    Write-Output "::notice title=Build Complete::Building Cmder v$version was successful."
}

Write-Host -ForegroundColor green "All good and done!"

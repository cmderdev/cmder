<#
.Synopsis
    Pack Cmder
.DESCRIPTION
    Use this script to pack Cmder into release archives

    You will need to make this script executable by setting your Powershell Execution Policy to Remote signed
    Then unblock the script for execution with UnblockFile .\pack.ps1
.PARAMETER cmderRoot
    Path to the Cmder repository root that should be packaged.

    Defaults to the parent directory of this script.
.PARAMETER terminal
    Select which terminal package set is included in generated archives:
    - all: create all archive variants (default)
    - none: exclude both ConEmu and Windows Terminal packages
    - conemu-maximus5: include only ConEmu package
    - windows-terminal: include only Windows Terminal package
.PARAMETER saveTo
    Output directory where archives and hashes.txt are written.

    Defaults to the repository build directory.
.PARAMETER Verbose
    Built-in common parameter from CmdletBinding.

    Prints detailed packaging progress and included files.
.PARAMETER WhatIf
    Built-in common parameter from CmdletBinding (SupportsShouldProcess).

    Shows what actions would run without making changes.
.EXAMPLE
    .\pack.ps1

    Creates default archives for Cmder
.EXAMPLE
    .\pack.ps1 -Verbose

    Creates default archives for Cmder with plenty of information
.EXAMPLE
    .\pack.ps1 -Terminal none

    Create archives without bundled terminal emulator packages.
.EXAMPLE
    .\pack.ps1 -Terminal conemu-maximus5

    Create archives that include ConEmu and exclude Windows Terminal.
.EXAMPLE
    .\pack.ps1 -Terminal windows-terminal

    Create archives that include Windows Terminal and exclude ConEmu.
.EXAMPLE
    .\pack.ps1 -SaveTo 'C:\temp\cmder-artifacts'

    Write release archives and hashes.txt to a custom output directory.
.EXAMPLE
    .\pack.ps1 -CmderRoot 'C:\src\cmder'

    Package a Cmder checkout from a custom repository path.
.EXAMPLE
    .\pack.ps1 -WhatIf

    Preview packaging actions without creating or deleting files.
.NOTES
    AUTHORS
    Samuel Vasko, Jack Bennett, Martin Kemp
    Part of the Cmder project.
.LINK
    https://github.com/cmderdev/cmder - Project Home
#>

[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    # CmdletBinding will give us;
    # -verbose switch to turn on logging and
    # -whatif switch to not actually make changes

    # Path to the vendor configuration source file
    [string]$cmderRoot = "$PSScriptRoot\..",

    # Using this option will pack artifacts for a specific included terminal emulator [none, all, conemu-maximus5, or windows-terminal]
    [string]$terminal = 'all',

    # Vendor folder locaton
    [string]$saveTo = "$PSScriptRoot\..\build"
)

$cmderRoot = Resolve-Path $cmderRoot

. "$PSScriptRoot\utils.ps1"
$ErrorActionPreference = "Stop"
Ensure-Executable "7z"

if ($terminal -eq "none") {
    $targets = @{
      "cmder_win.7z"       = "-t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -myx=7 -mqs=on -xr!`"vendor\conemu-maximus5`" -xr!`"vendor\windows-terminal`"";
      "cmder_win.zip"      = "-mm=Deflate -mfb=128 -mpass=3 -xr!`"vendor\conemu-maximus5`" -xr!`"vendor\windows-terminal`"";
      "cmder_win.mini.zip" = "-xr!`"vendor\git-for-windows`" -xr!`"vendor\conemu-maximus5`" -xr!`"vendor\windows-terminal`"";
    }
} elseif ($terminal -eq "windows-terminal") {
    $targets = @{
      "cmder_wt.7z"       = "-t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -myx=7 -mqs=on -xr!`"vendor\conemu-maximus5`"";
      "cmder_wt.zip"      = "-mm=Deflate -mfb=128 -mpass=3 -xr!`"vendor\conemu-maximus5`"";
      "cmder_wt_mini.zip" = "-xr!`"vendor\git-for-windows`" -xr!`"vendor\conemu-maximus5`"";
    }
} else {
    $targets = @{
      "cmder_win.7z"       = "-t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -myx=7 -mqs=on -xr!`"vendor\conemu-maximus5`" -xr!`"vendor\windows-terminal`"";
      "cmder_win.zip"      = "-mm=Deflate -mfb=128 -mpass=3 -xr!`"vendor\conemu-maximus5`" -xr!`"vendor\windows-terminal`"";
      "cmder_win_mini.zip" = "-xr!`"vendor\git-for-windows`" -xr!`"vendor\conemu-maximus5`" -xr!`"vendor\windows-terminal`"";
      "cmder_wt.7z"       = "-t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -myx=7 -mqs=on -xr!`"vendor\conemu-maximus5`"";
      "cmder_wt.zip"      = "-mm=Deflate -mfb=128 -mpass=3 -xr!`"vendor\conemu-maximus5`"";
      "cmder_wt_mini.zip" = "-xr!`"vendor\git-for-windows`" -xr!`"vendor\conemu-maximus5`"";
      "cmder.7z"       = "-t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -myx=7 -mqs=on -xr!`"vendor\windows-terminal`"";
      "cmder.zip"      = "-mm=Deflate -mfb=128 -mpass=3 -xr!`"vendor\windows-terminal`"";
      "cmder_mini.zip" = "-xr!`"vendor\git-for-windows`" -xr!`"vendor\windows-terminal`"";
    }
}

Push-Location -Path $cmderRoot

Delete-Existing "$cmderRoot\Version*"
Delete-Existing "$cmderRoot\build\*"

if (-not (Test-Path -PathType container $saveTo)) {
    (New-Item -ItemType Directory -Path $saveTo) | Out-Null
}

$saveTo = Resolve-Path $saveTo

$version = Get-VersionStr
(New-Item -ItemType file "$cmderRoot\Version $version") | Out-Null

if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
    Write-Verbose "Packing Cmder $version in $saveTo..."
    $excluded = (Get-Content -Path "$cmderRoot\packignore") -Split [System.Environment]::NewLine | Where-Object { $_ }
    Get-ChildItem $cmderRoot -Force -Exclude $excluded
}

foreach ($t in $targets.GetEnumerator()) {
    Create-Archive "$cmderRoot" "$saveTo\$($t.Name)" $t.Value
    $hash = (Digest-Hash "$saveTo\$($t.Name)")
    Add-Content -path "$saveTo\hashes.txt" -value ($t.Name + ' ' + $hash)
}

Pop-Location

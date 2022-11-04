<#
.Synopsis
    Pack Cmder
.DESCRIPTION
    Use this script to pack cmder into release archives

    You will need to make this script executable by setting your Powershell Execution Policy to Remote signed
    Then unblock the script for execution with UnblockFile .\pack.ps1
.EXAMPLE
    .\pack.ps1

    Creates default archives for cmder
.EXAMPLE
    .\pack.ps1 -verbose

    Creates default archives for cmder with plenty of information
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

    # Vendor folder locaton
    [string]$saveTo = "$PSScriptRoot\..\build"
)

$cmderRoot = Resolve-Path $cmderRoot

. "$PSScriptRoot\utils.ps1"
$ErrorActionPreference = "Stop"
Ensure-Executable "7z"

$targets = @{
    "cmder.7z"       = "-t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -myx=7 -mqs=on";
    "cmder.zip"      = "-mm=Deflate -mfb=128 -mpass=3";
    "cmder_mini.zip" = "-xr!`"vendor\git-for-windows`"";
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

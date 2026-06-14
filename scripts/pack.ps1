<#
.Synopsis
    Pack Cmder
.DESCRIPTION
    Use this script to pack Cmder into release archives

    You will need to make this script executable by setting your Powershell Execution Policy to Remote signed
    Then unblock the script for execution with UnblockFile .\pack.ps1
.EXAMPLE
    .\pack.ps1

    Creates default archives for Cmder
.EXAMPLE
    .\pack.ps1 -Verbose

    Creates default archives for Cmder with plenty of information
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
    # -Verbose switch to turn on logging and
    # -whatif switch to not actually make changes

    # Path to the vendor configuration source file
    [string]$cmderRoot = "$PSScriptRoot\..",

    # Using this option will pack artifacts for a specific included terminal emulator [none, all, conemu-maximus5, or windows-terminal]
    [string]$Terminal = 'all',

    # Vendor folder locaton
    [string]$saveTo = "$PSScriptRoot\..\build"
)

$cmderRoot = Resolve-Path $cmderRoot

. "$PSScriptRoot\utils.ps1"
$ErrorActionPreference = "Stop"
Ensure-Executable "7z"

function Get-ArchiveFlags {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Kind,

        [string[]]$IncludedVendors = @(),

        [string[]]$AllVendors = @()
    )

    if ($Kind -eq "7z") {
        $flags = "-t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -myx=7 -mqs=on"
    } else {
        $flags = "-mm=Deflate -mfb=128 -mpass=3"
    }

    $archiveExcludedVendors = @($AllVendors | Where-Object { $IncludedVendors -notcontains $_ })

    foreach ($vendor in $archiveExcludedVendors) {
        $flags += " -xr!`"vendor\$vendor`""
    }

    return $flags
}

Push-Location -Path $cmderRoot

Delete-Existing "$cmderRoot\Version*"
Delete-Existing "$saveTo\*"

if (-not (Test-Path -PathType container $saveTo)) {
    (New-Item -ItemType Directory -Path $saveTo) | Out-Null
}

$saveTo = Resolve-Path $saveTo
$profiles = Get-CmderPackageProfiles -Terminal $Terminal
$allVendors = @(Get-CmderVendorNames)
$version = Get-VersionStr
(New-Item -ItemType file "$cmderRoot\Version $version") | Out-Null

if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
    Write-Verbose "Packing Cmder $version in $saveTo..."
    $excluded = (Get-Content -Path "$cmderRoot\packignore") -Split [System.Environment]::NewLine | Where-Object { $_ }
    Get-ChildItem $cmderRoot -Force -Exclude $excluded
}

foreach ($profile in $profiles) {
    $profilePath = Join-Path $saveTo $profile.outputFolder
    if (-not (Test-Path -PathType container $profilePath)) {
        (New-Item -ItemType Directory -Path $profilePath) | Out-Null
    }

    $archives = @(
        @{ Name = "$($profile.outputFolder).7z"; Kind = "7z"; Mini = $false },
        @{ Name = "$($profile.outputFolder).zip"; Kind = "zip"; Mini = $false },
        @{ Name = "$($profile.outputFolder)_mini.zip"; Kind = "zip"; Mini = $true }
    )

    Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $profilePath "hashes.txt")

    foreach ($archive in $archives) {
        $outputPath = Join-Path $profilePath $archive.Name
        $includedVendors = @($profile.includedVendors)
        if ($archive.Mini) {
            $includedVendors = @($includedVendors | Where-Object { $_ -ne "git-for-windows" })
        }

        $flags = Get-ArchiveFlags -Kind $archive.Kind -IncludedVendors $includedVendors -AllVendors $allVendors
        Create-Archive "$cmderRoot" $outputPath $flags
        $hash = Digest-Hash $outputPath
        Add-Content -Path (Join-Path $profilePath "hashes.txt") -Value ($archive.Name + "`t" + $hash)
    }
}

Pop-Location

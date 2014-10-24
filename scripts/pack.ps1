<#
.Synopsis
    Pack cmder
.DESCRIPTION
    Use this script to pack cmder into release archives

    You will need to make this script executable by setting your Powershell Execution Policy to Remote signed
    Then unblock the script for execution with UnblockFile .\pack.ps1
.EXAMPLE
    .\pack.ps1

    Creates default archives for cmder
.EXAMPLE
    .\build -verbose

    Creates default archives for cmder with plenty of information
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
    [string]$cmderRoot = "..",

    # Vendor folder locaton
    [string]$saveTo = "..\build"
)

. "$PSScriptRoot\utils.ps1"
$ErrorActionPreference = "Stop"
Ensure-Executable "7z"

$targets = @{
    "cmder.zip" = $null;
    "cmder.7z" = $null;
    "cmder_mini.zip" = "-x!`"vendor\msysgit`"";
}

Delete-Existing "..\Version*"

$version = Invoke-Expression "git describe --abbrev=0 --tags"
(New-Item -ItemType file "$cmderRoot\Version $version") | Out-Null

foreach ($t in $targets.GetEnumerator()) {
    Create-Archive $cmderRoot "$saveTo\$($t.Name)" $t.Value
    $hash = (Digest-MD5 "$saveTo\$($t.Name)")
    Add-Content "$saveTo\hashes.txt" $hash
}
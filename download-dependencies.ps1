[CmdletBinding()]
param(
    [Parameter()]
    [switch]
    $IncludeMsysgit
)

$ErrorActionPreference = "Stop"

if (!(Get-Command "7z.exe" -ErrorAction SilentlyContinue)) {
    throw "7zip not found on this computer. Please make sure 7z.exe is on your PATH environment variable."
}

$rootDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$vendorDir = Join-Path $rootDir "vendor"

function getDependency($TempPackageName = "temp.7z", $PackageUrl, $ExtractDirName) {
    
    $packageFilePath = Join-Path $vendorDir $TempPackageName
    if (Test-Path $packageFilePath) {
        rm $packageFilePath
    }
    
    $extractDirPath = Join-Path $vendorDir $ExtractDirName
    if (Test-Path $extractDirPath) {
        rm -Recurse $extractDirPath
    }
    
    Invoke-WebRequest $PackageUrl -OutFile $packageFilePath
    & "7z.exe" "x", "-o""$extractDirPath""", $packageFilePath
    
    rm $packageFilePath
}

Write-Verbose "Downloading/extracting clink..."

getDependency `
    -PackageUrl "http://clink.googlecode.com/files/clink_0.4_setup.exe" `
    -ExtractDirName "clink"

Write-Verbose "Downloading/extracting ConEmu..."

getDependency `
    -PackageUrl "http://conemu-maximus5.googlecode.com/files/ConEmuPack.131107.7z" `
    -ExtractDirName "conemu-maximus5"

if ($IncludeMsysgit) {
    
    Write-Verbose "Downloading/extracting msysgit..."

    getDependency `
        -PackageUrl "http://msysgit.googlecode.com/files/PortableGit-1.8.5.2-preview20131230.7z" `
        -ExtractDirName "msysgit"
    
}
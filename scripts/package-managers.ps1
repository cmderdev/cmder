<#
.Synopsis
    Generate package-manager release files for Cmder.
.DESCRIPTION
    Renders WinGet manifests and Chocolatey package sources from an official
    Cmder release tag and hashes.txt file. This script does not publish or push
    anything to external registries.
.EXAMPLE
    .\package-managers.ps1 -Version 1.3.25 -ReleaseTag v1.3.25 -ReleaseDate 2024-05-31

    Generates files under ..\build\package-managers using hashes.txt from the
    official GitHub release.
.EXAMPLE
    .\package-managers.ps1 -Version 1.3.25 -ReleaseTag v1.3.25 -HashesPath ..\build\hashes.txt

    Generates files from a local release build hashes.txt file.
#>

[CmdletBinding()]
Param(
    [string]$Version = "",

    [string]$ReleaseTag = "",

    [string]$ReleaseDate = (Get-Date -Format "yyyy-MM-dd"),

    [string]$Repository = "cmderdev/cmder",

    [string]$AssetBaseUrl = "",

    [string]$HashesPath = "$PSScriptRoot\..\build\hashes.txt",

    [string]$OutputPath = "$PSScriptRoot\..\build\package-managers",

    [switch]$Clean
)

$ErrorActionPreference = "Stop"

function Get-CmderVersion {
    if ($Version) {
        return ($Version -replace "^v", "")
    }

    $versionString = ""
    if (Get-Command "git.exe" -ErrorAction SilentlyContinue) {
        $gitPresent = git rev-parse --is-inside-work-tree 2>$null
        if ($gitPresent -eq "true") {
            $versionString = git describe --abbrev=0 --tags 2>$null
        }
    }

    if (-not $versionString) {
        $changelogPath = Resolve-Path "$PSScriptRoot\..\CHANGELOG.md"
        $match = Select-String -Path $changelogPath -Pattern "^## \[(?<version>[\w\-\.]+)\]\([^\n()]+\)\s+\([^\n()]+\)$" | Select-Object -First 1
        if ($match) {
            $versionString = $match.Matches[0].Groups["version"].Value
        }
    }

    if (-not $versionString) {
        throw "Could not determine Cmder version. Pass -Version explicitly."
    }

    return ($versionString -replace "^v+", "")
}

function New-Utf8NoBomEncoding {
    return New-Object System.Text.UTF8Encoding($false)
}

function Write-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string[]]$Lines
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -PathType Container $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }

    $content = ($Lines -join [Environment]::NewLine) + [Environment]::NewLine
    [System.IO.File]::WriteAllText($Path, $content, (New-Utf8NoBomEncoding))
}

function Read-ReleaseHashes {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$HashesUrl
    )

    $resolvedPath = $Path
    if (-not (Test-Path -PathType Leaf $resolvedPath)) {
        $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ("cmder-hashes-{0}.txt" -f ([System.Guid]::NewGuid()))
        Write-Verbose "Downloading release hashes from $HashesUrl"
        Invoke-WebRequest -UseBasicParsing -Uri $HashesUrl -OutFile $tempPath
        $resolvedPath = $tempPath
    }

    $hashes = @{}
    foreach ($line in Get-Content -Path $resolvedPath) {
        if ($line -match "^\s*(\S+)\s+([A-Fa-f0-9]{64})\s*$") {
            $hashes[$Matches[1]] = $Matches[2].ToUpperInvariant()
        }
    }

    foreach ($asset in @("cmder.zip", "cmder.7z", "cmder_mini.zip")) {
        if (-not $hashes.ContainsKey($asset)) {
            throw "Could not find SHA256 hash for '$asset' in '$resolvedPath'."
        }
    }

    return $hashes
}

function New-WinGetManifest {
    param(
        [Parameter(Mandatory = $true)][string]$PackageIdentifier,
        [Parameter(Mandatory = $true)][string]$PackageName,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][string]$AssetName,
        [Parameter(Mandatory = $true)][string]$AssetSha256,
        [Parameter(Mandatory = $true)][string]$Architecture,
        [Parameter(Mandatory = $true)][string]$PackageVersion,
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$Date,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $packageLeaf = ($PackageIdentifier -split "\.")[-1]
    $manifestPath = Join-Path $Destination ("winget\manifests\c\Cmder\{0}\{1}" -f $packageLeaf, $PackageVersion)
    $schemaVersion = "1.10.0"

    Write-TextFile -Path (Join-Path $manifestPath "$PackageIdentifier.yaml") -Lines @(
        "# yaml-language-server: `$schema=https://aka.ms/winget-manifest.version.$schemaVersion.schema.json",
        "",
        "PackageIdentifier: $PackageIdentifier",
        "PackageVersion: $PackageVersion",
        "DefaultLocale: en-US",
        "ManifestType: version",
        "ManifestVersion: $schemaVersion"
    )

    Write-TextFile -Path (Join-Path $manifestPath "$PackageIdentifier.locale.en-US.yaml") -Lines @(
        "# yaml-language-server: `$schema=https://aka.ms/winget-manifest.defaultLocale.$schemaVersion.schema.json",
        "",
        "PackageIdentifier: $PackageIdentifier",
        "PackageVersion: $PackageVersion",
        "PackageLocale: en-US",
        "Publisher: Cmder",
        "PublisherUrl: https://github.com/cmderdev",
        "PublisherSupportUrl: https://github.com/cmderdev/cmder/issues",
        "Author: Samuel Vasko",
        "PackageName: $PackageName",
        "PackageUrl: https://cmder.app",
        "License: MIT",
        "LicenseUrl: https://github.com/cmderdev/cmder/blob/master/LICENSE",
        "Copyright: Copyright (c) 2016 Samuel Vasko",
        "ShortDescription: Lovely console emulator package for Windows.",
        "Description: >-",
        "  $Description",
        "Moniker: cmder",
        "Tags:",
        "- cmder",
        "- conemu",
        "- console",
        "- terminal",
        "ReleaseNotesUrl: https://github.com/cmderdev/cmder/releases/tag/$Tag",
        "ManifestType: defaultLocale",
        "ManifestVersion: $schemaVersion"
    )

    Write-TextFile -Path (Join-Path $manifestPath "$PackageIdentifier.installer.yaml") -Lines @(
        "# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.$schemaVersion.schema.json",
        "",
        "PackageIdentifier: $PackageIdentifier",
        "PackageVersion: $PackageVersion",
        "InstallerType: zip",
        "NestedInstallerType: portable",
        "NestedInstallerFiles:",
        "- RelativeFilePath: Cmder.exe",
        "  PortableCommandAlias: cmder",
        "ArchiveBinariesDependOnPath: true",
        "UpgradeBehavior: install",
        "Commands:",
        "- cmder",
        "ReleaseDate: $Date",
        "Installers:",
        "- Architecture: $Architecture",
        "  InstallerUrl: $BaseUrl/$AssetName",
        "  InstallerSha256: $AssetSha256",
        "ManifestType: installer",
        "ManifestVersion: $schemaVersion"
    )
}

function New-ChocolateyPackage {
    param(
        [Parameter(Mandatory = $true)][string]$PackageId,
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][string]$Notes,
        [Parameter(Mandatory = $true)][string]$AssetName,
        [Parameter(Mandatory = $true)][string]$AssetSha256,
        [Parameter(Mandatory = $true)][string]$PackageVersion,
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $packageRoot = Join-Path $Destination "chocolatey\$PackageId"
    $toolsPath = Join-Path $packageRoot "tools"
    $legalPath = Join-Path $packageRoot "legal"

    New-Item -ItemType Directory -Path $toolsPath -Force | Out-Null
    New-Item -ItemType Directory -Path $legalPath -Force | Out-Null

    Write-TextFile -Path (Join-Path $packageRoot "$PackageId.nuspec") -Lines @(
        "<?xml version=`"1.0`" encoding=`"utf-8`"?>",
        "<package xmlns=`"http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd`">",
        "  <metadata>",
        "    <id>$PackageId</id>",
        "    <version>$PackageVersion</version>",
        "    <packageSourceUrl>https://github.com/cmderdev/cmder</packageSourceUrl>",
        "    <owners>cmderdev</owners>",
        "    <title>$Title</title>",
        "    <authors>Samuel Vasko</authors>",
        "    <projectUrl>https://cmder.app/</projectUrl>",
        "    <licenseUrl>https://github.com/cmderdev/cmder/blob/master/LICENSE</licenseUrl>",
        "    <requireLicenseAcceptance>false</requireLicenseAcceptance>",
        "    <projectSourceUrl>https://github.com/cmderdev/cmder/</projectSourceUrl>",
        "    <docsUrl>https://github.com/cmderdev/cmder/wiki</docsUrl>",
        "    <bugTrackerUrl>https://github.com/cmderdev/cmder/issues</bugTrackerUrl>",
        "    <tags>cmder console terminal cli foss</tags>",
        "    <summary>Lovely console emulator package for Windows</summary>",
        "    <description><![CDATA[$Description",
        "",
        "$Notes",
        "]]></description>",
        "    <releaseNotes>https://github.com/cmderdev/cmder/releases/tag/$Tag</releaseNotes>",
        "    <dependencies>",
        "      <dependency id=`"vcredist2010`" version=`"10.0.40219.2`" />",
        "    </dependencies>",
        "  </metadata>",
        "  <files>",
        "    <file src=`"legal\**`" target=`"legal`" />",
        "    <file src=`"tools\**`" target=`"tools`" />",
        "  </files>",
        "</package>"
    )

    Write-TextFile -Path (Join-Path $toolsPath "chocolateyInstall.ps1") -Lines @(
        "`$ErrorActionPreference = 'Stop'",
        "",
        "`$installPath = Join-Path (Get-ToolsLocation) `$env:ChocolateyPackageName",
        "",
        "`$packageArgs = @{",
        "  packageName    = `$env:ChocolateyPackageName",
        "  unzipLocation  = `$installPath",
        "  url            = '$BaseUrl/$AssetName'",
        "  checksum       = '$AssetSha256'",
        "  checksumType   = 'sha256'",
        "}",
        "",
        "Install-ChocolateyZipPackage @packageArgs",
        "Install-ChocolateyPath `$installPath 'User'"
    )

    Write-TextFile -Path (Join-Path $toolsPath "chocolateyUninstall.ps1") -Lines @(
        "`$ErrorActionPreference = 'Stop'",
        "",
        "`$toolsPath = Split-Path -Parent `$MyInvocation.MyCommand.Definition",
        "`$unScriptPath = Join-Path `$toolsPath 'Uninstall-ChocolateyPath.psm1'",
        "`$installPath = Join-Path (Get-ToolsLocation) `$env:ChocolateyPackageName",
        "",
        "Import-Module `$unScriptPath",
        "Uninstall-ChocolateyPath `$installPath 'User'",
        "",
        "if (Test-Path `$installPath) {",
        "  Remove-Item -Path `$installPath -Recurse -Force",
        "}"
    )

    Write-TextFile -Path (Join-Path $legalPath "VERIFICATION.txt") -Lines @(
        "VERIFICATION",
        "",
        "This package downloads Cmder from the official GitHub release.",
        "",
        "Package: $PackageId",
        "Version: $PackageVersion",
        "Release: https://github.com/cmderdev/cmder/releases/tag/$Tag",
        "File: $BaseUrl/$AssetName",
        "Checksum type: sha256",
        "Checksum: $AssetSha256"
    )

    $licenseSource = Resolve-Path "$PSScriptRoot\..\LICENSE"
    Copy-Item -Path $licenseSource -Destination (Join-Path $legalPath "LICENSE.txt") -Force
}

$packageVersion = Get-CmderVersion
if (-not $ReleaseTag) {
    $ReleaseTag = "v$packageVersion"
}

if (-not $AssetBaseUrl) {
    $AssetBaseUrl = "https://github.com/$Repository/releases/download/$ReleaseTag"
}

$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

if ($Clean -and (Test-Path $OutputPath)) {
    Remove-Item -Path $OutputPath -Recurse -Force
}

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

$hashes = Read-ReleaseHashes -Path $HashesPath -HashesUrl "$AssetBaseUrl/hashes.txt"

$cmderDescription = "Cmder is a portable console emulator package for Windows. It combines ConEmu, Clink, a custom prompt layout, and Cmder defaults for a productive Windows command-line experience."
$cmderMiniDescription = "Cmder Mini is the smaller Cmder package for Windows. It includes Cmder's console experience without the vendored Git for Windows tools included in the full package."

New-WinGetManifest `
    -PackageIdentifier "Cmder.Cmder" `
    -PackageName "Cmder" `
    -Description $cmderDescription `
    -AssetName "cmder.zip" `
    -AssetSha256 $hashes["cmder.zip"] `
    -Architecture "x64" `
    -PackageVersion $packageVersion `
    -Tag $ReleaseTag `
    -BaseUrl $AssetBaseUrl `
    -Date $ReleaseDate `
    -Destination $OutputPath

New-WinGetManifest `
    -PackageIdentifier "Cmder.CmderMini" `
    -PackageName "Cmder Mini" `
    -Description $cmderMiniDescription `
    -AssetName "cmder_mini.zip" `
    -AssetSha256 $hashes["cmder_mini.zip"] `
    -Architecture "neutral" `
    -PackageVersion $packageVersion `
    -Tag $ReleaseTag `
    -BaseUrl $AssetBaseUrl `
    -Date $ReleaseDate `
    -Destination $OutputPath

New-ChocolateyPackage `
    -PackageId "Cmder" `
    -Title "Cmder" `
    -Description $cmderDescription `
    -Notes "This package installs the full Cmder archive, including vendored Git for Windows. See cmdermini for the smaller package without vendored Git." `
    -AssetName "cmder.zip" `
    -AssetSha256 $hashes["cmder.zip"] `
    -PackageVersion $packageVersion `
    -Tag $ReleaseTag `
    -BaseUrl $AssetBaseUrl `
    -Destination $OutputPath

New-ChocolateyPackage `
    -PackageId "cmdermini" `
    -Title "Cmder Mini" `
    -Description $cmderMiniDescription `
    -Notes "This package installs the mini Cmder archive without vendored Git for Windows. See Cmder for the full package." `
    -AssetName "cmder_mini.zip" `
    -AssetSha256 $hashes["cmder_mini.zip"] `
    -PackageVersion $packageVersion `
    -Tag $ReleaseTag `
    -BaseUrl $AssetBaseUrl `
    -Destination $OutputPath

Write-Host "Generated package-manager files in $OutputPath"

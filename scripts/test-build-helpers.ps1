[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'utils.ps1')
Ensure-Executable '7z'

$testParent = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$testRoot = Join-Path $testParent ('cmder-build-helpers-' + [guid]::NewGuid().ToString('N'))
$originalLocation = $PWD.Path
$cases = 0

try {
    $null = New-Item -ItemType Directory -Path $testRoot
    $source = Join-Path $testRoot 'source [literal] $(throw INJECTION); & text'
    $null = New-Item -ItemType Directory -Path $source
    $null = New-Item -ItemType Directory -Path (Join-Path $source 'vendor\drop')
    Set-Content -LiteralPath (Join-Path $source 'kept.txt') -Value 'expected payload' -Encoding ascii
    Set-Content -LiteralPath (Join-Path $source 'vendor\drop\excluded.txt') -Value 'excluded payload' -Encoding ascii
    Set-Content -LiteralPath (Join-Path $source 'packignore') -Value 'packignore' -Encoding ascii
    $archive = Join-Path $testRoot 'archive [literal] $(throw INJECTION).zip'
    Create-Archive $source $archive @('-tzip', '-xr!vendor\drop')
    if ($PWD.Path -ne $originalLocation -or -not (Test-Path -LiteralPath $archive)) {
        throw 'Archive creation failed to preserve literal paths or restore the working directory.'
    }
    & 7z t $archive > $null
    if ($LASTEXITCODE -ne 0) { throw 'The created archive failed integrity verification.' }
    $listing = (& 7z l -slt -ba $archive) -join "`n"
    if ($LASTEXITCODE -ne 0 -or $listing -notmatch 'Path = kept\.txt' -or $listing -match 'excluded\.txt') {
        throw 'Archive content or array-based vendor exclusion is incorrect.'
    }
    $expectedHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    if ((Digest-Hash $archive) -ne $expectedHash -or $expectedHash.Length -ne 64) {
        throw 'Digest-Hash did not return SHA-256 for a literal path.'
    }
    $cases++

    $extraction = Join-Path $testRoot 'extracted [literal] $(throw INJECTION)'
    Extract-Archive $archive $extraction
    if ((Get-Content -LiteralPath (Join-Path $extraction 'kept.txt') -Raw).Trim() -ne 'expected payload') {
        throw 'Literal-path archive extraction lost the payload.'
    }
    if (Test-Path -LiteralPath $archive) { throw 'Successful extraction did not remove its input archive.' }
    $cases++

    $corrupt = Join-Path $testRoot 'corrupt [literal].zip'
    Set-Content -LiteralPath $corrupt -Value 'not an archive' -Encoding ascii
    $failed = $false
    try { Extract-Archive $corrupt (Join-Path $testRoot 'bad-extraction') 2>$null } catch { $failed = $true }
    if (-not $failed -or -not (Test-Path -LiteralPath $corrupt)) {
        throw 'Failed extraction must report failure and preserve the input archive.'
    }
    $cases++

    $failed = $false
    try { Create-Archive $source (Join-Path $testRoot 'bad.zip') @('-tinvalid-format') 2>$null } catch { $failed = $true }
    if (-not $failed -or $PWD.Path -ne $originalLocation) {
        throw 'Failed compression must report failure and restore the working directory.'
    }
    $cases++

    foreach ($name in @('clink', 'git-for-windows', 'vendor_1.2-rc', 'x')) {
        Assert-CmderVendorName $name
        $cases++
    }
    foreach ($name in @('', '.', '..', '..\outside', '../outside', 'C:\outside', '\\server\share',
        ('clink' + [char]10), 'vendor*', 'vendor?', 'name.', 'space name', '$(throw INJECTION)', 'CON', 'aux.txt', 'LPT1', 'com9.zip')) {
        $failed = $false
        try { Assert-CmderVendorName $name } catch { $failed = $true }
        if (-not $failed) { throw "Unsafe vendor name was accepted: $name" }
        $cases++
    }

    $vendorRoot = Join-Path $testRoot 'vendors'
    $null = New-Item -ItemType Directory -Path $vendorRoot
    $sentinel = Join-Path $vendorRoot 'preserve.txt'
    Set-Content -LiteralPath $sentinel -Value 'preserve' -Encoding ascii
    $manifest = Join-Path $testRoot 'invalid-sources.json'
    '[{"name":"..\\outside","version":"1","url":"https://example.invalid/not-downloaded"}]' |
        Set-Content -LiteralPath $manifest -Encoding ascii
    $failed = $false
    try {
        & (Join-Path $PSScriptRoot 'build.ps1') -SourcesPath $manifest -SaveTo $vendorRoot
    } catch {
        if ($_.Exception.Message -notlike 'Invalid vendor name*') { throw }
        $failed = $true
    }
    if (-not $failed -or (Test-Path -LiteralPath (Join-Path $vendorRoot 'tmp')) -or
        (Get-Content -LiteralPath $sentinel -Raw).Trim() -ne 'preserve') {
        throw 'Invalid manifest must fail before any vendor-directory mutation.'
    }
    $cases++

    $packageSource = Join-Path $testRoot 'package source'
    $packageVendor = Join-Path $packageSource 'vendor'
    $profileDir = Join-Path $packageVendor 'git-for-windows\etc\profile.d'
    $null = New-Item -ItemType Directory -Path $profileDir
    $legacyBundledHook = Join-Path $profileDir 'cmder.sh'
    [IO.File]::WriteAllText($legacyBundledHook, 'legacy bundled hook')
    $repo = Split-Path $PSScriptRoot -Parent
    $startupFiles = @('cmder.sh', 'cmder_exinit', 'lib\lib_console.sh', 'setup_external_git_bash.ps1')
    foreach ($file in $startupFiles) {
        $destination = Join-Path $packageVendor $file
        $null = New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force
        Copy-Item -LiteralPath (Join-Path $repo "vendor\$file") -Destination $destination
    }
    $packageConfig = Join-Path $packageSource 'config'
    $null = New-Item -ItemType Directory -Path $packageConfig -Force
    [IO.File]::WriteAllText((Join-Path $packageConfig 'user_cmder_state.txt'), 'private Git path')
    Copy-Item -LiteralPath (Join-Path $repo 'packignore') -Destination $packageSource
    $emptyManifest = Join-Path $testRoot 'empty-sources.json'
    Set-Content -LiteralPath $emptyManifest -Value '[]' -Encoding ascii
    Set-Content -LiteralPath (Join-Path $profileDir 'git-prompt.sh.bak') -Value '' -Encoding ascii
    & (Join-Path $PSScriptRoot 'build.ps1') -SourcesPath $emptyManifest -SaveTo $packageVendor -Config $packageSource
    $hook = Get-Content -Raw -LiteralPath (Join-Path $profileDir 'zz-cmder.sh')
    if (!$hook.Contains('. "$CMDER_ROOT/vendor/cmder.sh"') -or $hook.Contains('__cmder_find_git_root')) {
        throw 'Bundled profile hook must source the shared startup rather than copy it.'
    }
    if ([IO.File]::ReadAllText($legacyBundledHook) -ne 'legacy bundled hook') {
        throw 'Package building must not rewrite the legacy bundled hook.'
    }
    $packageOutput = Join-Path $testRoot 'archives'
    & (Join-Path $PSScriptRoot 'pack.ps1') -CmderRoot $packageSource -SaveTo $packageOutput
    foreach ($profile in Get-CmderPackageProfiles) {
        foreach ($package in $profile.packages) {
            $archive = Join-Path $packageOutput "$($profile.outputFolder)\$($package.name)"
            $listing = & 7z l -slt -ba $archive
            if ($LASTEXITCODE) { throw "Cannot list $archive." }
            if ($listing -contains 'Path = config\user_cmder_state.txt') {
                throw "$($package.name) contains user-owned Cmder state."
            }
            foreach ($file in $startupFiles) {
                if ($listing -notcontains "Path = vendor\$file") {
                    throw "$($package.name) is missing vendor\$file."
                }
            }
            $hasBundledHook = $listing -contains 'Path = vendor\git-for-windows\etc\profile.d\zz-cmder.sh'
            if ($hasBundledHook -ne ($package.name -notlike '*_nogit.zip')) {
                throw "$($package.name) has incorrect bundled hook inclusion."
            }
            $cases++
        }
    }

    Push-Location -LiteralPath $testRoot
    try {
        $version = Get-VersionStr
        if ($version -notmatch '^\d+\.\d+' -or $ErrorActionPreference -ne 'Stop') {
            throw 'Version fallback outside a Git repository failed or changed error handling.'
        }
        $null = & git.exe init --quiet
        if ($LASTEXITCODE -ne 0) { throw 'Unable to prepare the untagged Git fixture.' }
        $version = Get-VersionStr
        if ($version -notmatch '^\d+\.\d+' -or $ErrorActionPreference -ne 'Stop') {
            throw 'Version fallback in an untagged Git repository failed or changed error handling.'
        }

        # An archival tag on a newer commit must not replace the release version.
        # Keep identity and hooks local to these commands; never change user config.
        $emptyHooks = Join-Path $testRoot 'empty-hooks'
        $null = New-Item -ItemType Directory -Path $emptyHooks
        $fixtureConfig = @('-c', 'user.name=Cmder Test Fixture', '-c', 'user.email=fixture@example.invalid',
            '-c', "core.hooksPath=$emptyHooks", '-c', 'tag.gpgSign=false')
        $null = & git.exe @fixtureConfig commit --allow-empty --no-gpg-sign --quiet -m 'Release fixture'
        if ($LASTEXITCODE -ne 0) { throw 'Unable to create the release-version fixture.' }
        $null = & git.exe @fixtureConfig tag v9.8.7
        if ($LASTEXITCODE -ne 0) { throw 'Unable to tag the release-version fixture.' }
        $null = & git.exe @fixtureConfig commit --allow-empty --no-gpg-sign --quiet -m 'Archival fixture'
        if ($LASTEXITCODE -ne 0) { throw 'Unable to create the archival-version fixture.' }
        $null = & git.exe @fixtureConfig tag archive-fixture
        if ($LASTEXITCODE -ne 0) { throw 'Unable to tag the archival-version fixture.' }
        $version = Get-VersionStr
        if ($version -notmatch '^9\.8\.7(?:\.|\z)' -or $ErrorActionPreference -ne 'Stop') {
            throw "A closer archival tag replaced the earlier release version: $version"
        }
        $cases++
    } finally {
        Pop-Location
    }
    $cases += 2
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        $resolved = (Resolve-Path -LiteralPath $testRoot).Path
        $item = Get-Item -LiteralPath $resolved
        if (-not $resolved.StartsWith($testParent, [System.StringComparison]::OrdinalIgnoreCase) -or
            $item.Name -notmatch '^cmder-build-helpers-[0-9a-f]{32}$' -or
            ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            throw "Refusing to remove an unexpected test directory: $resolved"
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}

Write-Output "Build helper regression tests passed ($cases cases)."
# Expected native failures above must not become the Actions shell's exit code.
exit 0

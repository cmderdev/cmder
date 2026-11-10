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
        'vendor*', 'vendor?', 'name.', 'space name', '$(throw INJECTION)', 'CON', 'aux.txt', 'LPT1', 'com9.zip')) {
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

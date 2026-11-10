[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$fixture = Join-Path $tempRoot ('cmder-legacy-pack-' + [guid]::NewGuid().ToString('N'))
$packScript = Join-Path $PSScriptRoot 'pack.ps1'
$expected = @('cmder.7z', 'cmder.zip', 'cmder_mini.zip')

try {
    $null = New-Item -ItemType Directory -Path $fixture
    foreach ($name in @('conemu-maximus5', 'git-for-windows', 'windows-terminal')) {
        $directory = Join-Path $fixture "vendor\$name"
        $null = New-Item -ItemType Directory -Path $directory -Force
        Set-Content -LiteralPath (Join-Path $directory 'marker.txt') -Value $name
    }
    Set-Content -LiteralPath (Join-Path $fixture 'vendor\init.bat') -Value '@rem Legacy initialization'
    Set-Content -LiteralPath (Join-Path $fixture 'Cmder.exe') -Value 'Launcher fixture'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot '..\packignore') -Destination $fixture

    # Supply local version metadata without relying on the caller's repository.
    git -C $fixture init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Cannot initialize fixture version metadata.' }
    git -C $fixture -c user.name=Fixture -c user.email=fixture@example.invalid commit --allow-empty --quiet -m Fixture
    if ($LASTEXITCODE -ne 0) { throw 'Cannot create fixture version metadata.' }
    git -C $fixture tag v1.3.26-fixture
    if ($LASTEXITCODE -ne 0) { throw 'Cannot tag fixture version metadata.' }

    # The real packer operates only on this disposable fixture, never the checkout.
    & $packScript -cmderRoot $fixture -saveTo (Join-Path $fixture 'build')
    $actual = @(Get-ChildItem -LiteralPath (Join-Path $fixture 'build') -File | Sort-Object Name)
    if (($actual.Name -join ',') -ne (($expected + 'hashes.txt' | Sort-Object) -join ',')) {
        throw "Unexpected legacy asset names: $($actual.Name -join ', ')"
    }

    foreach ($name in $expected) {
        $archive = Join-Path $fixture "build\$name"
        & 7z t $archive | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Invalid archive: $name" }
        $listing = (& 7z l -slt $archive) -join "`n"
        if ($LASTEXITCODE -ne 0) { throw "Cannot list archive: $name" }
        if ($listing -match '(?m)^Path = vendor[\\/]windows-terminal(?:[\\/]|\r?$)') {
            throw "Legacy archive includes Windows Terminal: $name"
        }
        foreach ($required in @('Cmder.exe', 'vendor[\\/]init.bat', 'vendor[\\/]conemu-maximus5[\\/]marker.txt')) {
            if ($listing -notmatch "(?m)^Path = $required`r?$" ) {
                throw "Missing $required in $name"
            }
        }
        $hasGit = $listing -match 'Path = vendor[\\/]git-for-windows[\\/]marker.txt'
        if ($hasGit -eq ($name -eq 'cmder_mini.zip')) {
            throw "Wrong Git contents in $name"
        }
        $hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
        if ((Get-Content -LiteralPath (Join-Path $fixture 'build\hashes.txt')) -notcontains "$name`t$hash") {
            throw "Missing or incorrect SHA256 for $name"
        }
        Write-Host "Passed: $name contents, integrity, and SHA256"
    }
}
finally {
    $resolvedFixture = [IO.Path]::GetFullPath($fixture)
    if (-not $resolvedFixture.StartsWith((Join-Path $tempRoot 'cmder-legacy-pack-'), [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Refusing to remove a fixture outside the expected temporary path.'
    }
    if (Test-Path -LiteralPath $resolvedFixture) {
        Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
    }
}

<# Build the opt-in Windows 11 Explorer command and its identity-only package. #>
[CmdletBinding()]
param(
    [string]$CmderRoot = (Join-Path $PSScriptRoot '..'),
    [ValidatePattern('^\d+\.\d+\.\d+\.\d+$')][string]$Version = '2.0.0.0',
    [string]$CertificateThumbprint,
    [string]$Publisher = 'CN=Cmder Contributors',
    [string]$TimestampServer,
    [switch]$SkipCompile
)
$ErrorActionPreference = 'Stop'
foreach ($component in $Version.Split('.')) {
    if ([long]$component -gt [uint16]::MaxValue) { throw 'Each package version component must be between 0 and 65535.' }
}
$CmderRoot = (Resolve-Path -LiteralPath $CmderRoot).Path
. (Join-Path $PSScriptRoot 'utils.ps1')

function Find-WindowsSdkTool([string]$Name) {
    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }
    $sdk = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots' -Name KitsRoot10).KitsRoot10
    foreach ($directory in (Get-ChildItem -LiteralPath (Join-Path $sdk 'bin') -Directory |
            Where-Object { $_.Name -match '^10\.\d+\.\d+\.\d+$' } |
            Sort-Object { [version]$_.Name } -Descending)) {
        $candidate = Join-Path $directory.FullName ('x64\' + $Name)
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    throw "Windows SDK tool '$Name' is required. Install the Windows 11 SDK."
}

$source = Join-Path $CmderRoot 'launcher\shell'
$output = Join-Path $CmderRoot 'bin\cmder-shell'
$stage = Join-Path $source ('obj\package-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $output, (Join-Path $stage 'Assets') | Out-Null
if (-not $SkipCompile) {
    Ensure-Executable 'msbuild'
    & msbuild (Join-Path $source 'CmderExplorerCommand.vcxproj') /t:Build /p:Configuration=Release /p:Platform=x64 /verbosity:minimal
    if ($LASTEXITCODE -ne 0) { throw 'MSBuild failed to build the Explorer command.' }
}
$dll = Join-Path $source 'bin\x64\Release\CmderExplorerCommand.dll'
if (-not (Test-Path -LiteralPath $dll -PathType Leaf)) { throw "Missing Explorer command: $dll" }
Copy-Item -LiteralPath $dll -Destination $output
Copy-Item -LiteralPath (Join-Path $source 'Register-CmderContextMenu.ps1') -Destination $output

if ($CertificateThumbprint) {
    $certificate = Get-Item -LiteralPath ('Cert:\CurrentUser\My\' + $CertificateThumbprint)
    if (-not $certificate.HasPrivateKey) { throw 'The signing certificate has no private key.' }
    $Publisher = $certificate.Subject
}
$manifest = [IO.File]::ReadAllText((Join-Path $source 'AppxManifest.xml.in'))
$manifest = $manifest.Replace('@PUBLISHER@', [Security.SecurityElement]::Escape($Publisher)).Replace('@VERSION@', $Version)
[IO.File]::WriteAllText((Join-Path $stage 'AppxManifest.xml'), $manifest, (New-Object Text.UTF8Encoding($false)))
$identityInfo = @{ Name = 'Cmder.ContextMenu'; Publisher = $Publisher }
$identityInfo | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'Identity.json') -Encoding UTF8
# Derive package logos from Cmder's existing icon; no new branding or image dependency.
Add-Type -AssemblyName System.Drawing
$image = [Drawing.Image]::FromFile((Join-Path $CmderRoot 'icons\icon_256.png'))
try {
    foreach ($logo in @(@('StoreLogo.png', 50), @('Square44x44Logo.png', 44), @('Square150x150Logo.png', 150))) {
        $bitmap = New-Object Drawing.Bitmap([int]$logo[1], [int]$logo[1])
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.DrawImage($image, 0, 0, $bitmap.Width, $bitmap.Height)
            $bitmap.Save((Join-Path $stage ('Assets\' + $logo[0])), [Drawing.Imaging.ImageFormat]::Png)
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
    }
} finally { $image.Dispose() }
# A loose manifest is only used by the explicit -Development registration mode.
$development = Join-Path $output 'development'
New-Item -ItemType Directory -Force -Path $development | Out-Null
Copy-Item -LiteralPath (Join-Path $stage 'AppxManifest.xml') -Destination $development
Copy-Item -LiteralPath (Join-Path $stage 'Assets') -Destination $development -Recurse -Force
$package = Join-Path $output 'CmderContextMenu.msix'
$makeAppx = Find-WindowsSdkTool 'makeappx.exe'
# /nv is required for sparse packages: binaries deliberately live outside the MSIX.
# XML/schema and referenced identity/assets are checked separately by test-shell-integration.ps1.
& $makeAppx pack /d $stage /p $package /o /nv
if ($LASTEXITCODE -ne 0) { throw 'MakeAppx failed to create the shell identity package.' }
if ($CertificateThumbprint) {
    $signTool = Find-WindowsSdkTool 'signtool.exe'
    $signArgs = @('sign', '/fd', 'SHA256', '/sha1', $CertificateThumbprint)
    if ($TimestampServer) { $signArgs += @('/tr', $TimestampServer, '/td', 'SHA256') }
    & $signTool @signArgs $package
    if ($LASTEXITCODE -ne 0) { throw 'Signing the Explorer identity package failed.' }
} else {
    Write-Warning 'The identity package is unsigned. Use Developer Mode for local testing; sign it with a trusted certificate before end-user distribution. No trust or registration settings were changed.'
}
Write-Verbose "Explorer command and identity package: $output"

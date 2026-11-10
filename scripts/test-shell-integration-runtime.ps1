<# Optional interactive Windows 11 development-package test. Never run by CI. #>
[CmdletBinding()]
param(
    [string]$SourceRoot,
    [string]$ReceiptPath
)
$ErrorActionPreference = 'Stop'
if (-not $SourceRoot) { $SourceRoot = Join-Path $PSScriptRoot '..' }
if ($PSVersionTable.PSVersion.Major -ne 5 -or -not [Environment]::Is64BitProcess) {
    throw 'Run this test in native Windows PowerShell 5.1 on x64 Windows 11.'
}
if ([int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber -lt 22621 -or
    [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() -ne 'X64') {
    throw 'This test requires x64 Windows 11 22H2 or later and an interactive Explorer desktop.'
}
$source = (Resolve-Path -LiteralPath $SourceRoot).ProviderPath
$payload = Join-Path $source 'bin\cmder-shell'
$test = Join-Path $source 'launcher\shell\tests\bin\x64\Release\ExplorerCommandTests.exe'
foreach ($file in @($test, (Join-Path $payload 'CmderExplorerCommand.dll'), (Join-Path $payload 'Identity.json'),
        (Join-Path $payload 'development\AppxManifest.xml'), (Join-Path $payload 'Register-CmderContextMenu.ps1'),
        (Join-Path $source 'icons\cmder.ico'))) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Build the integration and Release/x64 tests first. Missing: $file" }
}
$identity = 'Cmder.ContextMenu'
$settings = 'HKCU:\Software\Cmder\ContextMenu'
if (@(Get-AppxPackage -Name $identity).Count -or (Test-Path -LiteralPath $settings)) {
    throw 'An existing Cmder menu or registration settings were found. This test will not replace them.'
}
$developer = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue
if (-not $developer -or $developer.AllowDevelopmentWithoutDevLicense -ne 1) {
    throw 'Developer Mode must already be enabled. This test does not change trust or developer settings.'
}
$metadata = Get-Content -LiteralPath (Join-Path $payload 'Identity.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$paths = & {
    . (Join-Path $source 'launcher\shell\Register-CmderContextMenu.ps1') -Action Register
    $family = Get-CmderContextMenuPackageFamilyName $identity $metadata.Publisher
    Get-CmderContextMenuPreferencePath $family
}
$preferencePath = [string]$paths
$packageData = [IO.Path]::GetDirectoryName([IO.Path]::GetDirectoryName($preferencePath))
if (Test-Path -LiteralPath $packageData) {
    throw 'Existing Cmder package data was found. This test will not risk removing it during fixture unregistration.'
}
$parent = Join-Path ([IO.Path]::GetTempPath()) ('cmder-shell-runtime-' + [guid]::NewGuid().ToString('N'))
$root = Join-Path $parent ('Cmder fixture & ' + [char]0x03A9)
$selected = Join-Path $parent ('Selected & ' + [char]0x03A9)
$configs = @((Join-Path $parent ('Config one & ' + [char]0x03A9)), (Join-Path $parent ('Config two & ' + [char]0x03A9)))
New-Item -ItemType Directory -Path (@($root, $selected, (Join-Path $root 'bin'), (Join-Path $root 'icons'),
    (Join-Path $root 'vendor\conemu-maximus5')) + $configs) -Force | Out-Null
Copy-Item -LiteralPath $payload -Destination (Join-Path $root 'bin') -Recurse
Copy-Item -LiteralPath (Join-Path $source 'icons\cmder.ico') -Destination (Join-Path $root 'icons')
$captureSource = @'
using System;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;
using System.Diagnostics;
class CmderCapture {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode)] static extern int GetCurrentPackageFullName(ref uint length, StringBuilder name);
    static string Identity() {
        uint length = 512; var name = new StringBuilder(512);
        return GetCurrentPackageFullName(ref length, name).ToString() + "\n" + name.ToString();
    }
    [STAThread] static void Main(string[] args) {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        try {
            if (args.Length == 1 && args[0] == "--probe") {
                File.WriteAllText(Path.Combine(root, "terminal.package"), Identity());
                return;
            }
            string[] encoded = new string[args.Length + 1];
            encoded[0] = Convert.ToBase64String(Encoding.UTF8.GetBytes(Environment.CurrentDirectory));
            for (int i = 0; i < args.Length; ++i) encoded[i+1] = Convert.ToBase64String(Encoding.UTF8.GetBytes(args[i]));
            File.WriteAllText(Path.Combine(root, "launcher.package"), Identity());
            var info = new ProcessStartInfo(Path.Combine(root, "TerminalProbe.exe"), "--probe");
            info.UseShellExecute = false; info.CreateNoWindow = true;
            using (var child = Process.Start(info)) {
                if (!child.WaitForExit(5000) || child.ExitCode != 0) throw new Exception("Terminal probe failed.");
            }
            File.WriteAllLines(Path.Combine(root, "invoked.args.tmp"), encoded, new UTF8Encoding(false));
            File.Move(Path.Combine(root, "invoked.args.tmp"), Path.Combine(root, "invoked.args"));
        } catch (Exception error) {
            File.WriteAllText(Path.Combine(root, "capture.error"), error.ToString());
            Environment.Exit(1);
        }
    }
}
'@
Add-Type -TypeDefinition $captureSource -OutputAssembly (Join-Path $root 'Cmder.exe') -OutputType WindowsApplication
Copy-Item -LiteralPath (Join-Path $root 'Cmder.exe') -Destination (Join-Path $root 'TerminalProbe.exe')
$helper = Join-Path $root 'bin\cmder-shell\Register-CmderContextMenu.ps1'
$nativePowerShell = Join-Path ([Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)) 'System32\WindowsPowerShell\v1.0\powershell.exe'
$registered = $false
$runs = @()
try {
    for ($pass = 0; $pass -lt 2; $pass++) {
        $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $helper,
            '-Action', 'Register', '-Development', '-ConfigRoot', $configs[$pass])
        if ($pass -eq 0) { $arguments += '-SingleInstance' }
        & $nativePowerShell @arguments
        if ($LASTEXITCODE -ne 0) { throw 'Development registration failed.' }
        $registered = $true
        foreach ($name in @('invoked.args', 'invoked.args.tmp', 'launcher.package', 'terminal.package', 'capture.error')) {
            [IO.File]::Delete((Join-Path $root $name))
        }
        & $test --registered $root $selected
        if ($LASTEXITCODE -ne 0) { throw 'Packaged COM activation/invocation failed.' }
        $capture = Join-Path $root 'invoked.args'
        for ($i = 0; $i -lt 100 -and -not [IO.File]::Exists($capture); $i++) {
            if ([IO.File]::Exists((Join-Path $root 'capture.error'))) { throw [IO.File]::ReadAllText((Join-Path $root 'capture.error')) }
            Start-Sleep -Milliseconds 100
        }
        if (-not [IO.File]::Exists($capture)) { throw 'The isolated launcher did not record an invocation.' }
        $values = @([IO.File]::ReadAllLines($capture) | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) })
        foreach ($name in @('launcher.package', 'terminal.package')) {
            if ([IO.File]::ReadAllLines((Join-Path $root $name))[0] -ne '15700') { throw "Inherited package identity in $name." }
        }
        $expected = @($selected, '/start', $selected, '/c', $configs[$pass])
        if ($pass -eq 0) { $expected += '/single' }
        if ($values.Count -ne $expected.Count) { throw 'Unexpected child argv length.' }
        for ($i = 0; $i -lt $expected.Count; $i++) {
            if ($values[$i] -cne $expected[$i]) { throw "Child argv/CWD mismatch at index $i." }
        }
        $runs += [ordered]@{ ConfigRoot = $configs[$pass]; SingleInstance = ($pass -eq 0); WorkingDirectory = $values[0]; Arguments = @($values | Select-Object -Skip 1); LauncherHasPackageIdentity = $false; TerminalHasPackageIdentity = $false }
    }
} finally {
    if ($registered -or @(Get-AppxPackage -Name $identity).Count) {
        & $nativePowerShell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $helper -Action Unregister
        if ($LASTEXITCODE -ne 0) { throw 'Fixture package cleanup failed.' }
    }
    if (@(Get-AppxPackage -Name $identity).Count -or [IO.File]::Exists($preferencePath)) { throw 'Fixture package or menu preferences remain.' }
    if (Test-Path -LiteralPath $settings) {
        $key = Get-Item -LiteralPath $settings
        if ($key.ValueCount -ne 0 -or $key.SubKeyCount -ne 0) { throw 'Unexpected settings remain; preserving them for inspection.' }
        Remove-Item -LiteralPath $settings
    }
    Write-Output "Fixture package and preferences removed. Diagnostic files retained at $parent"
}
$receipt = [ordered]@{ Result = 'PASS'; Runs = $runs; CleanupVerified = $true; FixtureRoot = $root;
    DllSha256 = (Get-FileHash -LiteralPath (Join-Path $payload 'CmderExplorerCommand.dll') -Algorithm SHA256).Hash;
    Mode = 'Temporary development package with pre-existing Developer Mode';
    Limit = 'No Explorer visual acceptance or trusted production signature is claimed.' }
$json = $receipt | ConvertTo-Json -Depth 8
if ($ReceiptPath) {
    $receiptFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ReceiptPath)
    [IO.File]::WriteAllText($receiptFile, $json, (New-Object Text.UTF8Encoding($false)))
}
Write-Output $json

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][ValidateSet('Register', 'Unregister')][string]$Action,
    [string]$ConfigRoot,
    [switch]$SingleInstance,
    # Explicit local-development mode; never enabled or selected automatically.
    [switch]$Development
)
$ErrorActionPreference = 'Stop'
$identity = 'Cmder.ContextMenu'
$settings = 'HKCU:\Software\Cmder\ContextMenu'

function Get-CmderContextMenuOSArchitecture {
    return [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
}

function Get-CmderContextMenuPreferencePath([string]$Family) {
    Initialize-CmderContextMenuPackageIdentity
    $localData = [CmderContextMenu.PackageIdentity]::GetLocalAppData()
    if (-not $localData) { throw 'The current-user local application data directory is unavailable.' }
    return Join-Path $localData ('Packages\' + $Family + '\LocalState\CmderContextMenu.ini')
}

function Initialize-CmderContextMenuPackageIdentity {
    # Derive identity without installing a package or trusting a certificate.
    if (-not ('CmderContextMenu.PackageIdentity' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
namespace CmderContextMenu {
    public static class PackageIdentity {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct PackageId {
            public uint Reserved;
            public uint ProcessorArchitecture;
            public ulong Version;
            [MarshalAs(UnmanagedType.LPWStr)] public string Name;
            [MarshalAs(UnmanagedType.LPWStr)] public string Publisher;
            [MarshalAs(UnmanagedType.LPWStr)] public string ResourceId;
            [MarshalAs(UnmanagedType.LPWStr)] public string PublisherId;
        }
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, ExactSpelling = true)]
        private static extern int PackageFamilyNameFromId(ref PackageId packageId,
            ref uint length, StringBuilder familyName);
        [DllImport("shell32.dll", ExactSpelling = true)]
        private static extern int SHGetKnownFolderPath(ref Guid folder, uint flags,
            IntPtr token, out IntPtr path);
        public static string GetLocalAppData() {
            var folder = new Guid("F1B32785-6FBA-4FCF-9D55-7B8E7F157091");
            IntPtr path = IntPtr.Zero;
            try {
                // Match native COM: no package redirection, and do not create folders.
                int error = SHGetKnownFolderPath(ref folder, 0x00014000, IntPtr.Zero, out path);
                Marshal.ThrowExceptionForHR(error);
                return Marshal.PtrToStringUni(path);
            } finally { if (path != IntPtr.Zero) Marshal.FreeCoTaskMem(path); }
        }
        public static string GetFamilyName(string name, string publisher) {
            var id = new PackageId { Name = name, Publisher = publisher,
                ProcessorArchitecture = 9, ResourceId = String.Empty };
            uint length = 0;
            int error = PackageFamilyNameFromId(ref id, ref length, null);
            if (error != 122) throw new Win32Exception(error);
            if (length == 0 || length > 1024) throw new InvalidOperationException("Invalid package family length.");
            var family = new StringBuilder((int)length);
            error = PackageFamilyNameFromId(ref id, ref length, family);
            if (error != 0) throw new Win32Exception(error);
            return family.ToString();
        }
    }
}
'@
    }
}

function Get-CmderContextMenuPackageFamilyName([string]$Name, [string]$Publisher) {
    Initialize-CmderContextMenuPackageIdentity
    return [CmderContextMenu.PackageIdentity]::GetFamilyName($Name, $Publisher)
}

function Read-CmderContextMenuManifest([string]$Path, [switch]$Archive) {
    if ($Archive) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead($Path)
        try {
            $entry = $zip.GetEntry('AppxManifest.xml')
            if (-not $entry) { throw 'The identity package has no manifest.' }
            $reader = New-Object IO.StreamReader($entry.Open())
            try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
        } finally { $zip.Dispose() }
    } else { $text = [IO.File]::ReadAllText($Path) }
    $document = New-Object Xml.XmlDocument
    $document.XmlResolver = $null
    $document.LoadXml($text)
    return $document
}

function Invoke-CmderContextMenuRegistration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    if ([int]$os.CurrentBuildNumber -lt 22621) { throw 'The modern menu requires Windows 11 22H2 or later.' }
    if ((Get-CmderContextMenuOSArchitecture) -ne 'X64') {
        throw 'This Explorer command package requires x64 Windows. Use /REGISTER USER for the classic menu.'
    }
    $root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
    $package = Join-Path $PSScriptRoot 'CmderContextMenu.msix'
    $manifest = Join-Path $PSScriptRoot 'development\AppxManifest.xml'
    $identityFile = Join-Path $PSScriptRoot 'Identity.json'
    if (-not (Test-Path -LiteralPath $identityFile -PathType Leaf)) { throw 'The context-menu Identity.json is missing. Rebuild or extract the complete shell integration.' }
    $expected = Get-Content -LiteralPath $identityFile -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($expected.Name -ne $identity -or [string]::IsNullOrWhiteSpace($expected.Publisher)) { throw 'Invalid Cmder context-menu identity metadata.' }
    $expectedFamily = Get-CmderContextMenuPackageFamilyName $identity $expected.Publisher
    $preferencePath = Get-CmderContextMenuPreferencePath $expectedFamily
    $packages = @(Get-AppxPackage -Name $identity)
    $registered = @($packages | Where-Object { $_.Name -eq $identity -and $_.Publisher -eq $expected.Publisher })
    $previous = Get-ItemProperty -LiteralPath $settings -ErrorAction SilentlyContinue
    $ownsPreferences = $previous -and $previous.PackageFamilyName -eq $expectedFamily
    if ($Action -eq 'Unregister') {
        if (-not $PSCmdlet.ShouldProcess($identity, 'Remove current-user Explorer menu registration')) { return }
        foreach ($entry in $registered) { Remove-AppxPackage -Package $entry.PackageFullName -ErrorAction Stop }
        # Windows manages this package's app data during removal. Explicit cleanup
        # here covers only our constant preference file, including orphan cleanup.
        if ([IO.File]::Exists($preferencePath)) { [IO.File]::Delete($preferencePath) }
        if ($ownsPreferences) {
            foreach ($name in @('ConfigRoot', 'SingleInstance', 'InstallRoot', 'PackageFamilyName')) {
                if (Test-Path -LiteralPath $settings) {
                    Remove-ItemProperty -LiteralPath $settings -Name $name -ErrorAction SilentlyContinue
                }
            }
        }
        return
    }
    if (@($packages | Where-Object { $_.Name -eq $identity -and $_.Publisher -ne $expected.Publisher }).Count -or
        ($previous -and $previous.PackageFamilyName -and -not $ownsPreferences)) {
        throw 'Another Cmder publisher owns the modern menu or its active preferences. Unregister it from that installation before registering this build. No registration was changed.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $root 'Cmder.exe') -PathType Leaf) -or
        -not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'CmderExplorerCommand.dll') -PathType Leaf)) {
        throw 'Keep bin\cmder-shell beside this Cmder installation before registering.'
    }
    if ($ConfigRoot) {
        $resolvedConfig = Resolve-Path -LiteralPath $ConfigRoot
        if ($resolvedConfig.Provider.Name -ne 'FileSystem' -or
            -not (Test-Path -LiteralPath $resolvedConfig.ProviderPath -PathType Container)) {
            throw 'The Cmder configuration path must be an existing filesystem directory. No registration was changed.'
        }
        $ConfigRoot = $resolvedConfig.ProviderPath
    }
    if ($SingleInstance -and (
            -not (Test-Path -LiteralPath (Join-Path $root 'vendor\conemu-maximus5') -PathType Container) -or
            (Test-Path -LiteralPath (Join-Path $root 'vendor\windows-terminal') -PathType Container))) {
        throw 'Single-instance registration requires the ConEmu package without Windows Terminal, matching the Cmder launcher /single option.'
    }
    if ($registered.Count -and (-not $previous -or $previous.InstallRoot -ne $root)) {
        throw 'Another Cmder installation is registered. Run /UNREGISTER MODERN before registering this location.'
    }
    if ($Development) {
        $developerMode = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue
        if (-not $developerMode -or $developerMode.AllowDevelopmentWithoutDevLicense -ne 1) {
            throw 'Developer Mode is required for -Development registration. Enable it yourself only on a development machine, or use a trusted-signed package.'
        }
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw 'The development manifest is missing. Rebuild the shell integration.' }
        $document = Read-CmderContextMenuManifest $manifest
    } else {
        if (-not (Test-Path -LiteralPath $package -PathType Leaf)) { throw 'The Cmder context-menu identity package is missing.' }
        $document = Read-CmderContextMenuManifest $package -Archive
        $signature = Get-AuthenticodeSignature -LiteralPath $package
        if ($signature.Status -ne 'Valid') {
            throw 'The context-menu identity package must have a trusted signature. See docs/WINDOWS-11-CONTEXT-MENU.md for signing or explicit Developer Mode testing. No certificate trust or developer settings were changed.'
        }
    }
    if ($document.Package.Identity.Name -ne $identity -or $document.Package.Identity.Publisher -ne $expected.Publisher) {
        throw 'The package identity does not match this Cmder build. No registration was changed.'
    }
    $manifestVersion = [version]$document.Package.Identity.Version
    $preferenceOnlyUpdate = $previous -and $previous.InstallRoot -eq $root -and
        @($registered | Where-Object { $_.Version -and [version]$_.Version -eq $manifestVersion }).Count -gt 0
    if (-not $PSCmdlet.ShouldProcess($root, 'Register the current-user Windows 11 Cmder menu')) { return }
    $hadPreferenceFile = [IO.File]::Exists($preferencePath)
    [byte[]]$previousPreferenceBytes = @()
    if ($hadPreferenceFile) { $previousPreferenceBytes = [IO.File]::ReadAllBytes($preferencePath) }
    # Updating preferences must not redeploy the same package while Explorer uses it.
    # Identity, install-root, manifest and trust/development checks still run first.
    if (-not $preferenceOnlyUpdate) {
        if ($Development) {
            Add-AppxPackage -Register $manifest -ExternalLocation $root -ErrorAction Stop
        } else {
            Add-AppxPackage -Path $package -ExternalLocation $root -ErrorAction Stop
        }
    }
    try {
        $entry = Get-AppxPackage -Name $identity | Where-Object { $_.Name -eq $identity -and $_.Publisher -eq $expected.Publisher } | Select-Object -First 1
        if (-not $entry) { throw 'The identity package did not register.' }
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($preferencePath))
        $preferenceText = "[Cmder]`r`nConfigRoot=$ConfigRoot`r`nSingleInstance=$([int][bool]$SingleInstance)`r`n"
        [IO.File]::WriteAllText($preferencePath, $preferenceText, [Text.Encoding]::Unicode)
        New-Item -Path $settings -Force | Out-Null
        New-ItemProperty -LiteralPath $settings -Name 'ConfigRoot' -Value ([string]$ConfigRoot) -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $settings -Name 'SingleInstance' -Value ([int][bool]$SingleInstance) -PropertyType DWord -Force | Out-Null
        New-ItemProperty -LiteralPath $settings -Name 'InstallRoot' -Value $root -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $settings -Name 'PackageFamilyName' -Value $entry.PackageFamilyName -PropertyType String -Force | Out-Null
    } catch {
        $registrationFailure = $_
        # Restore only our four values; leave other settings and user profiles alone.
        foreach ($name in @('ConfigRoot', 'SingleInstance', 'InstallRoot', 'PackageFamilyName')) {
            if ($previous -and $previous.PSObject.Properties[$name]) {
                $kind = if ($name -eq 'SingleInstance') { 'DWord' } else { 'String' }
                New-ItemProperty -LiteralPath $settings -Name $name -Value $previous.$name -PropertyType $kind -Force -ErrorAction Continue | Out-Null
            } else {
                Remove-ItemProperty -LiteralPath $settings -Name $name -ErrorAction SilentlyContinue
            }
        }
        # Undo only a newly added package of our exact publisher identity.
        if (-not $registered.Count) {
            Get-AppxPackage -Name $identity | Where-Object { $_.Name -eq $identity -and $_.Publisher -eq $expected.Publisher } |
                ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -ErrorAction Continue }
        }
        # Restore after package rollback, which may remove the package's data directory.
        try {
            if ($hadPreferenceFile) {
                $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($preferencePath))
                [IO.File]::WriteAllBytes($preferencePath, [byte[]]$previousPreferenceBytes)
            } elseif ([IO.File]::Exists($preferencePath)) {
                [IO.File]::Delete($preferencePath)
            }
        } catch { Write-Warning ('Could not restore the previous Cmder menu preference file: ' + $_.Exception.Message) }
        throw $registrationFailure
    }
    Write-Output 'Cmder Here is registered for the current user. Open a new Explorer window; sign out and back in if Explorer still caches its menu.'
}

# Dot-sourcing exposes the operation for isolated fixture tests without registration.
if ($MyInvocation.InvocationName -ne '.') {
    [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
    try { Invoke-CmderContextMenuRegistration; exit 0 }
    catch { Write-Error $_ -ErrorAction Continue; exit 1 }
}

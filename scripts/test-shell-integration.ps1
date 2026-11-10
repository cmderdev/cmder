[CmdletBinding()]
param(
    [string]$SourceRoot,
    [string]$BuiltPackageRoot
)

$ErrorActionPreference = 'Stop'
if (-not $SourceRoot) { $SourceRoot = Join-Path $PSScriptRoot '..' }
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$helperSource = Join-Path $SourceRoot 'launcher\shell\Register-CmderContextMenu.ps1'
$helperText = [IO.File]::ReadAllText($helperSource)
$templateText = [IO.File]::ReadAllText((Join-Path $SourceRoot 'launcher\shell\AppxManifest.xml.in'))
$publisher = 'CN=Cmder Fixture Publisher'
$packageName = 'Cmder.ContextMenu'
$settingsPath = 'HKCU:\Software\Cmder\ContextMenu'
$script:assertions = 0
$script:cases = 0
$script:failures = New-Object 'System.Collections.Generic.List[string]'
$fixtureParent = Join-Path ([IO.Path]::GetTempPath()) ('cmder-shell-tests-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $fixtureParent

function Assert-True([bool]$Condition, [string]$Label) {
    if (-not $Condition) { throw $Label }
    $script:assertions++
}

function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ([string]$Actual -cne [string]$Expected) { throw "${Label}: expected '$Expected', received '$Actual'." }
    $script:assertions++
}

function Write-FixturePackage([string]$Path, [string]$Manifest) {
    if ([IO.File]::Exists($Path)) { [IO.File]::Delete($Path) }
    $archive = [IO.Compression.ZipFile]::Open($Path, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $writer = New-Object IO.StreamWriter($archive.CreateEntry('AppxManifest.xml').Open())
        try { $writer.Write($Manifest) } finally { $writer.Dispose() }
    } finally { $archive.Dispose() }
}

function Write-FixturePreference([string]$Path, [byte[]]$Bytes) {
    $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Path))
    [IO.File]::WriteAllBytes($Path, $Bytes)
}

function Invoke-FixtureCase([string]$Label, [hashtable]$Options, [scriptblock]$Check) {
    $script:cases++
    $root = Join-Path $fixtureParent ('case-' + $script:cases + ' [literal]')
    $shell = Join-Path $root 'bin\cmder-shell'
    $config = Join-Path $root 'config [literal] $ and quote''s'
    $null = New-Item -ItemType Directory -Path $shell, $config, (Join-Path $shell 'development') -Force
    [IO.File]::WriteAllText((Join-Path $root 'Cmder.exe'), 'fixture executable')
    [IO.File]::WriteAllText((Join-Path $shell 'CmderExplorerCommand.dll'), 'fixture DLL')
    [IO.File]::WriteAllText((Join-Path $shell 'Register-CmderContextMenu.ps1'), $helperText)
    [IO.File]::WriteAllText((Join-Path $shell 'Identity.json'), (@{ Name = $packageName; Publisher = $publisher } | ConvertTo-Json))
    $fixtureManifest = $templateText.Replace('@PUBLISHER@', $publisher).Replace('@VERSION@', '2.0.0.0')
    [IO.File]::WriteAllText((Join-Path $shell 'development\AppxManifest.xml'), $fixtureManifest)
    Write-FixturePackage (Join-Path $shell 'CmderContextMenu.msix') $fixtureManifest
    $owned = [pscustomobject]@{ Name = $packageName; Publisher = $publisher; PackageFullName = 'Cmder.ContextMenu_2.0.0.0_x64__fixture'; PackageFamilyName = 'Cmder.ContextMenu_fixture' }
    $foreign = [pscustomobject]@{ Name = $packageName; Publisher = 'CN=Unrelated Publisher'; PackageFullName = 'Cmder.ContextMenu_8.0.0.0_x64__unrelated'; PackageFamilyName = 'Cmder.ContextMenu_unrelated' }
    $state = @{
        Root = $root; Shell = $shell; Config = $config; Owned = $owned; Foreign = $foreign; Manifest = $fixtureManifest
        Packages = @(); Removed = @(); Added = @(); Writes = @(); Settings = @{ Preserve = 'unrelated setting' }
        KeyExists = $false; Build = 26100; Architecture = 'X64'; DeveloperMode = 0
        Signature = 'Valid'; SignerPublisher = $publisher; FailWrite = ''; WriteFailed = $false
        AddFails = $false; SuppressAddedPackage = $false; Error = $null; Output = @()
        PreferencePath = Join-Path $root 'package-data\Cmder.ContextMenu_fixture\LocalState\CmderContextMenu.ini'
        ForeignPreferencePath = Join-Path $root 'package-data\Cmder.ContextMenu_unrelated\LocalState\CmderContextMenu.ini'
    }
    if ($Options.ContainsKey('Before')) { & $Options.Before $state }
    foreach ($key in $Options.Keys) { if ($key -ne 'Before') { $state[$key] = $Options[$key] } }
    $state.PreferenceExisted = [IO.File]::Exists($state.PreferencePath)
    $state.PreferenceBefore = if ($state.PreferenceExisted) { [Convert]::ToBase64String([IO.File]::ReadAllBytes($state.PreferencePath)) } else { '' }
    $state.ForeignPreferenceExisted = [IO.File]::Exists($state.ForeignPreferencePath)
    $state.ForeignPreferenceBefore = if ($state.ForeignPreferenceExisted) { [Convert]::ToBase64String([IO.File]::ReadAllBytes($state.ForeignPreferencePath)) } else { '' }
    try {
        # Every host-facing command is shadowed in this child scope. Unexpected
        # registry access fails instead of reaching any real registry provider.
        & {
            param($state)
            function Get-ItemProperty {
                [CmdletBinding()]param([string]$Path, [string]$LiteralPath, [string[]]$Name)
                $target = if ($LiteralPath) { $LiteralPath } else { $Path }
                switch ($target) {
                    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' { return [pscustomobject]@{ CurrentBuildNumber = [string]$state.Build } }
                    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' { return [pscustomobject]@{ AllowDevelopmentWithoutDevLicense = $state.DeveloperMode } }
                    'HKCU:\Software\Cmder\ContextMenu' { if ($state.KeyExists) { return [pscustomobject]$state.Settings }; return }
                    default { throw "Unexpected registry read: $target" }
                }
            }
            function Get-AppxPackage {
                [CmdletBinding()]param([string]$Name, [string]$Publisher, [switch]$AllUsers, [string]$User)
                if ($AllUsers -or $User) { throw 'The helper attempted to query another user.' }
                if ($Name -cne 'Cmder.ContextMenu') { throw "Unexpected package query: $Name" }
                foreach ($entry in $state.Packages) { if (-not $Publisher -or $entry.Publisher -ceq $Publisher) { $entry } }
            }
            function Add-AppxPackage {
                [CmdletBinding()]param([string]$Path, [string]$Register, [string]$ExternalLocation,
                    [switch]$AllowUnsigned, [switch]$ForceApplicationShutdown, [switch]$ForceTargetApplicationShutdown,
                    [switch]$ForceUpdateFromAnyVersion, [switch]$AllUsers)
                if ($AllowUnsigned -or $ForceApplicationShutdown -or $ForceTargetApplicationShutdown -or $ForceUpdateFromAnyVersion -or $AllUsers) {
                    throw 'Registration attempted an unsigned, force-close, downgrade, or machine-wide operation.'
                }
                if ($state.AddFails) { throw 'fixture deployment failure' }
                $state.Added += [pscustomobject]@{ Path = $Path; Register = $Register; ExternalLocation = $ExternalLocation }
                if (-not $state.SuppressAddedPackage) {
                    $state.Packages = @($state.Packages | Where-Object PackageFullName -ne $state.Owned.PackageFullName) + @($state.Owned)
                }
            }
            function Remove-AppxPackage {
                [CmdletBinding()]param([string]$Package, [switch]$AllUsers, [string]$User)
                if ($AllUsers -or $User) { throw 'The helper attempted to remove a package for another user.' }
                $state.Removed += $Package
                $state.Packages = @($state.Packages | Where-Object PackageFullName -ne $Package)
                if ($Package -eq $state.Owned.PackageFullName) {
                    # Windows uninstall manages all data owned by this family.
                    # Keep the simulated recursive removal inside this fixture.
                    $packageData = [IO.Path]::GetFullPath((Join-Path $state.Root ('package-data\' + $state.Owned.PackageFamilyName)))
                    $boundary = [IO.Path]::GetFullPath((Join-Path $state.Root 'package-data')).TrimEnd('\') + '\'
                    if (-not $packageData.StartsWith($boundary, [StringComparison]::OrdinalIgnoreCase) -or
                        [IO.Path]::GetFileName($packageData) -ne $state.Owned.PackageFamilyName) { throw 'Unsafe package-data fixture removal.' }
                    if ([IO.Directory]::Exists($packageData)) { [IO.Directory]::Delete($packageData, $true) }
                }
            }
            function Get-AuthenticodeSignature {
                [CmdletBinding()]param([string]$LiteralPath, [string]$FilePath)
                [pscustomobject]@{ Status = $state.Signature; SignerCertificate = [pscustomobject]@{ Subject = $state.SignerPublisher } }
            }
            function Test-Path {
                [CmdletBinding()]param([string]$LiteralPath, [string]$Path, [string]$PathType)
                $target = if ($LiteralPath) { $LiteralPath } else { $Path }
                if ($target -like 'HK*:*') {
                    if ($target -ne 'HKCU:\Software\Cmder\ContextMenu') { throw "Unexpected registry path test: $target" }
                    return $state.KeyExists
                }
                $parameters = @{ LiteralPath = $target }
                if ($PathType) { $parameters.PathType = $PathType }
                Microsoft.PowerShell.Management\Test-Path @parameters
            }
            function New-Item {
                [CmdletBinding()]param([string]$Path, [string]$LiteralPath, [switch]$Force)
                $target = if ($LiteralPath) { $LiteralPath } else { $Path }
                if ($target -ne 'HKCU:\Software\Cmder\ContextMenu') { throw "Unexpected item creation: $target" }
                $state.KeyExists = $true
                $state.Writes += 'create key'
            }
            function New-ItemProperty {
                [CmdletBinding()]param([string]$LiteralPath, [string]$Path, [string]$Name, $Value, [string]$PropertyType, [switch]$Force)
                $target = if ($LiteralPath) { $LiteralPath } else { $Path }
                if ($target -ne 'HKCU:\Software\Cmder\ContextMenu') { throw "Unexpected setting write: $target" }
                if ($state.FailWrite -eq $Name -and -not $state.WriteFailed) { $state.WriteFailed = $true; throw 'fixture settings persistence failure' }
                $state.Settings[$Name] = $Value
                $state.Writes += ('write ' + $Name)
            }
            function Set-ItemProperty {
                [CmdletBinding()]param([string]$LiteralPath, [string]$Path, [string]$Name, $Value, [switch]$Force)
                New-ItemProperty -LiteralPath $LiteralPath -Path $Path -Name $Name -Value $Value -Force:$Force
            }
            function Remove-ItemProperty {
                [CmdletBinding()]param([string]$LiteralPath, [string]$Path, [string]$Name)
                $target = if ($LiteralPath) { $LiteralPath } else { $Path }
                if ($target -ne 'HKCU:\Software\Cmder\ContextMenu') { throw "Unexpected setting removal: $target" }
                $state.Settings.Remove($Name)
                $state.Writes += ('remove ' + $Name)
            }
            function Remove-Item {
                [CmdletBinding()]param([string]$LiteralPath, [string]$Path, [switch]$Force, [switch]$Recurse)
                throw 'The helper must preserve the settings key and unrelated values.'
            }
            $action = if ($state.ContainsKey('Action')) { $state.Action } else { 'Register' }
            $parameters = @{ Action = $action }
            if ($state.ContainsKey('UseConfig')) { $parameters.ConfigRoot = $state.Config }
            if ($state.ContainsKey('Single')) { $parameters.SingleInstance = [bool]$state.Single }
            if ($state.ContainsKey('Development')) { $parameters.Development = [bool]$state.Development }
            . (Join-Path $state.Shell 'Register-CmderContextMenu.ps1') @parameters
            # This seam returns the real OS architecture in production.
            function Get-CmderContextMenuOSArchitecture { $state.Architecture }
            function Get-CmderContextMenuPackageFamilyName([string]$Name, [string]$Publisher) {
                if ($Name -ne $state.Owned.Name -or $Publisher -ne $state.Owned.Publisher) { throw 'Unexpected package family derivation.' }
                return $state.Owned.PackageFamilyName
            }
            function Get-CmderContextMenuPreferencePath([string]$Family) {
                if ($Family -ne $state.Owned.PackageFamilyName) { throw 'Unexpected preference-file family.' }
                return $state.PreferencePath
            }
            try { $state.Output = @(Invoke-CmderContextMenuRegistration -WhatIf:([bool]$state.WhatIf)) }
            catch { $state.Error = $_.Exception.Message }
        } $state
        & $Check $state
        Write-Output ("PASS: " + $Label)
    } catch {
        $script:failures.Add($Label + ': ' + $_.Exception.Message)
        Write-Output ("FAIL: " + $Label + ': ' + $_.Exception.Message)
    }
}

function Assert-NoMutation($State) {
    Assert-Equal $State.Added.Count 0 'No package added'
    Assert-Equal $State.Removed.Count 0 'No package removed'
    Assert-Equal $State.Writes.Count 0 'No registry mutation'
    Assert-Equal ([IO.File]::Exists($State.PreferencePath)) $State.PreferenceExisted 'Preference-file existence is unchanged'
    if ($State.PreferenceExisted) { Assert-Equal ([Convert]::ToBase64String([IO.File]::ReadAllBytes($State.PreferencePath))) $State.PreferenceBefore 'Previous preference bytes are unchanged' }
    Assert-Equal ([IO.File]::Exists($State.ForeignPreferencePath)) $State.ForeignPreferenceExisted 'Foreign preference-file existence is unchanged'
    if ($State.ForeignPreferenceExisted) { Assert-Equal ([Convert]::ToBase64String([IO.File]::ReadAllBytes($State.ForeignPreferencePath))) $State.ForeignPreferenceBefore 'Foreign preference bytes are unchanged' }
}

function Assert-RejectedWithoutMutation($State) {
    Assert-True ([bool]$State.Error) 'The invalid operation must fail'
    Assert-NoMutation $State
}

function Test-Manifest([string]$XmlText, [string]$Label, [string]$ExpectedPublisher) {
    $xml = New-Object Xml.XmlDocument
    $xml.XmlResolver = $null
    $xml.LoadXml($XmlText)
    $ns = New-Object Xml.XmlNamespaceManager($xml.NameTable)
    foreach ($entry in @{
        f = 'http://schemas.microsoft.com/appx/manifest/foundation/windows10'
        uap = 'http://schemas.microsoft.com/appx/manifest/uap/windows10'
        uap10 = 'http://schemas.microsoft.com/appx/manifest/uap/windows10/10'
        desktop4 = 'http://schemas.microsoft.com/appx/manifest/desktop/windows10/4'
        desktop5 = 'http://schemas.microsoft.com/appx/manifest/desktop/windows10/5'
        desktop10 = 'http://schemas.microsoft.com/appx/manifest/desktop/windows10/10'
        com = 'http://schemas.microsoft.com/appx/manifest/com/windows10'
    }.GetEnumerator()) { $ns.AddNamespace($entry.Key, $entry.Value) }
    $identity = $xml.SelectSingleNode('/f:Package/f:Identity', $ns)
    Assert-Equal $identity.Name 'Cmder.ContextMenu' "$Label package identity"
    Assert-Equal $identity.Publisher $ExpectedPublisher "$Label publisher"
    Assert-Equal $identity.ProcessorArchitecture 'x64' "$Label architecture"
    Assert-True ([version]$identity.Version -ge [version]'1.0.0.0') "$Label numeric version"
    $target = $xml.SelectSingleNode('/f:Package/f:Dependencies/f:TargetDeviceFamily', $ns)
    Assert-Equal $target.Name 'Windows.Desktop' "$Label target family"
    Assert-True ([version]$target.MinVersion -ge [version]'10.0.22621.0') "$Label minimum OS covers drive registration"
    Assert-Equal ($xml.SelectSingleNode('//uap10:AllowExternalContent', $ns).InnerText) 'true' "$Label sparse content"
    $app = $xml.SelectSingleNode('/f:Package/f:Applications/f:Application', $ns)
    Assert-Equal $app.Executable 'Cmder.exe' "$Label external executable"
    Assert-True (-not $app.HasAttribute('EntryPoint')) "$Label win32App has no incompatible EntryPoint"
    Assert-Equal ($app.GetAttribute('RuntimeBehavior', $ns.LookupNamespace('uap10'))) 'win32App' "$Label runtime behavior"
    Assert-Equal ($xml.SelectSingleNode('//uap:VisualElements', $ns).AppListEntry) 'none' "$Label hidden app-list entry"
    $class = $xml.SelectSingleNode('//com:SurrogateServer/com:Class', $ns)
    Assert-Equal $class.Path 'bin\cmder-shell\CmderExplorerCommand.dll' "$Label relative external DLL"
    $header = [IO.File]::ReadAllText((Join-Path $SourceRoot 'launcher\shell\CmderExplorerCommand.h'))
    $nativeId = [regex]::Match($header, 'uuid\("([0-9A-Fa-f-]{36})"\)').Groups[1].Value
    Assert-True ([bool]$nativeId) "$Label native CLSID is declared"
    Assert-Equal ([guid]$class.Id) ([guid]$nativeId) "$Label native and manifest CLSIDs match"
    $menus = $xml.SelectSingleNode('//desktop4:FileExplorerContextMenus', $ns)
    Assert-Equal (@($menus.SelectNodes('desktop5:ItemType[@Type="Directory"]/desktop5:Verb', $ns)).Count) 1 "$Label directory registration"
    Assert-Equal (@($menus.SelectNodes('desktop5:ItemType[@Type="Directory\Background"]/desktop5:Verb', $ns)).Count) 1 "$Label background registration"
    Assert-Equal (@($menus.SelectNodes('desktop10:ItemType[@Type="Drive"]/desktop10:Verb', $ns)).Count) 1 "$Label drive uses desktop10"
    foreach ($verb in $menus.SelectNodes('*/*', $ns)) { Assert-Equal ([guid]$verb.Clsid) ([guid]$class.Id) "$Label command CLSID" }
    return $xml
}

try {
    Invoke-FixtureCase 'Production registration preserves literal configuration and unrelated settings' @{ UseConfig = $true; Single = $true; Before = {
        param($s) $null = [IO.Directory]::CreateDirectory((Join-Path $s.Root 'vendor\conemu-maximus5'))
    } } {
        param($s)
        Assert-True (-not $s.Error) ('Registration failed: ' + $s.Error)
        Assert-Equal $s.Added.Count 1 'One current-user identity added'
        Assert-Equal $s.Added[0].ExternalLocation $s.Root 'External root is the portable root'
        Assert-Equal $s.Added[0].Path (Join-Path $s.Shell 'CmderContextMenu.msix') 'Production uses MSIX'
        Assert-Equal $s.Settings.ConfigRoot $s.Config 'Literal config path preserved'
        Assert-Equal $s.Settings.SingleInstance 1 'Single-instance preference saved'
        Assert-Equal $s.Settings.InstallRoot $s.Root 'Install root saved'
        Assert-Equal $s.Settings.PackageFamilyName $s.Owned.PackageFamilyName 'Registered family saved'
        Assert-Equal $s.Settings.Preserve 'unrelated setting' 'Unrelated preference survives'
        Assert-Equal ([IO.File]::ReadAllText($s.PreferencePath, [Text.Encoding]::Unicode)) ("[Cmder]`r`nConfigRoot=$($s.Config)`r`nSingleInstance=1`r`n") 'Packaged COM preference file contains config and single instance'
    }
    Invoke-FixtureCase 'Default preferences are explicit' @{} {
        param($s)
        Assert-True (-not $s.Error) ('Registration failed: ' + $s.Error)
        Assert-Equal $s.Settings.ConfigRoot '' 'Default config is empty'
        Assert-Equal $s.Settings.SingleInstance 0 'Default does not force a single instance'
        Assert-Equal ([IO.File]::ReadAllText($s.PreferencePath, [Text.Encoding]::Unicode)) "[Cmder]`r`nConfigRoot=`r`nSingleInstance=0`r`n" 'Default preferences are written for packaged COM'
    }
    Invoke-FixtureCase 'Preference file preserves Unicode configuration in UTF-16 with a BOM' @{ UseConfig = $true; Before = {
        param($s)
        $s.Config = Join-Path $s.Root ('config ' + [char]0x06A9 + [char]0x0645 + [char]0x062F + [char]0x0631 + ' ' + [char]0x65E5)
        $null = [IO.Directory]::CreateDirectory($s.Config)
    } } {
        param($s)
        Assert-True (-not $s.Error) ('Unicode preference registration failed: ' + $s.Error)
        $bytes = [IO.File]::ReadAllBytes($s.PreferencePath)
        Assert-True ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) 'Preference file has a UTF-16LE BOM'
        Assert-Equal ([Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)) ("[Cmder]`r`nConfigRoot=$($s.Config)`r`nSingleInstance=0`r`n") 'Unicode and CRLF preference values are exact'
    }
    Invoke-FixtureCase 'Configuration rejects an existing file before deployment' @{ UseConfig = $true; Before = {
        param($s) $s.Config = Join-Path $s.Root 'Cmder.exe'
    } } ${function:Assert-RejectedWithoutMutation}
    Invoke-FixtureCase 'Configuration rejects a non-filesystem provider before deployment' @{ UseConfig = $true; Before = {
        param($s) $s.Config = 'Env:\PATH'
    } } ${function:Assert-RejectedWithoutMutation}
    Invoke-FixtureCase 'Single-instance registration rejects a package without ConEmu' @{ Single = $true } ${function:Assert-RejectedWithoutMutation}
    Invoke-FixtureCase 'Single-instance registration rejects Windows Terminal even alongside ConEmu' @{ Single = $true; Before = {
        param($s)
        $null = [IO.Directory]::CreateDirectory((Join-Path $s.Root 'vendor\conemu-maximus5'))
        $null = [IO.Directory]::CreateDirectory((Join-Path $s.Root 'vendor\windows-terminal'))
    } } ${function:Assert-RejectedWithoutMutation}
    foreach ($signature in @('NotSigned', 'HashMismatch', 'NotTrusted')) {
        Invoke-FixtureCase ("Production rejects signature: " + $signature) @{ Signature = $signature } ${function:Assert-RejectedWithoutMutation}
    }
    Invoke-FixtureCase 'Production rejects MSIX and identity publisher mismatch' @{ Before = {
        param($s) Write-FixturePackage (Join-Path $s.Shell 'CmderContextMenu.msix') ($s.Manifest.Replace('CN=Cmder Fixture Publisher', 'CN=Different Publisher'))
    } } ${function:Assert-RejectedWithoutMutation}
    Invoke-FixtureCase 'Production rejects a different package Name' @{ Before = {
        param($s) Write-FixturePackage (Join-Path $s.Shell 'CmderContextMenu.msix') ($s.Manifest.Replace('Name="Cmder.ContextMenu"', 'Name="Other.Application"'))
    } } ${function:Assert-RejectedWithoutMutation}
    foreach ($missing in @('Cmder.exe', 'bin\cmder-shell\CmderExplorerCommand.dll', 'bin\cmder-shell\CmderContextMenu.msix', 'bin\cmder-shell\Identity.json')) {
        $before = { param($s) [IO.File]::Delete((Join-Path $s.Root $missing)) }.GetNewClosure()
        Invoke-FixtureCase ("Register rejects missing " + $missing) @{ Before = $before } ${function:Assert-RejectedWithoutMutation}
    }
    Invoke-FixtureCase 'Register rejects unsupported Windows build' @{ Build = 22000 } ${function:Assert-RejectedWithoutMutation}
    foreach ($architecture in @('Arm64', 'X86')) {
        Invoke-FixtureCase ("Register rejects " + $architecture + ' Windows') @{ Architecture = $architecture } ${function:Assert-RejectedWithoutMutation}
    }
    Invoke-FixtureCase 'Register WhatIf performs no deployment or preference writes' @{ WhatIf = $true; Before = {
        param($s) Write-FixturePreference $s.PreferencePath ([byte[]]@(255, 254, 10, 0, 42, 0))
    } } {
        param($s) Assert-True (-not $s.Error) ('WhatIf failed: ' + $s.Error); Assert-NoMutation $s
    }
    Invoke-FixtureCase 'Unregister works without executable, DLL or MSIX and only removes owned identity' @{ Action = 'Unregister'; Before = {
        param($s)
        [IO.File]::Delete((Join-Path $s.Root 'Cmder.exe'))
        [IO.File]::Delete((Join-Path $s.Shell 'CmderExplorerCommand.dll'))
        [IO.File]::Delete((Join-Path $s.Shell 'CmderContextMenu.msix'))
        $s.Packages = @($s.Owned, $s.Foreign)
        $s.KeyExists = $true
        $s.Settings.ConfigRoot = $s.Config; $s.Settings.SingleInstance = 1; $s.Settings.InstallRoot = $s.Root
        $s.Settings.PackageFamilyName = $s.Owned.PackageFamilyName
        Write-FixturePreference $s.PreferencePath ([Text.Encoding]::Unicode.GetBytes('owned preferences'))
        Write-FixturePreference $s.ForeignPreferencePath ([Text.Encoding]::Unicode.GetBytes('foreign preferences'))
        [IO.File]::WriteAllText((Join-Path $s.Config 'user-profile.cmd'), 'source profile outside package data')
    } } {
        param($s)
        Assert-True (-not $s.Error) ('Unregister failed: ' + $s.Error)
        Assert-Equal ($s.Removed -join ',') $s.Owned.PackageFullName 'Only the owned full identity removed'
        Assert-Equal $s.Packages.Count 1 'Foreign package survives'
        Assert-Equal $s.Packages[0].PackageFullName $s.Foreign.PackageFullName 'Foreign publisher protected'
        Assert-Equal $s.Settings.Preserve 'unrelated setting' 'Unrelated preference survives removal'
        foreach ($name in @('ConfigRoot', 'SingleInstance', 'InstallRoot', 'PackageFamilyName')) { Assert-True (-not $s.Settings.ContainsKey($name)) ("Owned preference removed: " + $name) }
        Assert-True (-not [IO.File]::Exists($s.PreferencePath)) 'Owned package preference file is removed'
        Assert-Equal ([IO.File]::ReadAllText($s.ForeignPreferencePath, [Text.Encoding]::Unicode)) 'foreign preferences' 'Other publisher preference file survives'
        Assert-Equal ([IO.File]::ReadAllText((Join-Path $s.Config 'user-profile.cmd'))) 'source profile outside package data' 'Source profile outside package data survives'
    }
    Invoke-FixtureCase 'Unregister WhatIf preserves package and preferences' @{ Action = 'Unregister'; WhatIf = $true; Before = {
        param($s) $s.Packages = @($s.Owned); $s.KeyExists = $true; $s.Settings.ConfigRoot = $s.Config
        $s.Settings.PackageFamilyName = $s.Owned.PackageFamilyName
        Write-FixturePreference $s.PreferencePath ([byte[]]@(255, 254, 10, 0, 42, 0))
    } } { param($s) Assert-True (-not $s.Error) ('WhatIf failed: ' + $s.Error); Assert-NoMutation $s; Assert-Equal $s.Settings.ConfigRoot $s.Config 'WhatIf config preserved' }
    Invoke-FixtureCase 'Unregister cleans orphan preferences of its own family without a package' @{ Action = 'Unregister'; Before = {
        param($s) $s.KeyExists = $true; $s.Settings.PackageFamilyName = $s.Owned.PackageFamilyName
        $s.Settings.ConfigRoot = $s.Config; $s.Settings.SingleInstance = 1; $s.Settings.InstallRoot = $s.Root
        Write-FixturePreference $s.PreferencePath ([byte[]]@(42, 10, 255))
    } } {
        param($s)
        Assert-True (-not $s.Error) ('Orphan cleanup failed: ' + $s.Error)
        Assert-Equal $s.Removed.Count 0 'No package removal for an orphan'
        Assert-Equal $s.Settings.Count 1 'Only the four orphan-owned settings removed'
        Assert-Equal $s.Settings.Preserve 'unrelated setting' 'Unrelated setting survives orphan cleanup'
        Assert-True (-not [IO.File]::Exists($s.PreferencePath)) 'Owned orphan preference file is removed'
    }
    Invoke-FixtureCase 'Foreign package with the same Name is never removed' @{ Action = 'Unregister'; Before = { param($s) $s.Packages = @($s.Foreign) } } {
        param($s) Assert-Equal $s.Removed.Count 0 'No foreign removal'; Assert-Equal $s.Packages.Count 1 'Foreign package remains'
    }
    Invoke-FixtureCase 'Unregister preserves another publisher active preferences' @{ Action = 'Unregister'; Before = {
        param($s) $s.Packages = @($s.Foreign); $s.KeyExists = $true
        $s.Settings.PackageFamilyName = $s.Foreign.PackageFamilyName; $s.Settings.InstallRoot = 'C:\Other publisher installation'
        $s.Settings.ConfigRoot = 'C:\Other publisher config'; $s.Settings.SingleInstance = 1
        Write-FixturePreference $s.ForeignPreferencePath ([byte[]]@(17, 13, 10, 255))
    } } {
        param($s)
        Assert-NoMutation $s
        Assert-Equal $s.Settings.PackageFamilyName $s.Foreign.PackageFamilyName 'Foreign preference ownership preserved'
        Assert-Equal $s.Settings.ConfigRoot 'C:\Other publisher config' 'Foreign config preserved'
        Assert-Equal $s.Settings.SingleInstance 1 'Foreign single-instance preference preserved'
        Assert-Equal $s.Settings.InstallRoot 'C:\Other publisher installation' 'Foreign install root preserved'
    }
    Invoke-FixtureCase 'Unregister may remove owned package while preserving another publisher active preferences' @{ Action = 'Unregister'; Before = {
        param($s) $s.Packages = @($s.Owned, $s.Foreign); $s.KeyExists = $true
        $s.Settings.PackageFamilyName = $s.Foreign.PackageFamilyName; $s.Settings.InstallRoot = 'C:\Other publisher installation'
        $s.Settings.ConfigRoot = 'C:\Other publisher config'; $s.Settings.SingleInstance = 1
        Write-FixturePreference $s.PreferencePath ([byte[]]@(42, 0))
        Write-FixturePreference $s.ForeignPreferencePath ([byte[]]@(17, 13, 10, 255))
    } } {
        param($s)
        Assert-Equal ($s.Removed -join ',') $s.Owned.PackageFullName 'Owned package alone is removed'
        Assert-Equal $s.Writes.Count 0 'No foreign preference writes'
        Assert-Equal $s.Settings.PackageFamilyName $s.Foreign.PackageFamilyName 'Foreign active family preserved'
        Assert-Equal $s.Settings.ConfigRoot 'C:\Other publisher config' 'Foreign config survives owned package removal'
        Assert-True (-not [IO.File]::Exists($s.PreferencePath)) 'Owned file is removed despite foreign shared preferences'
        Assert-Equal ([Convert]::ToBase64String([IO.File]::ReadAllBytes($s.ForeignPreferencePath))) $s.ForeignPreferenceBefore 'Foreign preference file survives owned package removal'
    }
    Invoke-FixtureCase 'Register cannot overwrite another publisher active preferences' @{ Before = {
        param($s) $s.Packages = @($s.Foreign); $s.KeyExists = $true
        $s.Settings.PackageFamilyName = $s.Foreign.PackageFamilyName; $s.Settings.InstallRoot = 'C:\Other publisher installation'
        $s.Settings.ConfigRoot = 'C:\Other publisher config'; $s.Settings.SingleInstance = 1
    } } {
        param($s)
        Assert-RejectedWithoutMutation $s
        Assert-Equal $s.Settings.PackageFamilyName $s.Foreign.PackageFamilyName 'Foreign active family protected on register'
        Assert-Equal $s.Settings.ConfigRoot 'C:\Other publisher config' 'Foreign active config protected on register'
    }
    Invoke-FixtureCase 'Register rejects another installed publisher even without shared preferences' @{ Before = {
        param($s) $s.Packages = @($s.Foreign)
    } } ${function:Assert-RejectedWithoutMutation}
    Invoke-FixtureCase 'Another portable installation cannot be silently replaced' @{ Before = {
        param($s) $s.Packages = @($s.Owned); $s.KeyExists = $true; $s.Settings.InstallRoot = 'C:\Another Cmder'
    } } ${function:Assert-RejectedWithoutMutation}
    Invoke-FixtureCase 'Development registration requires explicit enabled Developer Mode' @{ Development = $true } ${function:Assert-RejectedWithoutMutation}
    Invoke-FixtureCase 'Explicit development registration uses the loose manifest' @{ Development = $true; DeveloperMode = 1; Signature = 'NotSigned' } {
        param($s)
        Assert-True (-not $s.Error) ('Development registration failed: ' + $s.Error)
        Assert-Equal $s.Added.Count 1 'One development registration'
        Assert-Equal $s.Added[0].Register (Join-Path $s.Shell 'development\AppxManifest.xml') 'Explicit loose manifest'
        Assert-Equal $s.Added[0].Path '' 'Development does not install unsigned production MSIX'
    }
    Invoke-FixtureCase 'Deployment failure leaves preferences untouched' @{ AddFails = $true } ${function:Assert-RejectedWithoutMutation}
    $sameVersionSetup = {
        param($s)
        Add-Member -InputObject $s.Owned -NotePropertyName Version -NotePropertyValue ([version]'2.0.0.0')
        $s.Packages = @($s.Owned); $s.KeyExists = $true
        $s.Settings.InstallRoot = $s.Root; $s.Settings.ConfigRoot = 'C:\Previous config'; $s.Settings.SingleInstance = 1
        $s.Settings.PackageFamilyName = $s.Owned.PackageFamilyName
        Write-FixturePreference $s.PreferencePath ([byte[]]@(255, 254, 91, 0, 42, 0, 13, 0, 10, 0))
    }
    Invoke-FixtureCase 'Same-version registration updates preferences without redeploying an in-use package' @{ UseConfig = $true; Single = $false; AddFails = $true; Before = $sameVersionSetup } {
        param($s)
        Assert-True (-not $s.Error) ('Same-version preference update failed: ' + $s.Error)
        Assert-Equal $s.Added.Count 0 'The same registered version is not redeployed'
        Assert-Equal $s.Removed.Count 0 'The registered package is retained'
        Assert-Equal $s.Settings.ConfigRoot $s.Config 'Updated configuration metadata is saved'
        Assert-Equal $s.Settings.SingleInstance 0 'Single-instance metadata can be disabled'
        Assert-Equal ([IO.File]::ReadAllText($s.PreferencePath, [Text.Encoding]::Unicode)) ("[Cmder]`r`nConfigRoot=$($s.Config)`r`nSingleInstance=0`r`n") 'Preference file receives the new configuration and disabled single-instance flag'
    }
    Invoke-FixtureCase 'Same-version preference update still validates the production signature' @{ Signature = 'NotSigned'; Before = $sameVersionSetup } ${function:Assert-RejectedWithoutMutation}
    Invoke-FixtureCase 'Same-version preference update still requires explicit enabled Developer Mode' @{ Development = $true; Before = $sameVersionSetup } ${function:Assert-RejectedWithoutMutation}
    Invoke-FixtureCase 'A newer manifest version still deploys the package' @{ Before = {
        param($s)
        & $sameVersionSetup $s
        Write-FixturePackage (Join-Path $s.Shell 'CmderContextMenu.msix') ($s.Manifest.Replace('Version="2.0.0.0"', 'Version="2.1.0.0"'))
    } } {
        param($s)
        Assert-True (-not $s.Error) ('New-version registration failed: ' + $s.Error)
        Assert-Equal $s.Added.Count 1 'A changed manifest version goes through deployment'
        Assert-Equal $s.Added[0].Path (Join-Path $s.Shell 'CmderContextMenu.msix') 'The newer production package is deployed'
    }
    Invoke-FixtureCase 'Same-version preference failure restores previous bytes without package removal' @{ UseConfig = $true; AddFails = $true; FailWrite = 'SingleInstance'; Before = $sameVersionSetup } {
        param($s)
        Assert-True ($s.Error -like '*persistence failure*') 'Same-version persistence error is reported'
        Assert-Equal $s.Added.Count 0 'A preference-only update performs no deployment'
        Assert-Equal $s.Removed.Count 0 'Preference-only rollback retains the registered package'
        Assert-Equal ([Convert]::ToBase64String([IO.File]::ReadAllBytes($s.PreferencePath))) $s.PreferenceBefore 'Preference-only rollback restores exact prior bytes'
        Assert-Equal $s.Settings.ConfigRoot 'C:\Previous config' 'Preference-only rollback restores previous metadata'
        Assert-Equal $s.Settings.SingleInstance 1 'Preference-only rollback restores the single-instance preference'
    }
    Invoke-FixtureCase 'New registration rolls back package and partial preferences after persistence failure' @{ UseConfig = $true; FailWrite = 'SingleInstance' } {
        param($s)
        Assert-True ($s.Error -like '*persistence failure*') 'Persistence error is reported'
        Assert-Equal $s.Added.Count 1 'New identity was deployed'
        Assert-Equal ($s.Removed -join ',') $s.Owned.PackageFullName 'Only newly deployed identity rolled back'
        Assert-Equal $s.Packages.Count 0 'No orphan identity remains'
        Assert-Equal $s.Settings.Count 1 'Partial owned preferences removed'
        Assert-Equal $s.Settings.Preserve 'unrelated setting' 'Unrelated setting retained during rollback'
        Assert-True (-not [IO.File]::Exists($s.PreferencePath)) 'New preference file is removed during rollback'
    }
    Invoke-FixtureCase 'Updating registration restores previous preferences after persistence failure' @{ UseConfig = $true; FailWrite = 'SingleInstance'; Before = {
        param($s) $s.Packages = @($s.Owned); $s.KeyExists = $true
        $s.Settings.InstallRoot = $s.Root; $s.Settings.ConfigRoot = 'C:\Previous config'; $s.Settings.SingleInstance = 1
        $s.Settings.PackageFamilyName = $s.Owned.PackageFamilyName
        Write-FixturePreference $s.PreferencePath ([byte[]]@(255, 254, 91, 0, 42, 0, 0, 0, 13, 0, 10, 0))
    } } {
        param($s)
        Assert-True ($s.Error -like '*persistence failure*') 'Update persistence error reported'
        Assert-Equal $s.Removed.Count 0 'Existing identity is retained'
        Assert-Equal $s.Settings.ConfigRoot 'C:\Previous config' 'Previous config restored'
        Assert-Equal $s.Settings.SingleInstance 1 'Previous single-instance value retained'
        Assert-Equal $s.Settings.Preserve 'unrelated setting' 'Unrelated setting survives update rollback'
        Assert-Equal ([Convert]::ToBase64String([IO.File]::ReadAllBytes($s.PreferencePath))) $s.PreferenceBefore 'Previous preference file is restored byte for byte'
    }
    Invoke-FixtureCase 'New package rollback preserves orphan preference bytes' @{ FailWrite = 'SingleInstance'; Before = {
        param($s) Write-FixturePreference $s.PreferencePath ([byte[]]@(42, 10, 0, 255))
    } } {
        param($s)
        Assert-True ($s.Error -like '*persistence failure*') 'Persistence error is reported for orphan-file rollback'
        Assert-Equal ($s.Removed -join ',') $s.Owned.PackageFullName 'New package is rolled back'
        Assert-Equal ([Convert]::ToBase64String([IO.File]::ReadAllBytes($s.PreferencePath))) $s.PreferenceBefore 'Orphan bytes survive new package rollback'
    }
    Invoke-FixtureCase 'Update rollback preserves an empty previous preference file' @{ FailWrite = 'SingleInstance'; Before = {
        param($s) $s.Packages = @($s.Owned); $s.KeyExists = $true
        $s.Settings.InstallRoot = $s.Root; $s.Settings.PackageFamilyName = $s.Owned.PackageFamilyName
        Write-FixturePreference $s.PreferencePath ([byte[]]@())
    } } {
        param($s)
        Assert-True ($s.Error -like '*persistence failure*') 'Persistence error is reported for empty-file rollback'
        Assert-Equal $s.Removed.Count 0 'Existing package is retained during empty-file rollback'
        Assert-True ([IO.File]::Exists($s.PreferencePath)) 'Existing empty preference file remains'
        Assert-Equal ([IO.File]::ReadAllBytes($s.PreferencePath).Length) 0 'Empty file is restored without an added BOM'
    }
    Invoke-FixtureCase 'Preference-file write failure rolls back the new package without touching source profiles' @{ Before = {
        param($s)
        $parent = [IO.Path]::GetDirectoryName($s.PreferencePath)
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($parent))
        [IO.File]::WriteAllText($parent, 'fixture obstruction inside owned package data')
        [IO.File]::WriteAllText((Join-Path $s.Config 'user-profile.cmd'), 'source profile outside package data')
    } } {
        param($s)
        Assert-True ([bool]$s.Error) 'Preference write failure is reported'
        Assert-Equal $s.Added.Count 1 'Package deployment was attempted'
        Assert-Equal ($s.Removed -join ',') $s.Owned.PackageFullName 'New package is rolled back after file write failure'
        Assert-Equal ([IO.File]::ReadAllText((Join-Path $s.Config 'user-profile.cmd'))) 'source profile outside package data' 'Source profile survives package rollback'
        Assert-Equal $s.Settings.Count 1 'No partial owned registry preferences remain'
    }

    $manifest = Test-Manifest ($templateText.Replace('@PUBLISHER@', $publisher).Replace('@VERSION@', '2.0.0.0')) 'Generated template' $publisher
    # SDK XSDs are optional on runtime machines. Compile the installed set when
    # available; report an incomplete SDK set instead of claiming validation.
    $sdkIncludes = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\Include'
    $schemaDirectory = @(Get-ChildItem -LiteralPath $sdkIncludes -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^10\.\d+\.\d+\.\d+$' } | Sort-Object { [version]$_.Name } -Descending |
        ForEach-Object { Join-Path $_.FullName 'winrt' } | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'DesktopManifestSchema_v10.xsd') } | Select-Object -First 1)
    $schemas = $null
    if ($schemaDirectory.Count) {
        try {
            $schemas = New-Object Xml.Schema.XmlSchemaSet
            $schemas.XmlResolver = $null
            foreach ($file in (Get-ChildItem -LiteralPath $schemaDirectory[0] -Filter '*.xsd' | Where-Object Name -ne 'AppxManifestSchema.xsd')) {
                $schema = New-Object Xml.XmlDocument
                $schema.XmlResolver = $null
                $schema.Load($file.FullName)
                $null = $schemas.Add($schema.DocumentElement.GetAttribute('targetNamespace'), $file.FullName)
            }
            $schemas.Compile()
        } catch {
            $schemas = $null
            Write-Warning ('SDK schema validation unavailable: ' + $_.Exception.Message)
        }
    } else { Write-Warning 'SDK schema validation unavailable: Windows SDK desktop10 schemas are not installed.' }
    if ($schemas) {
        $manifest.Schemas = $schemas
        $manifest.Validate($null)
        $script:assertions++
        Write-Output 'PASS: Generated manifest validates against installed SDK schemas.'
    }
    if ($BuiltPackageRoot) {
        $built = (Resolve-Path -LiteralPath $BuiltPackageRoot).Path
        foreach ($path in @('CmderExplorerCommand.dll', 'CmderContextMenu.msix', 'Identity.json', 'Register-CmderContextMenu.ps1')) {
            Assert-True (Test-Path -LiteralPath (Join-Path $built $path) -PathType Leaf) ("Built artifact exists: " + $path)
        }
        $metadata = [IO.File]::ReadAllText((Join-Path $built 'Identity.json')) | ConvertFrom-Json
        $dllBytes = [IO.File]::ReadAllBytes((Join-Path $built 'CmderExplorerCommand.dll'))
        Assert-True ($dllBytes.Length -gt 64 -and $dllBytes[0] -eq 0x4d -and $dllBytes[1] -eq 0x5a) 'Built DLL has a DOS executable header'
        $peOffset = [BitConverter]::ToInt32($dllBytes, 0x3c)
        Assert-True ($peOffset -ge 64 -and $peOffset + 24 -lt $dllBytes.Length) 'Built DLL has a bounded PE header'
        Assert-True ([BitConverter]::ToUInt32($dllBytes, $peOffset) -eq 0x4550) 'Built DLL has a PE signature'
        Assert-True ([BitConverter]::ToUInt16($dllBytes, $peOffset + 4) -eq 0x8664) 'Built DLL matches x64 Explorer'
        Assert-True (([BitConverter]::ToUInt16($dllBytes, $peOffset + 22) -band 0x2000) -ne 0) 'Built PE is a DLL'
        Assert-Equal ([IO.File]::ReadAllText((Join-Path $built 'Register-CmderContextMenu.ps1'))) $helperText 'Built registration helper matches shipped source'
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $built 'CmderContextMenu.msix'))
        try {
            $entry = $zip.GetEntry('AppxManifest.xml')
            Assert-True ($null -ne $entry) 'Built package contains its manifest'
            $reader = New-Object IO.StreamReader($entry.Open())
            try { $builtXml = $reader.ReadToEnd() } finally { $reader.Dispose() }
            $builtManifest = Test-Manifest $builtXml 'Actual MSIX' $metadata.Publisher
            Assert-Equal $metadata.Name 'Cmder.ContextMenu' 'Built metadata name'
            Assert-Equal ([IO.File]::ReadAllText((Join-Path $built 'development\AppxManifest.xml'))) $builtXml 'Development and packaged manifests match'
            foreach ($logo in @(@('StoreLogo.png', 50), @('Square44x44Logo.png', 44), @('Square150x150Logo.png', 150))) {
                $logoEntry = $zip.GetEntry('Assets/' + $logo[0])
                Assert-True ($null -ne $logoEntry) ('Built MSIX contains logo: ' + $logo[0])
                $memory = New-Object IO.MemoryStream
                $stream = $logoEntry.Open()
                try { $stream.CopyTo($memory); $bytes = $memory.ToArray() } finally { $stream.Dispose(); $memory.Dispose() }
                Assert-True ($bytes.Length -ge 24 -and [BitConverter]::ToString($bytes, 0, 8) -eq '89-50-4E-47-0D-0A-1A-0A') ('Valid PNG signature: ' + $logo[0])
                Assert-Equal ([Text.Encoding]::ASCII.GetString($bytes, 12, 4)) 'IHDR' ('PNG dimension header: ' + $logo[0])
                $width = ([int]$bytes[16] -shl 24) -bor ([int]$bytes[17] -shl 16) -bor ([int]$bytes[18] -shl 8) -bor [int]$bytes[19]
                $height = ([int]$bytes[20] -shl 24) -bor ([int]$bytes[21] -shl 16) -bor ([int]$bytes[22] -shl 8) -bor [int]$bytes[23]
                Assert-Equal $width $logo[1] ('PNG width: ' + $logo[0])
                Assert-Equal $height $logo[1] ('PNG height: ' + $logo[0])
                $developmentLogo = [IO.File]::ReadAllBytes((Join-Path $built ('development\Assets\' + $logo[0])))
                Assert-Equal ([Convert]::ToBase64String($developmentLogo)) ([Convert]::ToBase64String($bytes)) ('Development and packaged logos match: ' + $logo[0])
            }
            foreach ($entry in $zip.Entries) {
                Assert-True ($entry.FullName -notmatch '(?i)\.(exe|dll|pfx|cer)$') ('Sparse package excludes binaries and certificates: ' + $entry.FullName)
            }
            if ($schemas) { $builtManifest.Schemas = $schemas; $builtManifest.Validate($null); $script:assertions++ }
        } finally { $zip.Dispose() }
    }
    if ($script:failures.Count) { throw (($script:failures.Count.ToString() + ' shell-integration fixture(s) failed:') + "`n" + ($script:failures -join "`n")) }
    Write-Output ("Shell integration passed: $script:cases isolated registration cases, $script:assertions assertions. No host registration or settings changes were performed.")
} finally {
    # Delete only the unique directory created by this test invocation.
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureParent)
    $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $resolvedFixture.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($resolvedFixture) -notlike 'cmder-shell-tests-*') { throw 'Refusing unsafe fixture cleanup.' }
    if (Test-Path -LiteralPath $resolvedFixture) { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force }
}

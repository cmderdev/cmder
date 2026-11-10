[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$windows = [Environment]::GetFolderPath([Environment+SpecialFolder]::Windows)
$cmd = Join-Path $windows 'System32\cmd.exe'
$windowsPowerShell = Join-Path $windows 'System32\WindowsPowerShell\v1.0\powershell.exe'
$tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$fixture = Join-Path $tempRoot ("cmder-pwsh-" + [guid]::NewGuid().ToString('N') + " & O'Brien !")
$vendor = Join-Path $fixture 'vendor'
$null = New-Item -ItemType Directory -Path $vendor -Force
$helper = Join-Path $vendor 'start_powershell.cmd'
Copy-Item -LiteralPath (Join-Path $repo 'vendor\start_powershell.cmd') -Destination $helper
[IO.File]::WriteAllText((Join-Path $vendor 'profile.ps1'), 'Write-Output ("PROFILE[" + $PSVersionTable.PSVersion.Major + "]"); [Environment]::Exit(29)')
$assertions = 0
function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ([string]$Actual -cne [string]$Expected) { throw "${Label}: expected '$Expected', got '$Actual'." }
    $script:assertions++
}
function Invoke-Entry([string]$Command, [hashtable]$Environment, [switch]$ProfileCommand) {
    Write-Verbose "Invoking: $Command"
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $cmd
    $info.Arguments = '/d /v:off /s /c "' + $Command + '"'
    if ($ProfileCommand) {
        # Terminals use CreateProcess directly; do not add a second cmd parser.
        $prefix = '"%SystemRoot%\System32\cmd.exe"'
        if (!$Command.StartsWith($prefix)) { throw "Unexpected profile executable: $Command" }
        $info.Arguments = $Command.Substring($prefix.Length)
    }
    $info.WorkingDirectory = $fixture
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.RedirectStandardInput = $true
    foreach ($name in @('ProgramFiles', 'ProgramW6432', 'ProgramFiles(x86)', 'PATH', 'CMDER_ROOT')) {
        $info.EnvironmentVariables.Remove($name)
    }
    $info.EnvironmentVariables['CMDER_USER_CONFIG'] = Join-Path $fixture 'separate config'
    foreach ($name in $Environment.Keys) { $info.EnvironmentVariables[$name] = $Environment[$name] }
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    try {
        $null = $process.Start()
        $process.StandardInput.Close()
        Write-Verbose "Started fixture process $($process.Id)"
        $output = $process.StandardOutput.ReadToEndAsync()
        $errors = $process.StandardError.ReadToEndAsync()
        if (!$process.WaitForExit(45000) -and !$process.HasExited) {
            & (Join-Path $windows 'System32\taskkill.exe') /pid $process.Id /T /F 2>$null | Out-Null
            $process.WaitForExit()
            throw "Shell selection timed out: $Command. Output: $($output.Result) Errors: $($errors.Result)"
        }
        Write-Verbose "Fixture process exited $($process.ExitCode), stdout $($output.Status), stderr $($errors.Status)"
        if ($errors.Result) { throw "Unexpected shell stderr for ${Command}: $($errors.Result)" }
        [pscustomobject]@{ Output = $output.Result.Trim(); ExitCode = $process.ExitCode }
    } finally { $process.Dispose() }
}
function New-Pwsh([string]$RelativePath, [int]$Major = 7) {
    $path = Join-Path $fixture ($RelativePath + '\pwsh.exe')
    $null = New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force
    Copy-Item -LiteralPath (Join-Path $fixture 'probe.exe') -Destination $path
    [IO.File]::WriteAllText(($path + '.major'), [string]$Major)
    return $path
}
function Read-Probe($Result, [string]$ExpectedExecutable) {
    Assert-Equal $Result.ExitCode 37 ("Native exit code propagated for $ExpectedExecutable (output $($Result.Output))")
    $probe = $Result.Output | ConvertFrom-Json
    Assert-Equal $probe.Executable $ExpectedExecutable 'Selected shell'
    Assert-Equal $probe.Directory $fixture 'Working directory preserved'
    Assert-Equal $probe.UserConfig (Join-Path $fixture 'separate config') 'Separate user config preserved'
    return $probe
}

try {
    # Compile a small .NET Framework probe so both test hosts can simulate installs.
    $source = @'
using System;
using System.IO;
using System.Reflection;
using System.Web.Script.Serialization;
public static class Probe {
    public static int Main(string[] args) {
        string exe = Assembly.GetExecutingAssembly().Location;
        foreach (string arg in args) {
            if (arg.Contains("$PSVersionTable"))
                return Int32.Parse(File.ReadAllText(exe + ".major")) >= 7 ? 0 : 1;
        }
        Console.WriteLine(new JavaScriptSerializer().Serialize(new {
            Executable = exe, Arguments = args, Directory = Environment.CurrentDirectory,
            Root = Environment.GetEnvironmentVariable("CMDER_ROOT"),
            Profile = Environment.GetEnvironmentVariable("CMDER_PS_PROFILE"),
            UserConfig = Environment.GetEnvironmentVariable("CMDER_USER_CONFIG")
        }));
        return 37;
    }
}
'@
    [IO.File]::WriteAllText((Join-Path $fixture 'probe.cs'), $source)
    [IO.File]::WriteAllText((Join-Path $fixture 'compile.ps1'), @'
$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'probe.cs') -ReferencedAssemblies System.Web.Extensions -OutputAssembly (Join-Path $PSScriptRoot 'probe.exe') -OutputType ConsoleApplication
'@)
    & $windowsPowerShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $fixture 'compile.ps1')
    if ($LASTEXITCODE) { throw 'Could not compile the shell probe.' }

    $native = New-Pwsh 'Native Program Files\PowerShell\7'
    $x86 = New-Pwsh 'x86 Program Files\PowerShell\7'
    $portable = New-Pwsh 'Portable PowerShell'
    $older = New-Pwsh 'PowerShell 6' 6
    Copy-Item -LiteralPath $portable -Destination (Join-Path $fixture 'pwsh.exe')
    Copy-Item -LiteralPath ($portable + '.major') -Destination (Join-Path $fixture 'pwsh.exe.major')
    $environment = @{ ProgramFiles = (Join-Path $fixture 'x86 Program Files'); ProgramW6432 = (Join-Path $fixture 'Native Program Files'); PATH = (Split-Path $portable -Parent) }
    $probe = Read-Probe (Invoke-Entry ('"' + $helper + '"') $environment) $native
    Assert-Equal $probe.Root $fixture 'Cmder root follows launcher location'
    Assert-Equal $probe.Profile (Join-Path $vendor 'profile.ps1') 'Profile path remains literal'
    Assert-Equal ($probe.Arguments -join '|') '-ExecutionPolicy|Bypass|-NoLogo|-NoProfile|-NoExit|-Command|. $env:CMDER_PS_PROFILE' 'Interactive profile import'

    $probe = Read-Probe (Invoke-Entry ('"' + $helper + '" -File "script & name.ps1" "a b"') @{ 'ProgramFiles(x86)' = (Join-Path $fixture 'x86 Program Files') }) $x86
    Assert-Equal ($probe.Arguments -join '|') '-File|script & name.ps1|a b' 'Native CLI arguments remain separate'
    $probe = Read-Probe (Invoke-Entry ('"' + $helper + '"') @{ PATH = ((Split-Path $older -Parent) + ';' + (Split-Path $portable -Parent)) }) $portable

    foreach ($path in @('', (Split-Path $older -Parent))) {
        $result = Invoke-Entry ('"' + $helper + '" -NoProfile -NonInteractive -Command "Write-Output $PSVersionTable.PSVersion.Major; exit 23"') @{ PATH = $path }
        Assert-Equal $result.Output '5' 'No PowerShell 7 falls back to Windows PowerShell'
        Assert-Equal $result.ExitCode 23 'Fallback exit code propagated'
    }

    # Execute the exact shipped profile commands and their nested quoting.
    $settings = Get-Content -LiteralPath (Join-Path $repo 'vendor\windows_terminal_default_settings.json') -Raw | ConvertFrom-Json
    $null = New-Item -ItemType Directory -Path (Join-Path $vendor 'windows-terminal\settings') -Force
    foreach ($profile in $settings.profiles.list | Where-Object name -like 'Cmder - PowerShell*') {
        $values = @{ ProgramFiles = (Join-Path $fixture 'Native Program Files'); WT_SETTINGS_DIR = (Join-Path $vendor 'windows-terminal\settings') }
        $probe = Read-Probe (Invoke-Entry $profile.commandline $values -ProfileCommand) $native
        Assert-Equal ([IO.Path]::GetFullPath($probe.Profile)) (Join-Path $vendor 'profile.ps1') "$($profile.name) imports Cmder profile"
    }
    [xml]$conemu = Get-Content -LiteralPath (Join-Path $repo 'vendor\ConEmu.xml.default') -Raw
    $null = New-Item -ItemType Directory -Path (Join-Path $vendor 'conemu-maximus5')
    foreach ($task in $conemu.SelectNodes('//key[value[@name="Name" and starts-with(@data,"{PowerShell::")]]')) {
        $command = $task.SelectSingleNode('value[@name="Cmd1"]').data.TrimStart('*')
        $probe = Read-Probe (Invoke-Entry $command @{ ProgramFiles = (Join-Path $fixture 'Native Program Files'); ConEmuDir = (Join-Path $vendor 'conemu-maximus5') } -ProfileCommand) $native
        Assert-Equal ([IO.Path]::GetFullPath($probe.Profile)) (Join-Path $vendor 'profile.ps1') 'ConEmu task imports Cmder profile'
    }
    $alias = Get-Content -LiteralPath (Join-Path $repo 'vendor\user_aliases.cmd.default') | Where-Object { $_.StartsWith('pwsh=') }
    $probe = Read-Probe (Invoke-Entry ($alias.Substring(5).Replace('$*', '-Version')) @{ ProgramFiles = (Join-Path $fixture 'Native Program Files'); CMDER_ROOT = $fixture }) $native
    Assert-Equal ($probe.Arguments -join '|') '-Version' 'pwsh alias forwards CLI arguments'

    # Load a real profile under each installed host without touching user settings.
    $result = Invoke-Entry ('"' + $helper + '"') @{ PATH = '' }
    Assert-Equal $result.Output 'PROFILE[5]' 'Real fallback profile loads'
    Assert-Equal $result.ExitCode 29 'Real fallback profile exit propagated'
    $realPwsh = Get-Command pwsh.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($realPwsh) {
        $result = Invoke-Entry ('"' + $helper + '"') @{ PATH = (Split-Path $realPwsh.Source -Parent) }
        if ($result.Output -notmatch '^PROFILE\[([7-9]|[1-9][0-9]+)\]$') { throw "Real pwsh did not load the profile: $($result.Output)" }
        Assert-Equal $result.ExitCode 29 'Real PowerShell 7 profile exit propagated'
    }
    Write-Host "PowerShell selection tests passed: $assertions assertions."
} catch {
    Write-Host "Shell selection failure: $($_.Exception.Message)"
    throw
} finally {
    $resolvedFixture = [IO.Path]::GetFullPath($fixture)
    if ([IO.Path]::GetDirectoryName($resolvedFixture) -ne $tempRoot) { throw 'Unsafe fixture cleanup path.' }
    if (Test-Path -LiteralPath $resolvedFixture) { Remove-Item -LiteralPath $resolvedFixture -Recurse -Force }
}

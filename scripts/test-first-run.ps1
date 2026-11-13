$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\utils.ps1"
. "$PSScriptRoot\..\vendor\psmodules\FirstRun.ps1"

function Assert-Startup($Condition, [string]$Message) {
    if (-not $Condition) {
        throw $Message
    }
}

$root = Join-Path ([IO.Path]::GetTempPath()) "cmder first run $([guid]::NewGuid())"
$config = Join-Path $root 'config'
$vendor = Join-Path $root 'vendor'
$cmdProfile = Join-Path $config 'user_profile.cmd'
$psProfile = Join-Path $config 'user_profile.ps1'
$gitRoot = Join-Path $vendor 'git-for-windows'
$postInstall = Join-Path $gitRoot 'post-install.bat'

try {
    $null = New-Item -ItemType Directory -Path $cmdProfile, $psProfile, $gitRoot
    $repo = Split-Path -Parent $PSScriptRoot
    foreach ($path in (& git -C $repo ls-files -- vendor)) {
        $destination = Join-Path $root $path
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination))
        [IO.File]::Copy((Join-Path $repo $path), $destination)
    }
    $env:CMDER_ROOT = $root
    $env:CMDER_USER_CONFIG = $null
    $env:CMDER_CONFIGURED = $null
    $env:CMDER_CLINK = '0'
    $env:GIT_INSTALL_ROOT = $null
    $env:HOME = $root

    Push-Location -LiteralPath $root
    try {
        $cmdCommand = 'call vendor\init.cmd /f 2>&1'
        $psCommand = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File vendor\profile.ps1 2>&1'
        $cmdOutput = (& $env:ComSpec /d /c $cmdCommand) -join [Environment]::NewLine
        Assert-Startup ($LASTEXITCODE -eq 1 -and $cmdOutput.Contains("Failed: $cmdProfile")) "Missing CMD setup failure. $cmdOutput"
        $psOutput = (& $env:ComSpec /d /c $psCommand) -join [Environment]::NewLine
        Assert-Startup ($psOutput.Contains("Failed: $psProfile")) "Missing PowerShell setup failure. $psOutput"
        Assert-Startup (-not [IO.File]::Exists((Join-Path $config 'user_init.cmd'))) 'Failed setup created a startup cache.'
        [IO.Directory]::Delete($cmdProfile)
        [IO.Directory]::Delete($psProfile)

        $cmdFirst = (& $env:ComSpec /d /c $cmdCommand) -join [Environment]::NewLine
        Assert-Startup ($LASTEXITCODE -eq 0 -and $cmdFirst.Contains('Created user_profile.cmd')) "CMD retry failed. $cmdFirst"
        $psFirst = (& $env:ComSpec /d /c $psCommand) -join [Environment]::NewLine
        Assert-Startup ($LASTEXITCODE -eq 0 -and $psFirst.Contains('Created user_profile.ps1')) "PowerShell retry failed. $psFirst"

        [IO.File]::AppendAllText($cmdProfile, [Environment]::NewLine + '@echo user-cmd-profile')
        [IO.File]::AppendAllText($psProfile, [Environment]::NewLine + "Write-Output 'user-ps-profile'")
        $cmdRepeat = (& $env:ComSpec /d /c $cmdCommand) -join [Environment]::NewLine
        Assert-Startup ($LASTEXITCODE -eq 0 -and $cmdRepeat.Contains('user-cmd-profile') -and
            -not $cmdRepeat.Contains('Created user_')) "CMD repeat launch failed. $cmdRepeat"
        $psRepeat = (& $env:ComSpec /d /c $psCommand) -join [Environment]::NewLine
        Assert-Startup ($LASTEXITCODE -eq 0 -and $psRepeat.Contains('user-ps-profile') -and
            -not $psRepeat.Contains('Created user_')) "PowerShell repeat launch failed. $psRepeat"
    } finally {
        Pop-Location
    }

    $patch = Get-Content -LiteralPath "$PSScriptRoot\patches\portable-git-post-install.diff"
    $preimage = ($patch | Select-Object -Skip 5 | Where-Object { $_ -match '^[ -]' } |
        ForEach-Object { $_.Substring(1) }) -join [Environment]::NewLine
    [IO.File]::WriteAllText($postInstall, $preimage + [Environment]::NewLine)
    Update-CmderPortableGitPostInstall $gitRoot
    $patched = [IO.File]::ReadAllText($postInstall)
    Assert-Startup ($patched.Contains('@EXIT /B %ERRORLEVEL%')) 'Patched Git setup did not propagate exit status.'
    Assert-Startup (-not $patched.Contains('@DEL post-install.bat')) 'Patched Git script still deletes itself.'

    $source = 'using System; public static class FakeGitCmd { public static int Main() { if (Environment.GetEnvironmentVariable("CMDER_TEST_GIT_FAILURE") == "1") { Console.Error.WriteLine("simulated Git setup diagnostic"); return 17; } return 0; } }'
    Add-Type -OutputAssembly (Join-Path $gitRoot 'git-cmd.exe') -OutputType ConsoleApplication -TypeDefinition $source
    $env:CMDER_TEST_GIT_FAILURE = '1'
    Push-Location -LiteralPath $gitRoot
    try {
        $failedGit = (& $env:ComSpec /d /c 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File ..\bin\first-run.ps1 -Action Git -Target . 2>&1') -join [Environment]::NewLine
    } finally {
        Pop-Location
    }
    Assert-Startup ($LASTEXITCODE -eq 1 -and $failedGit.Contains('simulated Git setup diagnostic') -and
        $failedGit.Contains('exited with code 17')) "Git setup diagnostics or status were lost. $failedGit"
    Assert-Startup ([IO.File]::Exists($postInstall)) 'Git setup removed the script after failure.'

    $env:CMDER_TEST_GIT_FAILURE = $null
    Assert-Startup (Initialize-CmderPortableGit $gitRoot) 'Git setup retry failed.'
    Assert-Startup (-not [IO.File]::Exists($postInstall)) 'Git setup did not remove the script after success.'
    Assert-Startup (Initialize-CmderPortableGit $gitRoot) 'Git setup did not skip an initialized installation.'
} finally {
    if ([IO.Directory]::Exists($root)) {
        [IO.Directory]::Delete($root, $true)
    }
}
Write-Host 'First-run startup tests passed.'
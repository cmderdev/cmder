param(
    [Parameter(Mandatory = $true)]
    [string]$GitRoot
)

$ErrorActionPreference = 'Stop'

function Write-CmderExternalGitHook {
    param([string]$ProfileDir, [string]$Content)

    $hook = Join-Path $ProfileDir 'zz-cmder_exinit.sh'
    foreach ($name in @('zz-cmder_exinit.sh', 'cmder_exinit.sh', 'zz-cmder.sh', 'cmder.sh')) {
        if (Test-Path -LiteralPath (Join-Path $ProfileDir $name)) { return }
    }

    $temp = Join-Path $ProfileDir ('.cmder-exinit-' + [guid]::NewGuid().ToString('N') + '.tmp')
    $created = $false
    try {
        $stream = [IO.File]::Open($temp, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
        $created = $true
        try {
            $bytes = [Text.Encoding]::UTF8.GetBytes($Content)
            $stream.Write($bytes, 0, $bytes.Length)
        } finally {
            $stream.Dispose()
        }
        [IO.File]::Move($temp, $hook)
    } finally {
        if ($created -and [IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
    }
}

function Request-CmderExternalGitHookElevation {
    param([string]$ProfileDir, [string]$Content)

    # Pass the hook as data; the elevated process does not load scripts from the checkout.
    $data = @{ ProfileDir = $ProfileDir; Content = $Content } | ConvertTo-Json -Compress
    $payload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($data))
    $writer = ${function:Write-CmderExternalGitHook}.ToString()
    $command = @"
`$ErrorActionPreference = 'Stop'
`$data = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$payload')) | ConvertFrom-Json
& {
$writer
} -ProfileDir `$data.ProfileDir -Content `$data.Content
"@
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    $powershell = Join-Path ([Environment]::SystemDirectory) 'WindowsPowerShell\v1.0\powershell.exe'
    $process = Start-Process -FilePath $powershell -ArgumentList '-NoLogo', '-NoProfile', '-NonInteractive', '-EncodedCommand', $encoded `
        -WorkingDirectory ([Environment]::SystemDirectory) -Verb RunAs -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Elevated Cmder hook installation failed (exit code $($process.ExitCode))."
    }
}

function Test-CmderExternalGitOptOut {
    param([string]$Content, [string]$Entry)

    $section = ''
    foreach ($line in ($Content -split '\r?\n')) {
        if ($line -match '^[ \t]*\[([^\]]+)\][ \t]*$') {
            $section = $Matches[1]
        } elseif ($section -eq 'external-git-bash-opt-outs' -and $line -eq $Entry) {
            return $true
        }
    }
    return $false
}

function Save-CmderExternalGitOptOut {
    param([string]$ConfigDirectory, [string]$GitRoot, [string]$ComputerName)

    $null = [IO.Directory]::CreateDirectory($ConfigDirectory)
    $path = Join-Path $ConfigDirectory 'user_cmder_state.txt'
    $entry = "$ComputerName`t$GitRoot"
    $stream = [IO.File]::Open($path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8, $true, 1024, $true)
        try {
            $content = $reader.ReadToEnd()
            $encoding = $reader.CurrentEncoding
        } finally {
            $reader.Dispose()
        }
        if (Test-CmderExternalGitOptOut -Content $content -Entry $entry) { return }
        $section = ''
        foreach ($line in ($content -split '\r?\n')) {
            if ($line -match '^[ \t]*\[([^\]]+)\][ \t]*$') {
                $section = $Matches[1]
            }
        }
        $stream.Seek(0, [IO.SeekOrigin]::End) | Out-Null
        $writer = New-Object IO.StreamWriter($stream, $encoding, 1024, $true)
        try {
            if ($content -and !$content.EndsWith("`n")) {
                $writer.WriteLine()
            }
            if ($section -ne 'external-git-bash-opt-outs') {
                $writer.WriteLine('# Each entry is a computer name and external Git path, separated by a tab.')
                $writer.WriteLine('# Cmder will not offer to configure Git Bash for the listed computer and path.')
                $writer.WriteLine('# Remove an entry to allow the offer again.')
                $writer.WriteLine('[external-git-bash-opt-outs]')
            }
            $writer.WriteLine($entry)
        } finally {
            $writer.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}

function Install-CmderExternalGitHook {
    param([string]$GitRoot, [string]$CmderRoot, [string]$UserProfile, [string]$ComputerName = [Environment]::MachineName)

    $profileDir = Join-Path $GitRoot 'etc\profile.d'
    $hook = Join-Path $profileDir 'zz-cmder_exinit.sh'
    if (!(Test-Path -LiteralPath $profileDir -PathType Container)) {
        Write-Warning "Git Bash has no profile directory at '$profileDir'. Set up the Cmder hook manually if needed."
        return
    }
    foreach ($name in @('zz-cmder_exinit.sh', 'cmder_exinit.sh', 'zz-cmder.sh', 'cmder.sh')) {
        if (Test-Path -LiteralPath (Join-Path $profileDir $name)) { return }
    }

    $configDirectory = Join-Path $CmderRoot 'config'
    $optOut = Join-Path $configDirectory 'user_cmder_state.txt'
    $entry = "$ComputerName`t$GitRoot"
    if (Test-Path -LiteralPath $optOut) {
        if (Test-CmderExternalGitOptOut -Content ([IO.File]::ReadAllText($optOut)) -Entry $entry) {
            if ($env:debug_output -match '^[1-9]') {
                Write-Host "[setup_external_git_bash] Skipping the setup offer: '$GitRoot' is opted out in '$optOut'."
            }
            return
        }
    }
    $startup = Join-Path $CmderRoot 'vendor\cmder.sh'
    if (!(Test-Path -LiteralPath $startup -PathType Leaf)) {
        throw "Cannot install the Git Bash hook: Cmder startup script '$startup' is missing."
    }

    Write-Host "External Git Bash at '$GitRoot' is not configured to load Cmder's startup files."
    Write-Host "Installing '$hook' will also enable Cmder in standalone Git Bash for this Windows profile, using '$CmderRoot' when CMDER_ROOT is unset."
    do {
        $answer = ([string](Read-Host 'Install the Cmder hook? [y/N/never] (N = not now)')).Trim()
    } until ($answer -match '^(y|yes|n|no|never)?$')

    if ($answer -eq 'never') {
        Save-CmderExternalGitOptOut -ConfigDirectory $configDirectory -GitRoot $GitRoot -ComputerName $ComputerName
        Write-Host "Saved the opt-out in '$optOut'. Remove this computer and Git path entry to allow the offer again."
        return
    }
    if ($answer -notmatch '^y(es)?$') {
        return
    }

    $source = Join-Path $CmderRoot 'vendor\cmder_exinit'
    $shim = [IO.File]::ReadAllText($source) -replace "`r`n", "`n"
    # Do not use the installer's Cmder path by default in another Windows profile.
    $quotedRoot = "'" + $CmderRoot.Replace("'", "'\''") + "'"
    $quotedProfile = "'" + $UserProfile.Replace("'", "'\''") + "'"
    $assignment = @"
if [ -z "`${CMDER_ROOT:-}" ]; then
  [ "`${USERPROFILE:-}" = $quotedProfile ] || return 0
  CMDER_ROOT=$quotedRoot
fi
"@ -replace "`r`n", "`n"
    $content = "$assignment`n$shim"
    try {
        Write-CmderExternalGitHook -ProfileDir $profileDir -Content $content
    } catch [UnauthorizedAccessException] {
        Write-Host "Administrator permission is required to install the Cmder hook in '$profileDir'."
        Request-CmderExternalGitHookElevation -ProfileDir $profileDir -Content $content
    }
    Write-Host "The Cmder hook is configured in '$profileDir'."
}

if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { return }

if (!$env:USERPROFILE -or !$env:CMDER_ROOT) {
    throw 'External Git Bash setup requires the Cmder root and a Windows user profile.'
}
Install-CmderExternalGitHook -GitRoot $GitRoot -CmderRoot $env:CMDER_ROOT -UserProfile $env:USERPROFILE

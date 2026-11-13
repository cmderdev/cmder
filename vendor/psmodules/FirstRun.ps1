# Shared first-run output for Command Prompt and PowerShell.
function Write-CmderSetupSection([string]$Title) {
    Write-Host ''
    if ([Console]::IsOutputRedirected) {
        Write-Host "=== $Title ==="
    } else {
        Write-Host ("┌─ λ  " + $Title.PadRight(31) + " ─┐") -ForegroundColor Black -BackgroundColor Green
    }
}

function Write-CmderSetupItem([string]$Message) {
    if ([Console]::IsOutputRedirected) {
        Write-Host "  $Message"
    } else {
        Write-Host '│  ' -ForegroundColor DarkGreen -NoNewline
        Write-Host $Message
    }
}

function Write-CmderSetupFailure([string]$Target, [string]$Reason) {
    [Console]::Error.WriteLine("  Failed: $Target")
    [Console]::Error.WriteLine("          $Reason")
}

function Initialize-CmderConfig([string]$Title, [string[]]$Destination, [switch]$Directory, [string]$Template) {
    $shown = $false
    $succeeded = $true
    foreach ($path in $Destination) {
        $name = [IO.Path]::GetFileName($path)
        if (($Directory -and [IO.Directory]::Exists($path)) -or
            (-not $Directory -and [IO.File]::Exists($path))) {
            continue
        }

        if (-not $shown) {
            Write-CmderSetupSection $Title
            Write-CmderSetupItem ([IO.Path]::GetDirectoryName($path))
            $shown = $true
        }

        try {
            if ($Directory) {
                $null = [IO.Directory]::CreateDirectory($path)
            } else {
                $source = $Template
                if (-not $source) {
                    $source = Join-Path $env:CMDER_ROOT "vendor\$name.default"
                }
                [IO.File]::Copy($source, $path, $false)
            }
            Write-CmderSetupItem "Created $name"
        } catch {
            # A second shell may have created the same file since the existence check.
            if (-not $Directory -and [IO.File]::Exists($path)) {
                continue
            }
            Write-CmderSetupFailure $path $_.Exception.GetBaseException().Message
            $succeeded = $false
        }
    }
    return $succeeded
}

function Initialize-CmderPortableGit([string]$GitRoot) {
    $GitRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($GitRoot)
    $postInstall = Join-Path $GitRoot 'post-install.bat'
    if (-not [IO.File]::Exists($postInstall)) {
        return $true
    }

    # Command Prompt, PowerShell and Bash may be opened together as separate tabs.
    $hash = [Security.Cryptography.SHA256]::Create()
    try {
        $identity = [IO.Path]::GetFullPath($GitRoot).TrimEnd('\').ToUpperInvariant()
        $key = [BitConverter]::ToString($hash.ComputeHash([Text.Encoding]::Unicode.GetBytes($identity)))
    } finally {
        $hash.Dispose()
    }
    $mutex = $null
    $ownsMutex = $false
    try {
        $mutex = [Threading.Mutex]::new($false, "Local\CmderPortableGit-$key")
        try {
            $ownsMutex = $mutex.WaitOne()
        } catch [Threading.AbandonedMutexException] {
            # The previous shell exited during setup. This shell now owns the mutex.
            $ownsMutex = $true
        }

        if (-not [IO.File]::Exists($postInstall)) {
            return $true
        }

        Write-CmderSetupSection 'Git for Windows'
        Write-CmderSetupItem 'Running one-time setup'
        $patched = [IO.File]::ReadAllText($postInstall).Contains('@REM Cmder handles post-install cleanup')
        Push-Location -LiteralPath $GitRoot -ErrorAction Stop
        try {
            # Keep the vendor's diagnostics visible, while keeping this function's return value boolean.
            & (Join-Path $GitRoot 'git-cmd.exe') --no-needs-console --no-cd --command=post-install.bat | Out-Host
            $status = $LASTEXITCODE
        } finally {
            Pop-Location
        }

        if ($status -ne 0) {
            throw "Git setup exited with code $status."
        }
        if ($patched) {
            [IO.File]::Delete($postInstall)
        }
        if ([IO.File]::Exists($postInstall)) {
            throw 'The setup file is still present. Check that the Git directory is writable.'
        }
        Write-CmderSetupItem 'Setup complete'
        return $true
    } catch {
        Write-CmderSetupFailure $postInstall $_.Exception.GetBaseException().Message
        return $false
    } finally {
        if ($ownsMutex) {
            $mutex.ReleaseMutex()
        }
        if ($mutex) {
            $mutex.Dispose()
        }
    }
}
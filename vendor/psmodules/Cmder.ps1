function Get-GitVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GitPath
    )

    $gitExecutable = Join-Path $GitPath "git.exe"

    if (-not (Test-Path $gitExecutable)) {
        return $null
    }

    # Execute 'git --version' and capture output
    $gitVersion = & $gitExecutable --version 2>$null

    if ($gitVersion -match 'git version\s+(\S+)') {
        return $Matches[1]
    }

    Write-Debug "Git executable path: $gitExecutable"
    Write-Error "'git --version' returned an improper version string!"
    Write-Error "Unable to determine Git version from output: $gitVersion"

    return $null
}

function Get-GitShimPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GitPath
    )
    # Check if there is a shim file - if yes, read the actual executable path
    # See: github.com/ScoopInstaller/Shim

    $shimFile = Join-Path $GitPath "git.shim"
    if (Test-Path $shimFile) {
        $shimContent = Get-Content $shimFile -Raw
        if ($shimContent -match '^\s*path\s*=\s*(.+)\s*$') {
            $GitPath = $Matches[1].Trim().Replace('\git.exe', '')
        }
    }

    return $GitPath
}

function Compare-Version {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$UserVersion,
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$VendorVersion
    )

    if ([string]::IsNullOrEmpty($UserVersion)) { return -1 }
    if ([string]::IsNullOrEmpty($VendorVersion)) { return 1 }

    # Split version strings by dots to compare segment by segment
    # For "2.49.0.windows.1", we get: ["2", "49", "0", "windows", "1"]
    $userParts = $UserVersion -split '\.'
    $vendorParts = $VendorVersion -split '\.'

    $maxLength = [Math]::Max($userParts.Count, $vendorParts.Count)

    for ($i = 0; $i -lt $maxLength; $i++) {
        $userPart = if ($i -lt $userParts.Count) { $userParts[$i] } else { '' }
        $vendorPart = if ($i -lt $vendorParts.Count) { $vendorParts[$i] } else { '' }

        # Check if both parts are purely numeric
        $userIsNumeric = $userPart -match '^\d+$'
        $vendorIsNumeric = $vendorPart -match '^\d+$'

        if ($userIsNumeric -and $vendorIsNumeric) {
            # Both numeric: compare as integers (so 49 > 5, not lexicographic)
            $userNum = [int]$userPart
            $vendorNum = [int]$vendorPart

            if ($userNum -gt $vendorNum) { return 1 }
            if ($userNum -lt $vendorNum) { return -1 }
        }
        elseif ($userIsNumeric -and -not $vendorIsNumeric) {
            # Numeric segment comes before text segment (e.g., "2.0" < "2.0.rc1")
            return -1
        }
        elseif (-not $userIsNumeric -and $vendorIsNumeric) {
            # Text segment comes after numeric segment
            return 1
        }
        else {
            # Both are text: use case-insensitive lexicographic comparison
            $cmp = [string]::Compare($userPart, $vendorPart, $true)
            if ($cmp -ne 0) { return [Math]::Sign($cmp) }
        }
    }

    return 0
}

function Compare-GitVersion {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$UserVersion,
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$VendorVersion
    )

    $result = Compare-Version -UserVersion $UserVersion -VendorVersion $VendorVersion

    Write-Debug "Compare Versions Result: $result"
    if ($result -ge 0) {
        return $UserVersion
    }
    return $VendorVersion
}

function Set-GitPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GitRoot,
        [Parameter(Mandatory = $true)]
        [string]$GitType,
        [Parameter(Mandatory = $false)]
        [string]$GitPathUser
    )

    # Proposed Behavior

    # Modify the path if we are using VENDORED Git, do nothing if using USER Git.
    # If User Git is installed but is older, match its path config adding paths
    # in the same path positions allowing a user to configure Cmder Git path
    # using locally installed Git Path Config.

    if ($GitType -ne 'VENDOR') {
        return $env:Path
    }

    $newPath = $env:Path

    # Replace user Git path with vendored Git if user path exists
    if ($GitPathUser) {
        Write-Verbose "Cmder 'profile.ps1': Replacing older user Git path '$GitPathUser' with newer vendored Git path '$GitRoot' in the system path..."
        $newPath = $newPath -ireplace [regex]::Escape($GitPathUser), $GitRoot
    } else {
        # Add Git cmd directory to the path
        $gitCmd = Join-Path $GitRoot "cmd"
        if (-not ($newPath -match [regex]::Escape($gitCmd))) {
            Write-Debug "Adding $gitCmd to the path"
            $newPath = "$gitCmd;$newPath"
        }

        # Add mingw[32|64]\bin directories to the path, if they exist and not already present
        # Prefer mingw64 on 64-bit systems, mingw32 on 32-bit systems
        $is64Bit = [Environment]::Is64BitOperatingSystem
        $mingwDirs = if ($is64Bit) { @('mingw64', 'mingw32') } else { @('mingw32') }

        foreach ($mingw in $mingwDirs) {
            $mingwBin = Join-Path $GitRoot "$mingw\bin"
            if ((Test-Path $mingwBin) -and -not ($newPath -match [regex]::Escape($mingwBin))) {
                Write-Debug "Adding $mingwBin to the path"
                $newPath = "$newPath;$mingwBin"
                break
            }
        }

        # Add usr\bin directory to the path
        $usrBin = Join-Path $GitRoot "usr\bin"
        if ((Test-Path $usrBin) -and -not ($newPath -match [regex]::Escape($usrBin))) {
            Write-Debug "Adding $usrBin to the path"
            $newPath = "$newPath;$usrBin"
        }
    }

    return $newPath
}

function Import-Git {
    $gitModule = Get-Module -Name Posh-Git -ListAvailable

    if (-not $gitModule) {
        Microsoft.PowerShell.Utility\Write-Host -NoNewline "`r`n"
        Write-Warning "Missing git support, install posh-git with 'Install-Module posh-git' and restart Cmder."
        Microsoft.PowerShell.Utility\Write-Host -NoNewline "`r$([char]0x1B)[A"
        return $false
    }

    # Import posh-git module (works for all versions)
    Import-Module Posh-Git -ErrorAction SilentlyContinue | Out-Null

    # Apply version-specific settings for posh-git 1.0.0+
    if (($gitModule.Version -ge [version]"1.0.0") -and (Get-Variable -Name GitPromptSettings -ErrorAction SilentlyContinue)) {
        $GitPromptSettings.AnsiConsole = $false
    }

    return $true
}

function Show-GitStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return
    }

    $gitDir = Join-Path $Path '.git'
    if (-not (Test-Path $gitDir)) {
        $parentPath = Split-Path $Path
        if ($parentPath) {
            Show-GitStatus -Path $parentPath
        }
        return
    }

    if (Get-GitStatusSetting) {
        if ($null -eq $env:gitLoaded) {
            $env:gitLoaded = Import-Git
        }
        if ($env:gitLoaded -eq $true) {
            Write-VcsStatus
        }
    } else {
        $headFile = Join-Path $gitDir 'HEAD'
        if (Test-Path $headFile) {
            $headContent = Get-Content $headFile -Raw
            if ($headContent -match 'ref: refs/heads/(.+)') {
                $branchName = $Matches[1].Trim()
            } else {
                $shortHash = $headContent.Substring(0, [Math]::Min(7, $headContent.Length))
                $branchName = "HEAD detached at $shortHash"
            }
            Microsoft.PowerShell.Utility\Write-Host " [$branchName]" -NoNewline -ForegroundColor White
        }
    }
}

function Get-GitStatusSetting {
    $gitConfig = git --no-pager config -l 2>$null | Out-String

    # Check if git status display is disabled via config
    # Matches: cmder.status=false or cmder.psstatus=false (PowerShell-specific)
    if ($gitConfig -match '(?m)^cmder\.(ps)?status=false$') {
        return $false
    }

    return $true
}

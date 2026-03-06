<#
.SYNOPSIS
Integrate Cmder into the system and optionally add Cmder VS Code terminal profiles.

.DESCRIPTION
This script can perform three primary actions:
- Add/merge Cmder terminal profiles into VS Code's `terminal.integrated.profiles.windows` (when `-VSCode` is used).
- Set the user environment variable `CMDER_ROOT` (when `-SetRootEnv` is used).
- Prepend `CMDER_ROOT` to the user's `Path` variable (when `-PrependPath` is used).

The script attempts to discover a VS Code `settings.json` when `-SettingsJsonPath` is not provided. It will
only create a timestamped backup and write `settings.json` if the merged JSON differs from the original.

.PARAMETER VSCode
Switch to enable adding/merging Cmder profiles into VS Code `settings.json`. Defaults to enabled if the `code` command is found in the PATH.

.PARAMETER SetRootEnv
Switch to set the user environment variable `CMDER_ROOT` (if missing). Defaults to enabled.

.PARAMETER PrependPath
Switch to prepend `CMDER_ROOT` to the user's `Path` (if `cmder.exe` is not already on the Path). Defaults to enabled.

.PARAMETER CmderRoot
Path to the Cmder installation root. Defaults to the `CMDER_ROOT` environment variable if present, otherwise the current directory.

.PARAMETER DefaultProfile
Optional name of the Cmder profile to set as the default VS Code terminal profile. Valid values: 'Cmder - Cmd', 'Cmder - PowerShell', 'Cmder - Bash'.

.PARAMETER Confirm
When supplied, the script will skip the interactive confirmation prompt and proceed non-interactively. If omitted the script prompts in the terminal (default behavior).

.PARAMETER SettingsJsonPath
Explicit path to the VS Code `settings.json` to modify. If omitted the script attempts to discover a suitable file under common locations.

.EXAMPLE
# Dry-run / test (read-only):
.
.\vendor\bin\Add-CmderVSCodeProfiles.ps1 -SettingsJsonPath "$env:APPDATA\Code\User\settings.json" -Confirm

.EXAMPLE
# Interactive use (default):
.
.\vendor\bin\Add-CmderVSCodeProfiles.ps1 -SettingsJsonPath "$env:APPDATA\Code\User\settings.json"

.NOTES
- The script writes a timestamped backup only when changes are required.
- It uses a terminal prompt (`Read-Host`) for confirmation unless `-Confirm` is provided.
- It requires appropriate permissions to modify the user's registry environment variables and to write the `settings.json` file.
Script: vendor/bin/Add-CmderVSCodeProfiles.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)][switch]$VSCode = $true,

    [Parameter(Mandatory=$false)][switch]$SetRootEnv = $true,

    [Parameter(Mandatory=$false)][switch]$PrependPath = $true,

    [Parameter(Mandatory=$false)]
    # default $CmderRoot to the environment variable CMDER_ROOT if set, otherwise to the current directory
    [string]$CmderRoot = $env:CMDER_ROOT ? $env:CMDER_ROOT : (Get-Location).ProviderPath,

    [Parameter(Mandatory=$false)]
    [string]$DefaultProfile,

    [Parameter(Mandatory=$false)][switch]$Confirm,

    [Parameter(Mandatory=$false)]
    [string]$SettingsJsonPath
)

if (-not (get-command 'code')) {
    Write-Error "VS Code command 'code' not found in PATH. Ensure VS Code is installed and 'code' is available in the command line."
    $VSCode = $false 
}


if ($VSCode -and $DefaultProfile) {
    if ($DefaultProfile -notin @('Cmder - Cmd','Cmder - PowerShell','Cmder - Bash').Contains($DefaultProfile)) {
        Write-Error "Invalid value for -DefaultProfile: '$DefaultProfile'. Valid options are 'Cmder - Cmd', 'Cmder - PowerShell', or 'Cmder - Bash'."
        exit 1
    }   
}

function Merge-ProfilesToObject($target) {
    # Collect existing profiles into a plain hashtable (handle IDictionary or PSCustomObject)
    $combined = @{}
    $existing = $null
    if ($target.PSObject.Properties.Name -contains $propName) {
        $existing = $target.PSObject.Properties[$propName].Value
    }
    if ($existing -ne $null) {
        if ($existing -is [System.Collections.IDictionary]) {
            foreach ($k in $existing.Keys) { $combined[$k] = $existing[$k] }
        } else {
            foreach ($p in $existing.PSObject.Properties) { $combined[$p.Name] = $p.Value }
        }
    }

    # Overlay/insert Cmder profiles — only add profiles that don't already exist
    foreach ($k in $cmderProfiles.Keys) {
        if ($combined.ContainsKey($k)) {
            Write-Output "- Skipping existing profile '$k'!"
        } else {
            $combined[$k] = $cmderProfiles[$k]
            Write-Output "- Adding missing profile '$k'"
        }
    }

    # Create an ordered hashtable with keys sorted alphabetically
    $ordered = [ordered]@{}
    foreach ($k in ($combined.Keys | Sort-Object)) { $ordered[$k] = $combined[$k] }

    # Remove any existing literal property with the dotted name, then re-add as a note property
    if ($target.PSObject.Properties.Name -contains $propName) {
        $target.PSObject.Properties.Remove($propName)
    }
    $target | Add-Member -NotePropertyName $propName -NotePropertyValue $ordered -Force

    # If a default profile was requested and exists in the ordered set, set the default profile
    if ($DefaultProfile) {
        $defaultPropName = 'terminal.integrated.defaultProfile.windows'
        if ($ordered.Keys -contains $DefaultProfile) {
            if ($target.$defaultPropName -ne $DefaultProfile) {
                if ($target.PSObject.Properties.Name -contains $defaultPropName) { $target.PSObject.Properties.Remove($defaultPropName) }
                $target | Add-Member -NotePropertyName $defaultPropName -NotePropertyValue $DefaultProfile -Force
                Write-Output "- Setting default profile to '$DefaultProfile'"
            }
            else {
                Write-Output "- '$DefaultProfile' is already set as the default, no change needed."
            }
        }
        else {
            Write-Output "- Default profile '$DefaultProfile' not found in profiles list, skipping default profile set."
        }
    }
}

if ($VSCode -and -not $SettingsJsonPath) {
    # If the user didn't provide a path, try to discover a VS Code `settings.json` under %APPDATA% and common roots
    if (-not $SettingsJsonPath) {
        $candidates = @()
        $roots = @()
        if ($env:APPDATA) { $roots += $env:APPDATA }
        if ($env:LOCALAPPDATA) { $roots += $env:LOCALAPPDATA }
        if ($env:USERPROFILE) { $roots += $env:USERPROFILE }
        if ($env:ProgramFiles) { $roots += $env:ProgramFiles }
        if (${env:ProgramFiles(x86)}) { $roots += ${env:ProgramFiles(x86)} }

        foreach ($root in $roots | Select-Object -Unique) {
            if (-not (Test-Path $root)) { continue }
            try {
                $found = Get-ChildItem -Path $root -Recurse -Filter settings.json -ErrorAction SilentlyContinue -Force
                if ($found) { $candidates += $found }
            } catch {}
        }

        $candidate = $candidates | Where-Object {
            $_.FullName -match '\\User\\settings.json$' -and (
                $_.FullName -match '\\Code( | - |\\)' -or
                $_.FullName -match '\\data\\' -or
                $_.FullName -match 'vscode' -or
                $_.FullName -match 'Code -'
            )
        } | Select-Object -First 1

        if (-not $candidate) {
            $common = @(
                Join-Path $env:APPDATA 'Code\\User\\settings.json',
                Join-Path $env:APPDATA 'Code - Insiders\\User\\settings.json',
                Join-Path $env:APPDATA 'Code - OSS\\User\\settings.json'
            )
            foreach ($p in $common) { if (Test-Path $p) { $candidate = Get-Item $p; break } }
        }

        if ($candidate) {
            $SettingsJsonPath = $candidate.FullName
        } else {
            Write-Error "Could not discover a VS Code 'settings.json' (installed or portable). Provide -SettingsJsonPath explicitly."
            exit 3
        }
    }

    $SettingsJsonPath = (Resolve-Path -LiteralPath $SettingsJsonPath).ProviderPath
}

$CmderRoot = (Resolve-Path -LiteralPath $CmderRoot)

Write-Output "Configuration Summary:`n"

if ($VSCode) {
    Write-Output "Add Missing VS Code Terminal Profiles: $SettingsJsonPath"

    if ($DefaultProfile) {
        Write-Output "Set Default VS Code Terminal Profile:  $DefaultProfile"
    }
}

if ($SetRootEnv) {
    Write-Output "Add CMDER_ROOT environment variable:   Yes (if not already present)"
}

if ($PrependPath) {
    Write-Output "Prepend CMDER_ROOT to User Path:       Yes (if not already present)"
}

if (-not $Confirm) {
    # Prompt the user in the terminal (Read-Host) before making changes — default: No
    $prompt = "`nDo you want to continue? [y/N]"
    $answer = Read-Host -Prompt $prompt
    if (-not $answer) { $answer = 'N' }
    if ($answer.ToLower() -notin @('y','yes')) {
        Write-Output "Cmder System Integration cancelled by user input. No changes were made."
        exit 2
    }
}

if ($SetRootEnv) {
    Write-Output "`nEnvironment Changes:`n"

    # Set user environment variable CMDER_ROOT if not already set in the registry.
    $didSet = $false
    $regPath = 'HKCU:\Environment'
    $regVal = $null
    $prop = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
    if ($prop -ne $null -and $prop.PSObject.Properties.Name -contains 'CMDER_ROOT') { $regVal = $prop.CMDER_ROOT }
    if ([string]::IsNullOrEmpty($regVal)) {
        Write-Output "- No CMDER_ROOT found in registry; will write HKCU:\Environment\CMDER_ROOT -> $CmderRoot"
        [Environment]::SetEnvironmentVariable('CMDER_ROOT', $CmderRoot, 'User')
        $didSet = $true
    }
    else {
        Write-Output "- User environment variable 'CMDER_ROOT' already exists in registry with value '$regVal', skipping set."
    }

    $env:CMDER_ROOT = $CmderRoot
}

if ($PrependPath) {
    write-Output "`nPath Changes:`n"
    # Prepend $ENV:CMDER_ROOT to the current users Path variable if not already present
    if ((get-command 'cmder.exe' -ErrorAction SilentlyContinue) -eq $null) {
        Write-Output "- 'cmder.exe' not found in current PATH, checking registry user Path variable..."
        $pathVal = $null
        if ($prop -ne $null -and $prop.PSObject.Properties.Name -contains 'Path') { $pathVal = $prop.Path }
        if ($pathVal -ne $null -and -not ($pathVal.Split(';') -contains $env:CMDER_ROOT)) {
            Write-Output "- Prepending '$env:CMDER_ROOT' to user Path environment variable in registry."
            $newPath = "$env:CMDER_ROOT;$pathVal"
            [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        }
    }
    else {
        $CmderPath = (Get-Command 'cmder.exe' -ErrorAction SilentlyContinue).Source
        Write-Output "- 'cmder.exe' found in current PATH at '$CmderPath', skipping Path modification."
    }
}

if ($VSCode) {
    $cmderProfiles = @{}

    if (($DefaultProfile -eq 'Cmder - Cmd') -or $VSCode) {
        $cmderProfiles['Cmder - Cmd'] = @{
            name = 'Cmder - Cmd'
            path = @('${env:windir}\Sysnative\cmd.exe','${env:windir}\System32\cmd.exe')
            args = @('/k','${env:cmder_root}\vendor\bin\vscode_init.cmd')
            icon = 'terminal-cmd'
            color = 'terminal.ansiGreen'
        }
    }
    
    if (($DefaultProfile -eq 'Cmder - PowerShell') -or $VSCode) {
        $cmderProfiles['Cmder - PowerShell'] = @{
            name = 'Cmder - PowerShell'
            source = 'PowerShell'
            args = @('-ExecutionPolicy','Bypass','-NoLogo','-NoProfile','-NoExit','-Command','Invoke-Expression ''. ''''${env:CMDER_ROOT}\vendor\profile.ps1''''''')
            icon = 'terminal-powershell'
            color = 'terminal.ansiYellow'
        }
    }
    
    if (($DefaultProfile -eq 'Cmder - Bash') -or $VSCode) {
        $cmderProfiles['Cmder - Bash'] = @{
            name = 'Cmder - Bash'
            path = @('${env:windir}\Sysnative\cmd.exe','${env:windir}\System32\cmd.exe')
            args = @('/k','${env:cmder_root}\vendor\start_git_bash.cmd')
            icon = 'terminal-bash'
            color = 'terminal.ansiBlue'
        }
    }

    Write-Output "`nProfile Changes:`n"
    Write-Output "Reading '$SettingsJsonPath'...`n"
    $raw = Get-Content -Raw -Path $SettingsJsonPath -ErrorAction Stop
    try {
        $json = $raw | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Error "Failed to parse JSON in $($SettingsJsonPath): $_"
        exit 3
    }

    # Normalized copy of original JSON for change detection
    $originalNormalized = $json | ConvertTo-Json -Depth 10

    # Write-Output "Preparing to merge Cmder profiles into settings"
    $propName = 'terminal.integrated.profiles.windows'

    if ($json -is [System.Array]) {
        foreach ($item in $json) { Merge-ProfilesToObject $item }
    } else {
        Merge-ProfilesToObject $json
    }

    # Compare normalized JSON and only back up / write if changes occurred
    $newNormalized = $json | ConvertTo-Json -Depth 10
    if ($originalNormalized -ne $newNormalized) {
        $timestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
        $backup = "$SettingsJsonPath.$timestamp.backup"
        Write-Output "- Backing up 'settings.json' to '$backup' before applying changes..."
        Copy-Item -Path $SettingsJsonPath -Destination $backup -Force

        $pretty = $json | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($SettingsJsonPath, $pretty, [System.Text.Encoding]::UTF8)
        Write-Output "- Backed up original to $backup"
        Write-Output "- Added Cmder profiles into property '$propName' in $SettingsJsonPath"
        Write-Output "`nApplied changes to '$SettingsJsonPath'..."
    } else {
        Write-Output "`nAll VS Code terminal profiles are already configured in '$SettingsJsonPath'. No changes were made."
    }
}

# Init Script for PowerShell
# Created as part of Cmder project
# NOTE: This file must be saved using UTF-8 with BOM encoding for prompt symbol to work correctly.

# !!! THIS FILE IS OVERWRITTEN WHEN CMDER IS UPDATED
# !!! Use "%CMDER_ROOT%\config\user_profile.ps1" to add your own startup commands

$CMDER_INIT_START = Get-Date

# Determine the script root if not already set
if (!$PSScriptRoot) {
    $PSScriptRoot = Split-Path $Script:MyInvocation.MyCommand.Path
}

# We do this for Powershell as Admin Sessions because CMDER_ROOT is not being set.
if (!$ENV:CMDER_ROOT) {
    if ($ENV:ConEmuDir) {
        $ENV:CMDER_ROOT = Resolve-Path($ENV:ConEmuDir + "\..\..")
    } else {
        $ENV:CMDER_ROOT = Resolve-Path($PSScriptRoot + "\..")
    }
}

# Remove trailing '\'
$ENV:CMDER_ROOT = ($ENV:CMDER_ROOT).TrimEnd("\")

# Recent PowerShell versions include PowerShellGet out of the box
$moduleInstallerAvailable = [bool](Get-Command -Name 'Install-Module' -ErrorAction SilentlyContinue)

# Enable Debug and Verbose output if CMDER_DEBUG environment variable is set to '1' or 'true'
if ($env:CMDER_DEBUG -and ($env:CMDER_DEBUG -match '^(1|true)$')) {
    $DebugPreference = 'Continue'
    $VerbosePreference = 'Continue'
}

# Add Cmder modules directory to the autoload path.
$CmderModulePath = Join-path $PSScriptRoot "psmodules/"

# Import Cmder functions
$CmderFunctions  = Join-Path $CmderModulePath "Cmder.ps1"
. $CmderFunctions

# Configure PSModulePath to include Cmder modules if not already present
if (-not $moduleInstallerAvailable -and -not $env:PSModulePath.Contains($CmderModulePath) ) {
    $env:PSModulePath = $env:PSModulePath.Insert(0, "$CmderModulePath;")
}

if ($env:CMDER_USER_CONFIG) {
    Write-Verbose "CMDER IS ALSO USING INDIVIDUAL USER CONFIG FROM '$ENV:CMDER_USER_CONFIG'!"
}

# Read vendored Git Version
$gitVendorPath = Join-Path $ENV:CMDER_ROOT 'vendor\git-for-windows\cmd'
$gitVersionVendor = Get-GitVersion -GitPath $gitVendorPath
if (-not [string]::IsNullOrEmpty($gitVersionVendor)) {
    Write-Debug "GIT VENDOR: ${gitVersionVendor}"
} else {
    Write-Debug "GIT VENDOR is not present at '$gitVendorPath'"
}

# Get user installed Git version(s) if found, and compare them with vendored version.
foreach ($git in (Get-Command -ErrorAction SilentlyContinue 'git')) {
    Write-Debug "GIT USER PATH: $($git.Path)"
    $gitDir = Split-Path -Path $git.Path
    $gitDir = Get-GitShimPath -GitPath $gitDir
    $gitVersionUser = Get-GitVersion -GitPath $gitDir
    Write-Debug "GIT USER VERSION: ${gitVersionUser}"

    $useGitVersion = Compare-GitVersion -UserVersion $gitVersionUser -VendorVersion $gitVersionVendor
    Write-Debug "Using Git Version: ${useGitVersion}"

    # Use user installed Git
    if ($null -eq $gitPathUser) {
        Write-Debug "Detected Git from mingw bin directory"
        Write-Debug "Git Dir: ${gitDir}"
        if ($gitDir -match '\\mingw32\\bin' -or $gitDir -match '\\mingw64\\bin') {
            $gitPathUser = $gitDir.subString(0, $gitDir.Length - 12)
        } else {
            $gitPathUser = $gitDir.subString(0, $gitDir.Length - 4)
        }
        Write-Debug "Git Path User: ${gitDir}"
    }

    if ($useGitVersion -eq $gitVersionUser) {
        Write-Debug "Using Git Dir: ${gitDir}"
        $ENV:GIT_INSTALL_ROOT = $gitPathUser
        $ENV:GIT_INSTALL_TYPE = 'USER'
        break
    }
}

# Use vendored Git if no user Git found or user Git is older than vendored Git
if ($null -eq $ENV:GIT_INSTALL_ROOT -and $null -ne $gitVersionVendor) {
    $ENV:GIT_INSTALL_ROOT = "$ENV:CMDER_ROOT\vendor\git-for-windows"
    $ENV:GIT_INSTALL_TYPE = 'VENDOR'
}

Write-Debug "GIT_INSTALL_ROOT: ${ENV:GIT_INSTALL_ROOT}"
Write-Debug "GIT_INSTALL_TYPE: ${ENV:GIT_INSTALL_TYPE}"

if ($null -ne $ENV:GIT_INSTALL_ROOT) {
    $env:Path = Set-GitPath -GitRoot "$ENV:GIT_INSTALL_ROOT" -GitType $ENV:GIT_INSTALL_TYPE -GitPathUser $gitPathUser
}

# Create 'vi' alias for 'vim' if vim is available
if (Get-Command -Name "vim" -ErrorAction SilentlyContinue) {
    New-Alias -name "vi" -value vim
}

# PSReadline configuration
if (Get-Module PSReadline -ErrorAction "SilentlyContinue") {
    # Display an extra prompt line between the prompt and the command input
    Set-PSReadlineOption -ExtraPromptLineCount 1

    # Invoked when Enter is pressed to submit a command
    if ($env:WT_SESSION) {
        Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
            # Get the current command line
            $line = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

            # Accept the line first
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()

            # Emit OSC 133;C to mark start of command output
            # This is written directly to the console after the command is accepted
            [Console]::Write("$([char]0x1B)]133;C$([char]7)")
        }
    }
}

# Pre-assign default prompt hooks so the first run of Cmder gets a working prompt
$env:gitLoaded = $null
[ScriptBlock]$PrePrompt = {}
[ScriptBlock]$PostPrompt = {}
[ScriptBlock]$CmderPrompt = {
    # Check if we're currently running under Admin privileges
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    $color = "White"
    if ($principal.IsInRole($adminRole)) { $color = "Red" }
    $Host.UI.RawUI.ForegroundColor = "White"
    Microsoft.PowerShell.Utility\Write-Host "PS " -NoNewline -ForegroundColor $color
    Microsoft.PowerShell.Utility\Write-Host $pwd.ProviderPath -NoNewLine -ForegroundColor Green
    Show-GitStatus -Path $pwd.ProviderPath
    Microsoft.PowerShell.Utility\Write-Host "`nλ" -NoNewLine -ForegroundColor "DarkGray"
}

# Enhance Path
$env:Path = "$Env:CMDER_ROOT\bin;$Env:CMDER_ROOT\vendor\bin;$env:Path;$Env:CMDER_ROOT"

# Drop *.ps1 files into "$ENV:CMDER_ROOT\config\profile.d"
# to source them at startup.
if (-not (Test-Path -PathType container "$ENV:CMDER_ROOT\config\profile.d")) {
    New-Item -ItemType Directory -Path "$ENV:CMDER_ROOT\config\profile.d"
}

Push-Location $ENV:CMDER_ROOT\config\profile.d
foreach ($x in Get-ChildItem *.psm1) {
    Write-Verbose "Sourcing $x"
    Import-Module $x
}
foreach ($x in Get-ChildItem *.ps1) {
    Write-Verbose "Sourcing $x"
    . $x
}
Pop-Location

# Drop *.ps1 files into "$ENV:CMDER_USER_CONFIG\config\profile.d"
# to source them at startup.  Requires using cmder.exe /C [cmder_user_root_path] argument
if ($ENV:CMDER_USER_CONFIG -ne "" -and (Test-Path "$ENV:CMDER_USER_CONFIG\profile.d")) {
    Push-Location $ENV:CMDER_USER_CONFIG\profile.d
    foreach ($x in Get-ChildItem *.psm1) {
        Write-Verbose "Sourcing $x"
        Import-Module $x
    }
    foreach ($x in Get-ChildItem *.ps1) {
        Write-Verbose "Sourcing $x"
        . $x
    }
    Pop-Location
}

# Renaming to "config\user_profile.ps1" to "user_profile.ps1" for consistency.
if (Test-Path "$env:CMDER_ROOT\config\user-profile.ps1") {
    Rename-Item  "$env:CMDER_ROOT\config\user-profile.ps1" user_profile.ps1
}

$CmderUserProfilePath = Join-Path $env:CMDER_ROOT "config\user_profile.ps1"
if (Test-Path $CmderUserProfilePath) {
    # Create this file and place your own command in there.
    . "$CmderUserProfilePath" # user_profile.ps1 is not a module DO NOT USE import-module
}

if ($ENV:CMDER_USER_CONFIG) {
    # Renaming to "$env:CMDER_USER_CONFIG\user-profile.ps1" to "user_profile.ps1" for consistency.
    if (Test-Path "$env:CMDER_USER_CONFIG\user-profile.ps1") {
        Rename-Item  "$env:CMDER_USER_CONFIG\user-profile.ps1" user_profile.ps1
    }

    $env:Path = "$Env:CMDER_USER_CONFIG\bin;$env:Path"

    $CmderUserProfilePath = Join-Path $ENV:CMDER_USER_CONFIG "user_profile.ps1"
    if (Test-Path $CmderUserProfilePath) {
        . "$CmderUserProfilePath" # user_profile.ps1 is not a module DO NOT USE import-module
    }
}

if (-not (Test-Path $CmderUserProfilePath)) {
    $CmderUserProfilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CmderUserProfilePath)
    Write-Host -NoNewline "`r"
    Write-Host -BackgroundColor Green -ForegroundColor Black "First Run: Creating user startup file: $CmderUserProfilePath"
    Copy-Item "$env:CMDER_ROOT\vendor\user_profile.ps1.default" -Destination $CmderUserProfilePath
}

#
# Prompt Section
#   Users should modify their user_profile.ps1 as it will be safe from updates.
#

# Only set the prompt if it is currently set to the default
# This allows users to configure the prompt in their user_profile.ps1 or config\profile.d\*.ps1
if ( $(Get-Command prompt).Definition -match 'PS \$\(\$executionContext.SessionState.Path.CurrentLocation\)\$\(' -and `
    $(Get-Command prompt).Definition -match '\(\$nestedPromptLevel \+ 1\)\) ";') {

    <#
    This scriptblock runs every time the prompt is returned.
    Explicitly use functions from MS namespace to protect from being overridden in the user session.
    Custom prompt functions are loaded in as constants to get the same behaviour
    #>
    [ScriptBlock]$Prompt = {
        $lastSUCCESS = $?
        $realLastExitCode = $LastExitCode

        # Terminal-specific escape sequences for Windows Terminal and ConEmu
        if ($env:WT_SESSION -or $env:ConEmuPID) {
            # Emit OSC 133;D to mark the end of command execution with exit code
            if ($env:WT_SESSION) {
                Microsoft.PowerShell.Utility\Write-Host -NoNewline "$([char]0x1B)]133;D;$realLastExitCode$([char]7)"
            }

            # Emit OSC 9;9 to enable directory tracking
            # Enables "Duplicate Tab" and "Split Pane" to preserve the working directory
            $loc = $executionContext.SessionState.Path.CurrentLocation
            if ($loc.Provider.Name -eq "FileSystem") {
                Microsoft.PowerShell.Utility\Write-Host -NoNewline "$([char]0x1B)]9;9;`"$($loc.ProviderPath)`"$([char]0x1B)\"
            }

            # Emit OSC 133;A to mark the start of the prompt
            # Enables features like command navigation, selection, and visual separators
            if ($env:WT_SESSION) {
                Microsoft.PowerShell.Utility\Write-Host -NoNewline "$([char]0x1B)]133;A$([char]7)"
            }
        }

        $host.UI.RawUI.WindowTitle = Microsoft.PowerShell.Management\Split-Path $pwd.ProviderPath -Leaf
        Microsoft.PowerShell.Utility\Write-Host -NoNewline "$([char]0x200B)`r$([char]0x1B)[K"
        if ($lastSUCCESS -or ($LastExitCode -ne 0)) {
            Microsoft.PowerShell.Utility\Write-Host
        }
        PrePrompt | Microsoft.PowerShell.Utility\Write-Host -NoNewline
        CmderPrompt
        PostPrompt | Microsoft.PowerShell.Utility\Write-Host -NoNewline

        # Emit OSC 133;B to mark the start of command input (after prompt, before user types)
        if ($env:WT_SESSION) {
            Microsoft.PowerShell.Utility\Write-Host -NoNewline "$([char]0x1B)]133;B$([char]7)"
        }

        $global:LastExitCode = $realLastExitCode
        return " "
    }

    # Once Created these code blocks cannot be overwritten
    # if (-not $(Get-Command PrePrompt).Options   -match 'Constant') {Set-Item -Path function:\PrePrompt   -Value $PrePrompt   -Options Constant}
    # if (-not $(Get-Command CmderPrompt).Options -match 'Constant') {Set-Item -Path function:\CmderPrompt -Value $CmderPrompt -Options Constant}
    # if (-not $(Get-Command PostPrompt).Options  -match 'Constant') {Set-Item -Path function:\PostPrompt  -Value $PostPrompt  -Options Constant}

    Set-Item -Path function:\PrePrompt   -Value $PrePrompt   -Options Constant
    Set-Item -Path function:\CmderPrompt -Value $CmderPrompt -Options Constant
    Set-Item -Path function:\PostPrompt  -Value $PostPrompt  -Options Constant

    # Functions can be made constant only at creation time
    # ReadOnly at least requires `-force` to be overwritten
    # if (!$(Get-Command Prompt).Options -match 'ReadOnly') {Set-Item -Path function:\prompt  -Value $Prompt  -Options ReadOnly}
    Set-Item -Path function:\prompt  -Value $Prompt  -Options ReadOnly
}

$CMDER_INIT_END = Get-Date

$ElapsedTime = New-TimeSpan -Start $CMDER_INIT_START -End $CMDER_INIT_END

Write-Verbose "Elapsed Time: $($ElapsedTime.TotalSeconds) seconds total"

# Init Script for PowerShell
# Created as part of cmder project

# !!! THIS FILE IS OVERWRITTEN WHEN CMDER IS UPDATED
# !!! Use "%CMDER_ROOT%\config\user-profile.ps1" to add your own startup commands

# Compatibility with PS major versions <= 2
if(!$PSScriptRoot) {
    $PSScriptRoot = Split-Path $Script:MyInvocation.MyCommand.Path
}

# Add Cmder modules directory to the autoload path.
$CmderModulePath = Join-path $PSScriptRoot "psmodules/"

if( -not $env:PSModulePath.Contains($CmderModulePath) ){
    $env:PSModulePath = $env:PSModulePath.Insert(0, "$CmderModulePath;")
}

try {
    Get-command -Name "vim" -ErrorAction Stop >$null
} catch {
    $env:Path += ";$env:CMDER_ROOT\vendor\git-for-windows\usr\share\vim\vim74"
}

try {
    # Check if git is on PATH, i.e. Git already installed on system
    Get-command -Name "git" -ErrorAction Stop >$null
} catch {
    $env:Path += ";$env:CMDER_ROOT\vendor\git-for-windows\bin"
}

try {
    Import-Module -Name "posh-git" -ErrorAction Stop >$null
    $gitStatus = $true
} catch {
    Write-Warning "Missing git support, install posh-git with 'Install-Module posh-git' and restart cmder."
    $gitStatus = $false
}

function checkGit($Path) {
    if (Test-Path -Path (Join-Path $Path '.git/') ) {
        Write-VcsStatus
        return
    }
    $SplitPath = split-path $path
    if ($SplitPath) {
        checkGit($SplitPath)
    }
}

# Set up a Cmder prompt, adding the git prompt parts inside git repos
function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE
    $Host.UI.RawUI.ForegroundColor = "White"
    Write-Host $pwd.ProviderPath -NoNewLine -ForegroundColor Green
    if($gitStatus){
        checkGit($pwd.ProviderPath)
    }
    $global:LASTEXITCODE = $realLASTEXITCODE
    Write-Host "`nλ" -NoNewLine -ForegroundColor "DarkGray"
    return " "
}

# Load special features come from posh-git
if ($gitStatus) {
    Start-SshAgent -Quiet
}

# Move to the wanted location
$cmderStartKey = 'HKCU:\Software\cmder'
$cmderStartSubKey = 'CMDER_START'

$cmderStart = (Get-Item -Path $cmderStartKey).GetValue($cmderStartSubKey)
if ( $cmderStart ) {
    $cmderStart = ($cmderStart).Trim('"').Trim("'")
    if ( $cmderStart.EndsWith(':') ) {
        $cmderStart += '\'
    }

    if ( ( Get-Item $cmderStart -Force ) -is [System.IO.FileInfo] ) {
        $cmderStart = Split-Path $cmderStart
    }

    Set-Location -Path "${cmderStart}"

    Set-ItemProperty -Path $cmderStartKey -Name $cmderStartSubKey -Value $null
} else {
    Set-Location -Path "${env:HOME}"
}

# Enhance Path
$env:Path = "$Env:CMDER_ROOT\bin;$env:Path;$Env:CMDER_ROOT"


$CmderUserProfilePath = Join-Path $env:CMDER_ROOT "config/user-profile.ps1"
if(Test-Path $CmderUserProfilePath) {
    # Create this file and place your own command in there.
    . "$CmderUserProfilePath"
} else {
    Write-Host "Creating user startup file: $CmderUserProfilePath"
    "# Use this file to run your own startup commands" | Out-File $CmderUserProfilePath
}

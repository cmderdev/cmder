# Init Script for PowerShell
# Created as part of cmder project

# !!! THIS FILE IS OVERWRITTEN WHEN CMDER IS UPDATED
# !!! Use "%CMDER_ROOT%\config\user-profile.ps1" to add your own startup commands

# We do this for Powershell as Admin Sessions because CMDER_ROOT is not beng set.
if (! $ENV:CMDER_ROOT ) {
    $ENV:CMDER_ROOT = resolve-path( $ENV:ConEmuDir + "\..\.." )
}

# Remove trailing '\'
$ENV:CMDER_ROOT = (($ENV:CMDER_ROOT).trimend("\"))

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
    # # You could do this but it may be a little drastic and introduce a lot of
    # # unix tool overlap with powershel unix like aliases
    # $env:Path += $(";" + $env:CMDER_ROOT + "\vendor\git-for-windows\usr\bin")
    # set-alias -name "vi" -value "vim"
    # # I think the below is safer.

    new-alias -name "vim" -value $($ENV:CMDER_ROOT + "\vendor\git-for-windows\usr\bin\vim.exe")
    new-alias -name "vi" -value vim
}

try {
    # Check if git is on PATH, i.e. Git already installed on system
    Get-command -Name "git" -ErrorAction Stop >$null
} catch {
    $env:Path += $(";" + $env:CMDER_ROOT + "\vendor\git-for-windows\bin")
}

try {
    Import-Module -Name "posh-git" -ErrorAction Stop >$null
    $gitStatus = $true
} catch {
    Write-Warning "Missing git support, install posh-git with 'Install-Module posh-git' and restart cmder."
    $gitStatus = $false
}

function checkGit($Path) {
    if (Test-Path -Path (Join-Path $Path '.git') ) {
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
# This is either a env variable set by the user or the result of
# cmder.exe setting this variable due to a commandline argument or a "cmder here"
if ( $ENV:CMDER_START ) {
    Set-Location -Path "$ENV:CMDER_START"
}

if (Get-Module PSReadline -ErrorAction "SilentlyContinue") {
    Set-PSReadlineOption -ExtraPromptLineCount 1
}

# Enhance Path
$env:Path = "$Env:CMDER_ROOT\bin;$env:Path;$Env:CMDER_ROOT"

# Drop *.ps1 files into "$ENV:CMDER_ROOT\config\profile.d"
# to source them at startup.
if (-not (test-path "$ENV:CMDER_ROOT\config\profile.d")) {
  mkdir "$ENV:CMDER_ROOT\config\profile.d"
}

pushd $ENV:CMDER_ROOT\config\profile.d
foreach ($x in ls *.ps1) {
  # write-host write-host Sourcing $x
  . $x
}
popd

$CmderUserProfilePath = Join-Path $env:CMDER_ROOT "config\user-profile.ps1"
if(Test-Path $CmderUserProfilePath) {
    # Create this file and place your own command in there.
    . "$CmderUserProfilePath"
} else {
    Write-Host "Creating user startup file: $CmderUserProfilePath"
    "# Use this file to run your own startup commands" | Out-File $CmderUserProfilePath
}

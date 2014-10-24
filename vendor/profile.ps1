# Global modules directory
$global:PsGetDestinationModulePath = $PSScriptRoot + "\..\vendor\psmodules"

# Push to modules location
Push-Location -Path ($PsGetDestinationModulePath)

# Load modules from current directory
Get-ChildItem -Directory | `
Foreach-Object{
    Import-Module .\$_\$_
}

# Come back to PWD
Pop-Location

# Set up a Cmder prompt, adding the git prompt parts inside git repos
function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE
    $Host.UI.RawUI.ForegroundColor = "white"
    Write-Host($pwd.ProviderPath) -NoNewLine -ForegroundColor "green"
    if (Get-Module posh-git) {
        Write-VcsStatus
    }
    $global:LASTEXITCODE = $realLASTEXITCODE
    return "`nλ "
}

# Load special features come from posh-git
if (Get-Module posh-git) {
    Enable-GitColors
    Start-SshAgent -Quiet
}

# Move to the wanted location
if (Test-Path Env:\CMDER_START) {
    Set-Location -Path $Env:CMDER_START
} elseif ($Env:CMDER_ROOT -and $Env:CMDER_ROOT.StartsWith($pwd)) {
    Set-Location -Path $Env:USERPROFILE
}

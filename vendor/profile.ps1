# Global modules directory
$global:PsGetDestinationModulePath = $PSScriptRoot + "\..\vendor\psmodules"

# Push to modules location
Push-Location -Path ($PsGetDestinationModulePath)

# Load modules from current directory
Import-Module .\PsGet\PsGet
Get-ChildItem -Exclude "PsGet" -Directory -Name | Foreach-Object {
    Import-Module .\$_\$_
}

# Come back to PWD
Pop-Location

# Set up a Cmder prompt, adding the git prompt parts inside git repos
function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE
    $Host.UI.RawUI.ForegroundColor = "White"
    Write-Host("`n" + $pwd.ProviderPath) -NoNewLine -ForegroundColor Green
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

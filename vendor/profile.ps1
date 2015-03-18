# Add Cmder modules directory to the autoload path.
$CmderModulePath = Join-path $PSScriptRoot "psmodules/"

if( -not $env:PSModulePath.Contains($CmderModulePath) ){
    $env:PSModulePath = $env:PSModulePath.Insert(0, "$CmderModulePath;")
}

# Set up a Cmder prompt, adding the git prompt parts inside git repos
function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE
    $Host.UI.RawUI.ForegroundColor = "White"
    Write-Host("`n" + $pwd.ProviderPath) -NoNewLine -ForegroundColor Green
    if (Get-Module posh-git) {
        Write-VcsStatus
    }
    $global:LASTEXITCODE = $realLASTEXITCODE
    Write-Host "`nλ" -NoNewLine -ForegroundColor "DarkGray"
    return " "
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

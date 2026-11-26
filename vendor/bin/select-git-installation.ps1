[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:CMDER_ROOT)) {
    throw 'CMDER_ROOT must be set before selecting a Git installation.'
}

. (Join-Path $PSScriptRoot '..\psmodules\Cmder.ps1')
$selection = Select-GitInstallation -CmderRoot $env:CMDER_ROOT -GitInstallRoot $env:GIT_INSTALL_ROOT -FastInit ($env:fast_init -eq '1')
if ($selection.GitRoot) {
    Write-Output $selection.GitRoot
}

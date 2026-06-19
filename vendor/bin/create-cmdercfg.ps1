[CmdletBinding()]
param(
    [Parameter()]
    [string]$Shell = 'cmd',
    [string]$OutFile = "$env:cmder_config_dir\user_init.cmd"
)

if ($Shell -match 'powershell') {
    Write-Host "'$Shell' is not supported at this time!"
    exit 0
}
elseif ($Shell -match 'bash') {
    Write-Host "'$Shell' is not supported at this time!"
    exit 0
}
elseif ($Shell -notmatch 'cmd') {
    exit 0
}

$CmderModulePath = Join-Path $env:cmder_root 'vendor/psmodules/'
$CmderFunctions = Join-Path $CmderModulePath 'Cmder.ps1'

. $CmderFunctions

if ($Shell -match 'cmd') {
    Write-Host "Generating Cmder Config for '$Shell' shell in '$OutFile'..."
    TemplateExpand "$env:cmder_root\vendor\user_init.cmd.template" "$OutFile"
}
elseif ($Shell -match 'powershell') {
    Write-Host "'$Shell' is not supported at this time!"
}
elseif ($Shell -match 'bash') {
    Write-Host "'$Shell' is not supported at this time!"
}

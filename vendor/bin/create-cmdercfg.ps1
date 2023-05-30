[CmdletBinding()]
param(
    [Parameter()]
    [string]$shell = 'cmd',
    [string]$outfile = "$env:cmder_root\config\user_init.cmd"
)

$CmderModulePath = Join-path $env:cmder_root "vendor/psmodules/"
$CmderFunctions  = Join-Path $CmderModulePath "Cmder.ps1"
. $CmderFunctions

if ($shell -match 'cmd') {
  write-host "Generating Cmder Config for '$shell' shell in '$outfile'..."
  templateExpand "$env:cmder_root\vendor\user_init.template.cmd" "$outfile"
} elseif ($shell -match 'powershell') {
  write-host "'$shell' is not supported at this time!"
} elseif ($shell -match 'bash') {
  write-host "'$shell' is not supported at this time!"
}

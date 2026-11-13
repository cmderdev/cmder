[CmdletBinding()]
param(
    [Parameter()]
    [string]$Shell = 'cmd',
    [string]$OutFile = "$env:cmder_config_dir\user_init.cmd",

    [switch]$FirstRun
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
    $template = "$env:cmder_root\vendor\user_init.cmd.template"
    if ($FirstRun) {
        . (Join-Path $CmderModulePath 'FirstRun.ps1')
        Write-CmderSetupSection 'Command startup cache'
        Write-CmderSetupItem ([IO.Path]::GetDirectoryName($OutFile))
        if ([IO.File]::Exists($OutFile)) {
            return
        }
        try {
            TemplateExpand $template $OutFile -CreateNew
            Write-CmderSetupItem "Created $([IO.Path]::GetFileName($OutFile))"
        } catch {
            if (-not [IO.File]::Exists($OutFile)) {
                Write-CmderSetupFailure $OutFile $_.Exception.GetBaseException().Message
                exit 1
            }
        }
    } else {
        Write-Host "Generating Cmder Config for '$Shell' shell in '$OutFile'..."
        TemplateExpand $template $OutFile
    }
}
elseif ($Shell -match 'powershell') {
    Write-Host "'$Shell' is not supported at this time!"
}
elseif ($Shell -match 'bash') {
    Write-Host "'$Shell' is not supported at this time!"
}

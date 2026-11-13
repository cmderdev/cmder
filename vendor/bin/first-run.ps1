param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Clink', 'Aliases', 'Profile', 'ProfileDirectory', 'Git')]
    [string]$Action,
    [string]$Target
)

. "$PSScriptRoot\..\psmodules\FirstRun.ps1"

$ok = switch ($Action) {
    'Clink' {
        $files = @()
        if (-not [IO.File]::Exists((Join-Path $Target 'settings'))) {
            $files += Join-Path $Target 'clink_settings'
        }
        $files += Join-Path $Target 'cmder_prompt_config.lua'
        Initialize-CmderConfig 'Clink and prompt' $files
    }
    'Aliases' {
        Initialize-CmderConfig 'Command aliases' $Target -Template (Join-Path $env:CMDER_ROOT 'vendor/user_aliases.cmd.default')
    }
    'Profile' { Initialize-CmderConfig 'Startup profile' $Target }
    'ProfileDirectory' { Initialize-CmderConfig 'Startup scripts' $Target -Directory }
    'Git' { Initialize-CmderPortableGit $Target }
}

if (-not $ok) {
    exit 1
}
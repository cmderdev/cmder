[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$updateScriptPath = Join-Path $PSScriptRoot 'update.ps1'
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $updateScriptPath,
    [ref]$tokens,
    [ref]$parseErrors
)

if ($parseErrors.Count -gt 0) {
    throw "Unable to parse ${updateScriptPath}: $($parseErrors[0].Message)"
}

$requiredFunctions = @('Compare-Filename', 'Test-IsPrerelease', 'Fetch-DownloadUrl')
$functionDefinitions = $ast.FindAll({
    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $args[0].Name -in $requiredFunctions
}, $true)

foreach ($name in $requiredFunctions) {
    $definition = $functionDefinitions | Where-Object Name -eq $name | Select-Object -First 1
    if ($null -eq $definition) {
        throw "Required function '$name' was not found in $updateScriptPath."
    }

    . ([scriptblock]::Create($definition.Extent.Text))
}

$currentUrl = 'https://github.com/example/vendor/releases/download/v1.0.0/vendor-1.0.0-x64.zip'
$script:expectedUrl = 'https://github.com/example/vendor/releases/download/v2.0.0/vendor-2.0.0-x64.zip'

function Invoke-RestMethodMock {
    param(
        [uri]$Uri,
        [hashtable]$Headers
    )

    if ($Uri.Host -ne 'api.github.com' -or $Uri.AbsolutePath -ne '/repos/example/vendor/releases') {
        throw "Unexpected release API request: $Uri"
    }
    $null = $Headers

    return @(
        [pscustomobject]@{
            prerelease = $false
            tag_name = 'v2.0.0'
            assets = @([pscustomobject]@{ browser_download_url = $script:expectedUrl })
        },
        [pscustomobject]@{
            prerelease = $false
            tag_name = 'v1.0.0'
            assets = @()
        }
    )
}

Set-Alias -Name Invoke-RestMethod -Value Invoke-RestMethodMock -Scope Script

$actualUrl = Fetch-DownloadUrl -urlStr $currentUrl
if ($actualUrl -ne $script:expectedUrl) {
    throw "Expected '$script:expectedUrl', received '$actualUrl'."
}

Write-Output 'Vendor update helper smoke test passed.'

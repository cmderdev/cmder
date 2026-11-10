[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$workflow = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\.github\workflows\vendor.yml') -Raw -Encoding UTF8
$start = $workflow.IndexOf('          function Set-UrlQueryParameter {')
$end = $workflow.IndexOf('          $previousPrVersion =', $start)
if ($start -lt 0 -or $end -le $start) { throw 'Vendor badge helper block was not found.' }
$helpers = $workflow.Substring($start, $end - $start) -replace '(?m)^          ', ''
$tokens = $null
$parseErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseInput($helpers, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors) { throw ($parseErrors | Out-String) }
# Load only the helper definitions, never the workflow's vendor update or PR code.
. ([scriptblock]::Create($helpers))

$script:Assertions = 0
function Assert-Equal($Actual, $Expected, [string]$Name) {
    $script:Assertions++
    if ($Actual -cne $Expected) { throw "$Name`nExpected: $Expected`nActual: $Actual" }
}
function Assert-Contains([string]$Actual, [string]$Expected, [string]$Name) {
    $script:Assertions++
    if (-not $Actual.Contains($Expected)) { throw "$Name`nMissing: $Expected`nActual: $Actual" }
}

$release = @{ RepoPath='example/vendor'; RepoUrl='https://github.com/example/vendor'; TagName='v2/test+1'; ReleaseUrl='https://github.com/example/vendor/releases/tag/v2%2Ftest%2B1' }
$encodedTag = 'v2%2Ftest%2B1'
$encodedAzureTag = 'refs%2Ftags%2Fv2%2Ftest%2B1'
Assert-Equal (Set-UrlQueryParameter 'https://example.test/build#logs' 'branch' $release.TagName) "https://example.test/build?branch=$encodedTag#logs" 'Query precedes fragment'
Assert-Equal (Set-UrlQueryParameter 'https://example.test/build?branch=main&view=all#logs' 'branch' $release.TagName) "https://example.test/build?branch=$encodedTag&view=all#logs" 'Existing query is replaced without losing fragment'

$azureImage = 'https://dev.azure.com/example/project/_apis/build/status/Build?branchName=main'
foreach ($target in @('https://dev.azure.com/example/project/_build','https://dev.azure.com/example/project/_build/','https://dev.azure.com/example/project/_build?definitionId=1','https://dev.azure.com/example/project/_build/latest?definitionId=1')) {
    $badge = ConvertTo-ReleaseBuildStatusBadge "[![Build]($azureImage)]($target)" $release
    Assert-Contains $badge "branchName=$encodedAzureTag" 'Azure image uses an explicit tag ref'
    Assert-Equal ([regex]::Matches($badge, "branchName=$encodedAzureTag").Count) 2 'Azure target uses the same tag for every URL form'
}
$modern = ConvertTo-ReleaseBuildStatusBadge '[![CI](https://github.com/example/vendor/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/example/vendor/actions?query=branch%3Amain)' $release
Assert-Contains $modern "branch=$encodedTag" 'Modern GitHub image ref'
Assert-Contains $modern 'query=branch%3Av2%2Ftest%2B1' 'Modern GitHub target ref'
$legacy = ConvertTo-ReleaseBuildStatusBadge '[![Build](https://github.com/example/vendor/workflows/Build/badge.svg)](https://github.com/example/vendor/actions)' $release
Assert-Contains $legacy "branch=$encodedTag" 'Legacy GitHub image ref'
Assert-Equal (ConvertTo-ReleaseBuildStatusBadge '[![Chat](https://example.test/chat.svg)](https://example.test)' $release) ([string][char]0x2014) 'Unrelated badges are not retargeted'
Assert-Equal (ConvertTo-ReleaseBuildStatusBadge '[![CI](https://github.com/other/repository/actions/workflows/build.yml/badge.svg)](https://github.com/other/repository/actions)' $release) ([string][char]0x2014) 'Another repository badge is not labeled as this release'
Assert-Equal (ConvertTo-ReleaseBuildStatusBadge "[![Build]($azureImage)](https://example.test/unrelated)" $release) ([string][char]0x2014) 'An unrelated Azure target is not shown as retargeted'

function Invoke-WebRequest {
    param($Uri, [switch]$UseBasicParsing, $TimeoutSec)
    $script:RequestedBadgeUrls.Add([string]$Uri)
    if ($script:BadgeFailure) { throw 'Fixture network failure' }
    $content = if ([string]$Uri -like 'https://img.shields.io/*') { $script:FallbackSvg } else { $script:ReadmeBadgeSvg }
    return @{ Content=$content }
}
function Invoke-GitHubApi {
    param($Uri)
    if ($script:ReadmeFailure) { throw 'Fixture README API failure' }
    if ($null -ne $script:ReleaseApiResponse) { return $script:ReleaseApiResponse }
    return $script:ReadmeResponse
}
function Reset-Fixtures {
    $script:RequestedBadgeUrls = New-Object 'System.Collections.Generic.List[string]'
    $script:BadgeFailure = $false
    $script:ReadmeFailure = $false
    $script:ReleaseApiResponse = $null
    $script:ReadmeResponse = @{ content='' }
    $script:ReadmeBadgeSvg = '<svg xmlns="http://www.w3.org/2000/svg"><title>build: passing</title></svg>'
    $script:FallbackSvg = '<svg xmlns="http://www.w3.org/2000/svg"><title>checks: passing</title></svg>'
}
Reset-Fixtures
$sampleBadge = '[![Build](https://github.com/example/vendor/actions/workflows/build.yml/badge.svg)](https://github.com/example/vendor/actions)'
foreach ($status in @('passing','failing','pending')) {
    $script:ReadmeBadgeSvg = "<svg><title>build: $status</title></svg>"
    Assert-Equal (Test-BuildStatusBadgeHasReleaseStatus $sampleBadge) $true "A real $status status is shown"
}
foreach ($content in @('<svg><title>build: no status</title></svg>','<svg><title>checks: no check runs</title></svg>','<svg><title>build: never built</title></svg>','<svg><title>checks: unknown</title></svg>','<svg><title>checks: inaccessible</title></svg>','<html><body>passing</body></html>','<svg/>','not an SVG')) {
    $script:ReadmeBadgeSvg = $content
    Assert-Equal (Test-BuildStatusBadgeHasReleaseStatus $sampleBadge) $false 'Missing status or invalid response is rejected'
}
$script:BadgeFailure = $true
Assert-Equal (Test-BuildStatusBadgeHasReleaseStatus $sampleBadge) $false 'Badge network failure is rejected'

foreach ($fixture in @('empty','missing','invalid-base64','api-failure','no-badge')) {
    Reset-Fixtures
    switch ($fixture) {
        'missing' { $script:ReadmeResponse=@{} }
        'invalid-base64' { $script:ReadmeResponse=@{content='%%%'} }
        'api-failure' { $script:ReadmeFailure=$true }
        'no-badge' { $script:ReadmeResponse=@{content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('# No build badge'))} }
    }
    $actual = Get-ReadmeBuildStatusBadge $release
    Assert-Contains $actual "https://img.shields.io/github/check-runs/example/vendor/$encodedTag" "Fallback works for $fixture README"
    Assert-Contains $actual 'Build status for release v2/test+1' 'Fallback names the requested release'
}

Reset-Fixtures
$script:ReadmeResponse=@{content=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($sampleBadge))}
Assert-Contains (Get-ReadmeBuildStatusBadge $release) "github.com/example/vendor/actions/workflows/build.yml/badge.svg?branch=$encodedTag" 'Valid README badge is preferred'
$script:ReadmeBadgeSvg='<svg><title>build: no status</title></svg>'
Assert-Contains (Get-ReadmeBuildStatusBadge $release) 'img.shields.io/github/check-runs/' 'Invalid README badge uses the fallback'
$script:FallbackSvg='<svg><title>checks: no check runs</title></svg>'
Assert-Equal (Get-ReadmeBuildStatusBadge $release) ([string][char]0x2014) 'No release status stays unavailable'

$quote = ConvertTo-BlockQuote -Markdown ('x' * 80) -MaxLength 20 -FullTextUrl $release.ReleaseUrl
Assert-Contains $quote ('[open the release notes]('+$release.ReleaseUrl+')') 'Truncated blockquote links full release notes'
Assert-Contains $quote '> [!TIP]' 'Truncation notice remains a quoted TIP'
$script:ReleaseApiResponse = @(@{tag_name=$release.TagName;name='Example release';html_url=$release.ReleaseUrl;body=('x' * 1500)})
$rangeNotes = Get-ReleaseNotesForRange -ReleaseInfo $release -ChangeType patch
Assert-Contains $rangeNotes ('[open the release notes]('+$release.ReleaseUrl+')') 'Long release-range notes link their full source'
Assert-Contains $rangeNotes '[!TIP]' 'Release-range truncation retains the TIP'
Write-Host "Vendor badge fixtures passed ($script:Assertions assertions)."

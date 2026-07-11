[CmdletBinding()]
param(
    [string]$Path = ".",

    [string]$SummaryPath = $env:GITHUB_STEP_SUMMARY
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-OneLine {
    param(
        [AllowEmptyString()]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    return (($Text.Trim() -split "`r?`n") -join " ") -replace '\s+', ' '
}

function ConvertTo-HtmlText {
    param(
        [AllowEmptyString()]
        [string]$Text
    )

    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function Get-RelativeScriptPath {
    param(
        [AllowEmptyString()]
        [string]$ScriptPath,

        [string]$RootPath,

        [AllowEmptyString()]
        [string]$FallbackName
    )

    if (-not [string]::IsNullOrWhiteSpace($ScriptPath)) {
        try {
            return [System.IO.Path]::GetRelativePath($RootPath, $ScriptPath).Replace('\', '/')
        } catch {
            return $ScriptPath.Replace('\', '/')
        }
    }

    return $FallbackName
}

function Get-MarkdownLocation {
    param(
        [string]$RelativePath,

        [int]$Line
    )

    $displayPath = if ($Line -gt 0) { "${RelativePath}:$Line" } else { $RelativePath }
    $repository = $env:GITHUB_REPOSITORY
    $sha = $env:GITHUB_SHA
    $serverUrl = if ($env:GITHUB_SERVER_URL) { $env:GITHUB_SERVER_URL } else { "https://github.com" }

    if (-not [string]::IsNullOrWhiteSpace($repository) -and -not [string]::IsNullOrWhiteSpace($sha)) {
        $url = "$serverUrl/$repository/blob/$sha/$RelativePath"
        if ($Line -gt 0) {
            $url += "#L$Line"
        }

        return "[``$displayPath``]($url)"
    }

    return "``$displayPath``"
}

Import-Module PSScriptAnalyzer -ErrorAction Stop

$rootPath = (Resolve-Path -Path $Path).Path
$diagnostics = @(Invoke-ScriptAnalyzer -Path $rootPath -Recurse -Severity Error, Warning, Information)
$severityOrder = @{
    Error = 0
    Warning = 1
    Information = 2
}

$diagnostics = @(
    $diagnostics | Sort-Object `
        @{ Expression = { $severityOrder[$_.Severity.ToString()] } }, `
        @{ Expression = { $_.ScriptName } }, `
        @{ Expression = { $_.Line } }, `
        @{ Expression = { $_.Column } }, `
        @{ Expression = { $_.RuleName } }
)

$summary = [System.Collections.Generic.List[string]]::new()
$summary.Add("### PowerShell ScriptAnalyzer")
$summary.Add("")

if ($diagnostics.Count -eq 0) {
    $summary.Add("No PowerShell issues were reported by PSScriptAnalyzer.")
    $summary.Add("")
} else {
    $fileCount = @($diagnostics | Where-Object { $_.ScriptName } | Select-Object -ExpandProperty ScriptName -Unique).Count
    $summary.Add("PSScriptAnalyzer reported **$($diagnostics.Count)** advisory findings across **$fileCount** PowerShell files.")
    $summary.Add("")
    $summary.Add("| Severity | Count |")
    $summary.Add("| --- | ---: |")

    foreach ($severity in @("Error", "Warning", "Information")) {
        $count = @($diagnostics | Where-Object { $_.Severity.ToString() -eq $severity }).Count
        $summary.Add("| $severity | $count |")
    }

    $summary.Add("")
    $summary.Add("> These findings are sorted by severity and are advisory; they do not fail the test job.")
    $summary.Add("")

    foreach ($severity in @("Error", "Warning", "Information")) {
        $severityDiagnostics = @($diagnostics | Where-Object { $_.Severity.ToString() -eq $severity })
        if ($severityDiagnostics.Count -eq 0) {
            continue
        }

        $summary.Add("<details>")
        $summary.Add("<summary>$severity findings ($($severityDiagnostics.Count))</summary>")
        $summary.Add("")

        $index = 1
        foreach ($diagnostic in $severityDiagnostics) {
            $relativePath = Get-RelativeScriptPath -ScriptPath $diagnostic.ScriptPath -RootPath $rootPath -FallbackName $diagnostic.ScriptName
            $line = if ($null -ne $diagnostic.Line) { [int]$diagnostic.Line } else { 0 }
            $column = if ($null -ne $diagnostic.Column) { [int]$diagnostic.Column } else { 0 }
            $location = Get-MarkdownLocation -RelativePath $relativePath -Line $line
            $ruleName = ConvertTo-HtmlText -Text $diagnostic.RuleName
            $message = ConvertTo-HtmlText -Text (ConvertTo-OneLine -Text $diagnostic.Message)

            $summary.Add("$index. **$location** - ``$ruleName``")
            $summary.Add("   - Message: $message")
            if ($line -gt 0 -or $column -gt 0) {
                $summary.Add("   - Position: line $line, column $column")
            }
            $summary.Add("")
            $index++
        }

        $summary.Add("</details>")
        $summary.Add("")
    }

    Write-Warning "PSScriptAnalyzer reported $($diagnostics.Count) advisory findings."
}

if ([string]::IsNullOrWhiteSpace($SummaryPath)) {
    $summary -join [Environment]::NewLine
} else {
    $summary | Add-Content -Path $SummaryPath -Encoding utf8
}

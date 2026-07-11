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
    $ruleCount = @($diagnostics | Select-Object -ExpandProperty RuleName -Unique).Count
    $summary.Add("PSScriptAnalyzer reported **$($diagnostics.Count)** advisory findings across **$ruleCount** rule types and **$fileCount** PowerShell files.")
    $summary.Add("")
    $summary.Add("| Severity | Count |")
    $summary.Add("| --- | ---: |")

    foreach ($severity in @("Error", "Warning", "Information")) {
        $count = @($diagnostics | Where-Object { $_.Severity.ToString() -eq $severity }).Count
        $summary.Add("| $severity | $count |")
    }

    $summary.Add("")
    $summary.Add("> These findings are grouped by rule type, then file. Rule groups are sorted by highest severity, finding count, and rule name. Findings are advisory; they do not fail the test job.")
    $summary.Add("")

    $ruleGroups = @(
        $diagnostics |
            Group-Object RuleName |
            ForEach-Object {
                $groupDiagnostics = @($_.Group)
                $highestSeverityRank = ($groupDiagnostics | ForEach-Object { $severityOrder[$_.Severity.ToString()] } | Measure-Object -Minimum).Minimum
                $highestSeverity = ($severityOrder.GetEnumerator() | Where-Object { $_.Value -eq $highestSeverityRank } | Select-Object -First 1).Key
                $groupFiles = @($groupDiagnostics | Where-Object { $_.ScriptName } | Select-Object -ExpandProperty ScriptName -Unique)

                [pscustomobject]@{
                    RuleName = $_.Name
                    Severity = $highestSeverity
                    SeverityRank = $highestSeverityRank
                    Count = $groupDiagnostics.Count
                    FileCount = $groupFiles.Count
                    Diagnostics = $groupDiagnostics
                }
            } |
            Sort-Object `
                @{ Expression = { $_.SeverityRank } }, `
                @{ Expression = { -1 * $_.Count } }, `
                @{ Expression = { $_.RuleName } }
    )

    $summary.Add("| Rule | Severity | Findings | Files |")
    $summary.Add("| --- | --- | ---: | ---: |")
    foreach ($ruleGroup in $ruleGroups) {
        $summary.Add("| ``$($ruleGroup.RuleName)`` | $($ruleGroup.Severity) | $($ruleGroup.Count) | $($ruleGroup.FileCount) |")
    }
    $summary.Add("")

    foreach ($ruleGroup in $ruleGroups) {
        $summary.Add("<details>")
        $summary.Add("<summary>$($ruleGroup.Severity): $($ruleGroup.RuleName) ($($ruleGroup.Count) findings across $($ruleGroup.FileCount) files)</summary>")
        $summary.Add("")

        $fileGroups = @(
            $ruleGroup.Diagnostics |
                Group-Object {
                    Get-RelativeScriptPath -ScriptPath $_.ScriptPath -RootPath $rootPath -FallbackName $_.ScriptName
                } |
                Sort-Object Name
        )

        foreach ($fileGroup in $fileGroups) {
            $relativePath = $fileGroup.Name
            $summary.Add("#### ``$relativePath`` ($($fileGroup.Count))")
            $summary.Add("")

            foreach ($diagnostic in @($fileGroup.Group | Sort-Object Line, Column, Message)) {
                $line = if ($null -ne $diagnostic.Line) { [int]$diagnostic.Line } else { 0 }
                $column = if ($null -ne $diagnostic.Column) { [int]$diagnostic.Column } else { 0 }
                $location = Get-MarkdownLocation -RelativePath $relativePath -Line $line
                $message = ConvertTo-HtmlText -Text (ConvertTo-OneLine -Text $diagnostic.Message)

                $summary.Add("- **$location**")
                $summary.Add("  - Message: $message")
                if ($line -gt 0 -or $column -gt 0) {
                    $summary.Add("  - Position: line $line, column $column")
                }
                $summary.Add("")
            }
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

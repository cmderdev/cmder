[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$extensions = @(
    '.ps1',
    '.psm1',
    '.psd1',
    '.cmd',
    '.bat',
    '.sh',
    '.lua',
    '.yml',
    '.yaml',
    '.json',
    '.xml',
    '.ini',
    '.rc',
    '.vcxproj',
    '.filters',
    '.props',
    '.sln',
    '.cpp',
    '.c',
    '.h',
    '.hpp'
)

$files = @(
    git ls-files |
        Where-Object { $extensions -contains [System.IO.Path]::GetExtension($_).ToLowerInvariant() }
)

$findings = foreach ($file in $files) {
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $file) {
        $lineNumber++
        if ($line -match '[ \t]+$') {
            [pscustomobject]@{
                File = $file
                Line = $lineNumber
            }
        }
    }
}

if ($findings) {
    Write-Error (
        "Trailing whitespace found:`n" +
        (($findings | ForEach-Object { "$($_.File):$($_.Line)" }) -join "`n")
    )
}

Write-Output "No trailing whitespace found in checked files."

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$helper = Join-Path $PSScriptRoot '..\vendor\lib\lib_base.cmd'
$cmdExecutable = Join-Path ([Environment]::SystemDirectory) 'cmd.exe'

# These exercise the batch helper under cmd.exe; they do not start a TCC shell.
$cases = @(
    @{ Name = 'cmd defaults'; Shell = 'cmd'; Clink = ''; Aliases = ''; ExpectedClink = '1'; ExpectedAliases = '1' },
    @{ Name = 'cmd overrides'; Shell = 'cmd'; Clink = '0'; Aliases = '0'; ExpectedClink = '0'; ExpectedAliases = '0' },
    @{ Name = 'TCC defaults'; Shell = 'tcc'; Clink = ''; Aliases = ''; ExpectedClink = '0'; ExpectedAliases = '0' },
    @{ Name = 'TCCLE defaults'; Shell = 'tccle'; Clink = ''; Aliases = ''; ExpectedClink = '0'; ExpectedAliases = '0' },
    @{ Name = 'TCC mixed case'; Shell = 'TcC'; Clink = ''; Aliases = ''; ExpectedClink = '0'; ExpectedAliases = '0' },
    @{ Name = 'TCCLE mixed case'; Shell = 'TcClE'; Clink = ''; Aliases = ''; ExpectedClink = '0'; ExpectedAliases = '0' },
    @{ Name = 'TCC overrides'; Shell = 'tcc'; Clink = '2'; Aliases = '1'; ExpectedClink = '2'; ExpectedAliases = '1' },
    @{ Name = 'TCCLE overrides'; Shell = 'tccle'; Clink = '1'; Aliases = '1'; ExpectedClink = '1'; ExpectedAliases = '1' },
    @{ Name = 'TCC Clink override only'; Shell = 'tcc'; Clink = '2'; Aliases = ''; ExpectedClink = '2'; ExpectedAliases = '0' },
    @{ Name = 'TCCLE aliases override only'; Shell = 'tccle'; Clink = ''; Aliases = '1'; ExpectedClink = '0'; ExpectedAliases = '1' }
)

foreach ($case in $cases) {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $cmdExecutable
    $startInfo.Arguments = '/d /v:off /c call "{0}" detect_comspec "C:\JPSoft\{1}.exe" & set CMDER_SHELL & set CMDER_CLINK & set CMDER_ALIASES' -f $helper, $case.Shell
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.EnvironmentVariables['CMDER_CLINK'] = $case.Clink
    $startInfo.EnvironmentVariables['CMDER_ALIASES'] = $case.Aliases
    $startInfo.EnvironmentVariables.Remove('CMDER_SHELL')

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    try {
        $null = $process.Start()
        $output = $process.StandardOutput.ReadToEnd()
        $errors = $process.StandardError.ReadToEnd()
        $process.WaitForExit()
        if ($process.ExitCode -ne 0 -or $errors) {
            throw "$($case.Name): helper failed (exit $($process.ExitCode)). $errors $output"
        }

        $actual = @{}
        foreach ($line in ($output -split '\r?\n')) {
            if ($line -match '^(CMDER_(?:SHELL|CLINK|ALIASES))=(.*)$') {
                $actual[$Matches[1]] = $Matches[2]
            }
        }

        if ($actual.CMDER_SHELL -cne $case.Shell -or
            $actual.CMDER_CLINK -ne $case.ExpectedClink -or
            $actual.CMDER_ALIASES -ne $case.ExpectedAliases) {
            throw "$($case.Name): unexpected shell defaults. $output"
        }

        Write-Host "Passed: $($case.Name)"
    }
    finally {
        $process.Dispose()
    }
}

Write-Host "All $($cases.Count) shell detection cases passed. Real TCC/TCCLE testing is separate."

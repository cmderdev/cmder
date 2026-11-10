[CmdletBinding()]
param(
    [string]$BashExecutable = "$env:ProgramFiles\Git\usr\bin\bash.exe"
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$tokens = $null
$parseErrors = $null
$modulePath = Join-Path $repoRoot 'vendor\psmodules\Cmder.ps1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($modulePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw $parseErrors[0].Message }
foreach ($name in @('Get-GitRoot', 'Get-GitNativeBin', 'Set-GitPath')) {
    $definition = $ast.Find({
        $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $args[0].Name -eq $name
    }, $true)
    if (!$definition) { throw "Missing production function: $name" }
    . ([scriptblock]::Create($definition.Extent.Text))
}

$script:assertionCount = 0
function Assert-Equal($Actual, $Expected, [string]$Label) {
    if ([string]$Actual -cne [string]$Expected) {
        throw "${Label}: expected '$Expected', got '$Actual'."
    }
    $script:assertionCount++
}

if (!(Test-Path -LiteralPath $BashExecutable -PathType Leaf)) {
    throw "Git Bash is required; provide -BashExecutable. Not found: $BashExecutable"
}
$cygpath = Join-Path (Split-Path $BashExecutable -Parent) 'cygpath.exe'
if (!(Test-Path -LiteralPath $cygpath -PathType Leaf)) { throw "Not found: $cygpath" }
$bashSource = [IO.File]::ReadAllText((Join-Path $repoRoot 'vendor\cmder.sh'))
$bashMatch = [regex]::Match($bashSource, '(?ms)^git_mingw_bin=""\r?\n.*?(?=^PATH="\$\{CMDER_ROOT\}/bin:)')
if (!$bashMatch.Success) { throw 'Cannot locate Git native-bin selection in cmder.sh.' }
$cmdBlocks = @{}
foreach ($source in @('vendor\init.cmd', 'vendor\user_init.cmd.template')) {
    $sourceText = [IO.File]::ReadAllText((Join-Path $repoRoot $source))
    $selection = [regex]::Match($sourceText, '(?ms)^\s*set "git_mingw_bin="\r?\n.*?(?=^\s*%lib_path% add_path_with_position)')
    if (!$selection.Success) { throw "Cannot locate Git native-bin selection in $source." }
    $cmdBlocks[$source] = $selection.Value
}

$tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$fixtureRoot = Join-Path $tempParent ('cmder-git-layout-' + [guid]::NewGuid().ToString('N'))
$savedPath = $env:Path
$savedGitRoot = $env:GIT_INSTALL_ROOT
$savedArchitecture = $env:PROCESSOR_ARCHITECTURE
$savedWow64Architecture = $env:PROCESSOR_ARCHITEW6432
try {
    $null = New-Item -ItemType Directory -Path $fixtureRoot
    $cases = @(
        @{ Name = 'UCRT64 only'; Dirs = @('ucrt64'); Native = 'ucrt64' },
        @{ Name = 'MinGW64 only'; Dirs = @('mingw64'); Native = 'mingw64' },
        @{ Name = 'MinGW32 only'; Dirs = @('mingw32'); Native = 'mingw32' },
        @{ Name = 'Mixed layouts'; Dirs = @('ucrt64', 'mingw64', 'mingw32'); Native = 'ucrt64' },
        @{ Name = 'Older mixed layouts'; Dirs = @('mingw64', 'mingw32'); Native = 'mingw64' },
        @{ Name = 'No native directory'; Dirs = @(); Native = '' }
    )
    $basePath = 'C:\Windows\System32'
    foreach ($case in $cases) {
        $gitRoot = Join-Path $fixtureRoot $case.Name
        foreach ($directory in @('cmd', 'bin', 'usr\bin') + @($case.Dirs | ForEach-Object { "$_\bin" })) {
            $null = New-Item -ItemType Directory -Path (Join-Path $gitRoot $directory) -Force
        }
        # A directory without bin is not a usable native-tool layout.
        $null = New-Item -ItemType Directory -Path (Join-Path $gitRoot 'unused\bin') -Force
        if (!$case.Native) { $null = New-Item -ItemType Directory -Path (Join-Path $gitRoot 'mingw64') }
        $native = if ($case.Native) { Join-Path $gitRoot ($case.Native + '\bin') } else { '' }
        $native32 = if ($case.Dirs -contains 'mingw32') { Join-Path $gitRoot 'mingw32\bin' } else { '' }
        Assert-Equal (Get-GitNativeBin -GitRoot $gitRoot -Is64BitOperatingSystem $true) $native "$($case.Name) PowerShell native bin on 64-bit OS"
        Assert-Equal (Get-GitNativeBin -GitRoot $gitRoot -Is64BitOperatingSystem $false) $native32 "$($case.Name) PowerShell native bin on 32-bit OS"
        $hostNative = if ([Environment]::Is64BitOperatingSystem) { $native } else { $native32 }
        Assert-Equal (Get-GitNativeBin -GitRoot $gitRoot) $hostNative "$($case.Name) PowerShell native bin on current OS"
        foreach ($directory in @('cmd', 'bin') + @($case.Dirs | ForEach-Object { "$_\bin" })) {
            Assert-Equal (Get-GitRoot -GitPath (Join-Path $gitRoot $directory)) $gitRoot "$($case.Name) root from $directory"
        }
        Assert-Equal (Get-GitRoot -GitPath $gitRoot) $gitRoot "$($case.Name) root remains unchanged"
        $env:Path = $basePath
        $expected = (Join-Path $gitRoot 'cmd') + ';' + $basePath
        if ($hostNative) { $expected += ';' + $hostNative }
        $expected += ';' + (Join-Path $gitRoot 'usr\bin')
        Assert-Equal (Set-GitPath -GitRoot $gitRoot -GitType 'VENDOR') $expected "$($case.Name) vendored PATH"
        $env:Path = $expected
        Assert-Equal (Set-GitPath -GitRoot $gitRoot -GitType 'VENDOR') $expected "$($case.Name) no duplicate PATH"
        $env:Path = $basePath
        Assert-Equal (Set-GitPath -GitRoot $gitRoot -GitType 'USER') $basePath "$($case.Name) preserves user-selected PATH"
        $env:Path = $savedPath

        $env:GIT_INSTALL_ROOT = $gitRoot
        foreach ($source in $cmdBlocks.Keys) {
            $cmdFile = Join-Path $fixtureRoot 'select-native.cmd'
            $architectures = @(
                @{ Name = 'native64'; Process = 'AMD64'; Wow64 = ''; Native = $native },
                @{ Name = 'native32'; Process = 'x86'; Wow64 = ''; Native = $native32 },
                @{ Name = 'WoW64'; Process = 'x86'; Wow64 = 'AMD64'; Native = $native }
            )
            foreach ($architecture in $architectures) {
                $env:PROCESSOR_ARCHITECTURE = $architecture.Process
                $env:PROCESSOR_ARCHITEW6432 = $architecture.Wow64
                # cmd.exe restores its real architecture on launch; set the fixture inside the child.
                $cmdText = "@echo off`r`nset `"PROCESSOR_ARCHITECTURE=$($architecture.Process)`"`r`nset `"PROCESSOR_ARCHITEW6432=$($architecture.Wow64)`"`r`n" + $cmdBlocks[$source] + "`r`necho LAYOUT[%git_mingw_bin%]`r`n"
                [IO.File]::WriteAllText($cmdFile, $cmdText, [Text.Encoding]::ASCII)
                $actual = & $env:ComSpec /d /c "`"$cmdFile`""
                if ($LASTEXITCODE) { throw "CMD selection failed: $source" }
                Assert-Equal $actual "LAYOUT[$($architecture.Native)]" "$($case.Name) $source ($($architecture.Name))"
            }
        }
        $bashFile = Join-Path $fixtureRoot 'select-native.sh'
        $bashText = 'GIT_INSTALL_ROOT="$1"' + "`n" + 'PROCESSOR_ARCHITECTURE="$2"' + "`n" + 'PROCESSOR_ARCHITEW6432="$3"' + "`n" + 'PATH="/layout-test-base"' + "`n" + $bashMatch.Value + "`n" + 'printf ''%s\n'' "$PATH"' + "`n"
        [IO.File]::WriteAllText($bashFile, ($bashText -replace "`r`n", "`n"), (New-Object Text.UTF8Encoding($false)))
        $posixGitRoot = & $cygpath -u $gitRoot
        $posixScript = & $cygpath -u $bashFile
        foreach ($architecture in $architectures) {
            $env:PROCESSOR_ARCHITECTURE = $architecture.Process
            $env:PROCESSOR_ARCHITEW6432 = $architecture.Wow64
            $actual = & $BashExecutable --noprofile --norc $posixScript $posixGitRoot $architecture.Process $architecture.Wow64
            if ($LASTEXITCODE) { throw 'Bash selection failed.' }
            $expectedBash = if ($architecture.Native) { (& $cygpath -u $architecture.Native) + ':/layout-test-base' } else { '/layout-test-base' }
            Assert-Equal $actual $expectedBash "$($case.Name) Bash native bin ($($architecture.Name)) and no empty PATH entry"
        }
    }

    $newRoot = Join-Path $fixtureRoot 'UCRT64 only'
    $oldRoot = Join-Path $fixtureRoot 'Old Git'
    $env:Path = "$basePath;$oldRoot\cmd;$oldRoot\mingw64\bin;$oldRoot\usr\bin"
    if ([Environment]::Is64BitOperatingSystem) {
        $expected = "$basePath;$newRoot\cmd;$newRoot\ucrt64\bin;$newRoot\usr\bin"
        Assert-Equal (Set-GitPath -GitRoot $newRoot -GitType 'VENDOR' -GitPathUser $oldRoot) $expected 'Migrates an older MinGW PATH to UCRT64 in the same position'
    }

    $env:Path = $savedPath
    $posixSource = & $cygpath -u (Join-Path $repoRoot 'vendor\cmder.sh')
    & $BashExecutable -n $posixSource
    Assert-Equal $LASTEXITCODE 0 'Full cmder.sh Bash syntax'
} finally {
    $env:Path = $savedPath
    $env:GIT_INSTALL_ROOT = $savedGitRoot
    $env:PROCESSOR_ARCHITECTURE = $savedArchitecture
    $env:PROCESSOR_ARCHITEW6432 = $savedWow64Architecture
    $resolved = [IO.Path]::GetFullPath($fixtureRoot)
    if (!$resolved.StartsWith($tempParent, [StringComparison]::OrdinalIgnoreCase) -or
        !(Split-Path $resolved -Leaf).StartsWith('cmder-git-layout-')) {
        throw "Refusing to remove unexpected fixture directory: $resolved"
    }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
Write-Output "Git directory-layout tests passed ($script:assertionCount assertions)."

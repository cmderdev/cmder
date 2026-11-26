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
foreach ($name in @('Get-GitVersion', 'Get-GitShimPath', 'Compare-Version', 'Get-GitRoot', 'Select-GitInstallation', 'Get-GitNativeBin', 'Set-GitPath')) {
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

function Get-GitVersion {
    param([string]$GitPath)
    $versionFile = Join-Path $GitPath 'version.txt'
    if (Test-Path -LiteralPath $versionFile -PathType Leaf) {
        return [IO.File]::ReadAllText($versionFile)
    }
    return $null
}

$minttyLauncher = [IO.File]::ReadAllText((Join-Path $repoRoot 'vendor\start_git_mintty.cmd'))
$bashLauncher = [IO.File]::ReadAllText((Join-Path $repoRoot 'vendor\start_git_bash.cmd'))
$gitShellLibrary = [IO.File]::ReadAllText((Join-Path $repoRoot 'vendor\lib\lib_git_shell.cmd'))
$initScript = [IO.File]::ReadAllText((Join-Path $repoRoot 'vendor\init.cmd'))
$powershellProfile = [IO.File]::ReadAllText((Join-Path $repoRoot 'vendor\profile.ps1'))
$bashStartup = [IO.File]::ReadAllText((Join-Path $repoRoot 'vendor\cmder.sh'))
Assert-Equal $bashLauncher.Contains('lib_git_shell.cmd') $true 'Bash launcher uses shared Git shell setup'
Assert-Equal $minttyLauncher.Contains('lib_git_shell.cmd') $true 'Mintty launcher uses shared Git shell setup'
Assert-Equal $gitShellLibrary.Contains('setup_external_git_bash.ps1') $true 'Shared Git shell setup uses external Git setup'
Assert-Equal $initScript.Contains('select-git-installation.ps1') $true 'CMD init uses shared Git selection'
Assert-Equal $powershellProfile.Contains('Select-GitInstallation') $true 'PowerShell profile uses shared Git selection'
Assert-Equal $bashStartup.Contains('select-git-installation.ps1') $true 'Bash startup uses shared Git selection'
Assert-Equal $gitShellLibrary.Contains('ucrt64') $true 'Shared setup supports UCRT64'
Assert-Equal $gitShellLibrary.Contains('mingw64') $true 'Shared setup supports MinGW64'
Assert-Equal $gitShellLibrary.Contains('mingw32') $true 'Shared setup supports MinGW32'
Assert-Equal $gitShellLibrary.Contains('conemu-msys2-64.exe') $true 'Bash setup keeps ConEmu integration'
Assert-Equal $minttyLauncher.Contains('"%shellCmd%" /bin/bash -l -i') $true 'Mintty launcher starts an interactive login Bash'

if (!(Test-Path -LiteralPath $BashExecutable -PathType Leaf)) {
    throw "Git Bash is required; provide -BashExecutable. Not found: $BashExecutable"
}
$cygpath = Join-Path (Split-Path $BashExecutable -Parent) 'cygpath.exe'
if (!(Test-Path -LiteralPath $cygpath -PathType Leaf)) { throw "Not found: $cygpath" }
$bashSource = [IO.File]::ReadAllText((Join-Path $repoRoot 'vendor\cmder.sh'))
$bashMatch = [regex]::Match($bashSource, '(?ms)^__cmder_add_git_native_bin\(\) \{\r?\n.*?(?=^PATH="\$\{CMDER_ROOT\}/bin:)')
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
    $launcherVendorGit = Join-Path $fixtureRoot 'vendor\git-for-windows'
    $null = New-Item -ItemType Directory -Path (Join-Path $launcherVendorGit 'cmd') -Force
    [IO.File]::WriteAllText((Join-Path $launcherVendorGit 'cmd\git.exe'), '')
    $selectorCmderRoot = Join-Path $fixtureRoot 'Selector Cmder'
    $selectorVendorRoot = Join-Path $selectorCmderRoot 'vendor\git-for-windows'
    $selectorUserRoot = Join-Path $fixtureRoot 'Selector User Git'
    $selectorOtherRoot = Join-Path $fixtureRoot 'Selector Other Git'
    foreach ($gitRoot in @($selectorVendorRoot, $selectorUserRoot, $selectorOtherRoot)) {
        $commandDirectory = Join-Path $gitRoot 'cmd'
        $null = New-Item -ItemType Directory -Path $commandDirectory -Force
        [IO.File]::WriteAllText((Join-Path $commandDirectory 'git.exe'), '')
    }
    $null = New-Item -ItemType Directory -Path (Join-Path $selectorUserRoot 'bin'), (Join-Path $selectorUserRoot 'ucrt64\bin') -Force
    [IO.File]::WriteAllText((Join-Path $selectorVendorRoot 'cmd\version.txt'), '2.50.0.windows.1')
    [IO.File]::WriteAllText((Join-Path $selectorUserRoot 'cmd\version.txt'), '2.52.0.windows.1')
    [IO.File]::WriteAllText((Join-Path $selectorOtherRoot 'cmd\version.txt'), '2.40.0.windows.1')
    $systemPath = 'C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0'
    $env:Path = "$($selectorUserRoot)\cmd;$($selectorOtherRoot)\cmd;$systemPath"
    $env:GIT_INSTALL_ROOT = ''
    $selection = Select-GitInstallation -CmderRoot $selectorCmderRoot
    Assert-Equal $selection.GitRoot $selectorUserRoot 'Selection prefers a PATH Git at least as new as bundled Git'
    Assert-Equal $selection.GitType 'USER' 'PATH Git selection is classified as user Git'
    Assert-Equal $selection.GitPathUser $selectorUserRoot 'Selected PATH Git is reported for PATH replacement'

    $env:GIT_INSTALL_ROOT = $selectorOtherRoot
    $selection = Select-GitInstallation -CmderRoot $selectorCmderRoot
    Assert-Equal $selection.GitRoot $selectorOtherRoot 'A valid explicit Git root takes precedence'
    Assert-Equal $selection.GitType 'USER' 'Explicit Git root is classified as user Git'

    $env:GIT_INSTALL_ROOT = ''
    $env:Path = "$($selectorOtherRoot)\cmd;$systemPath"
    $selection = Select-GitInstallation -CmderRoot $selectorCmderRoot
    Assert-Equal $selection.GitRoot $selectorVendorRoot 'Older PATH Git falls back to bundled Git'
    Assert-Equal $selection.GitPathUser $selectorOtherRoot 'Older PATH Git is returned for PATH replacement'

    $env:Path = "$($selectorUserRoot)\cmd;$systemPath"
    $selection = Select-GitInstallation -CmderRoot $selectorCmderRoot -FastInit $true
    Assert-Equal $selection.GitRoot $selectorVendorRoot 'Fast init prefers bundled Git without version scanning'

    $env:Path = $systemPath
    $selection = Select-GitInstallation -CmderRoot (Join-Path $fixtureRoot 'No Git Cmder')
    Assert-Equal $selection.GitRoot $null 'Selection returns no Git when neither PATH nor bundled Git is available'

    $env:Path = "$($selectorUserRoot)\cmd;$systemPath"
    $selection = Select-GitInstallation -CmderRoot (Join-Path $fixtureRoot 'No Git Cmder')
    Assert-Equal $selection.GitRoot $selectorUserRoot 'PATH Git is selected when no bundled Git is available'

    $shimDirectory = Join-Path $fixtureRoot 'Selector Shim'
    $null = New-Item -ItemType Directory -Path $shimDirectory -Force
    [IO.File]::WriteAllText((Join-Path $shimDirectory 'git.exe'), '')
    [IO.File]::WriteAllText((Join-Path $shimDirectory 'git.shim'), "path = $(Join-Path $selectorUserRoot 'cmd\git.exe')")
    $env:Path = "$shimDirectory;$systemPath"
    $selection = Select-GitInstallation -CmderRoot $selectorCmderRoot
    Assert-Equal $selection.GitRoot $selectorUserRoot 'Selection resolves Git shims to their installation root'

    foreach ($shell in @('bash', 'mintty')) {
        foreach ($debug in @('0', '1')) {
            $launcher = Join-Path $repoRoot "vendor\start_git_$shell.cmd"
            $cmdFile = Join-Path $fixtureRoot 'test-launcher-debug.cmd'
            $cmdText = @(
                '@echo off'
                "set `"CMDER_ROOT=$fixtureRoot`""
                "set `"ProgramFiles=$fixtureRoot`""
                "set `"ProgramFiles(x86)=$fixtureRoot`""
                'set "ConEmuDir="'
                'set "DEBUG=1"'
                "set `"debug_output=$debug`""
                'set "fast_init=1"'
                'set "verbose_output=0"'
                "call `"$launcher`""
            ) -join "`r`n"
            [IO.File]::WriteAllText($cmdFile, $cmdText + "`r`n", [Text.Encoding]::ASCII)
            $output = & $env:ComSpec /d /c "`"$cmdFile`""
            Assert-Equal $LASTEXITCODE 0 "$shell launcher parses with debug_output=$debug"
            $debugLines = @($output | Where-Object { $_ -match "DEBUG\(start_git_$shell\):" })
            Assert-Equal ($debugLines.Count -gt 0) ($debug -eq '1') "$shell debug messages follow debug_output"
        }
    }

    $selectedShellGit = Join-Path $fixtureRoot 'Selected Shell Git'
    $selectedShellProfiles = Join-Path $selectedShellGit 'etc\profile.d'
    $null = New-Item -ItemType Directory -Path (Join-Path $selectedShellGit 'cmd'), (Join-Path $selectedShellGit 'usr\bin'), (Join-Path $selectedShellGit 'ucrt64\bin'), $selectedShellProfiles -Force
    foreach ($executable in @('git.exe', 'bash.exe', 'mintty.exe')) {
        $directory = if ($executable -eq 'git.exe') { Join-Path $selectedShellGit 'cmd' } else { Join-Path $selectedShellGit 'usr\bin' }
        [IO.File]::WriteAllText((Join-Path $directory $executable), '')
    }
    [IO.File]::WriteAllText((Join-Path $selectedShellGit 'ucrt64\bin\git.exe'), '')
    [IO.File]::WriteAllText((Join-Path $selectedShellProfiles 'zz-cmder_exinit.sh'), '')
    foreach ($shell in @('bash', 'mintty')) {
        $helper = Join-Path $repoRoot 'vendor\lib\lib_git_shell.cmd'
        $cmdText = @(
            '@echo off'
            "set `"CMDER_ROOT=$fixtureRoot`""
            "set `"GIT_INSTALL_ROOT=$selectedShellGit`""
            'set "fast_init=0"'
            'set "MSYSTEM="'
            'set "debug_output=1"'
            'set "verbose_output=0"'
            "call `"$helper`" initialize $shell start_git_$shell"
            'echo SELECTED_ROOT=%GIT_INSTALL_ROOT%'
            'echo SELECTED_SHELL=%shellCmd%'
            'echo SELECTED_MSYSTEM=%MSYSTEM%'
        ) -join "`r`n"
        [IO.File]::WriteAllText($cmdFile, $cmdText + "`r`n", [Text.Encoding]::ASCII)
        $output = & $env:ComSpec /d /c "`"$cmdFile`""
        Assert-Equal $LASTEXITCODE 0 "$shell launcher selects the explicit Git root"
        Assert-Equal (@($output | Where-Object { $_ -eq "SELECTED_ROOT=$selectedShellGit" }).Count) 1 "$shell launcher uses selected Git root"
        Assert-Equal (@($output | Where-Object { $_ -eq "SELECTED_SHELL=$(Join-Path $selectedShellGit "usr\bin\$shell.exe")" }).Count) 1 "$shell launcher uses shell executable from selected Git"
        Assert-Equal (@($output | Where-Object { $_ -eq 'SELECTED_MSYSTEM=UCRT64' }).Count) 1 "$shell launcher derives MSYSTEM from selected Git"
    }

    $bundledRoot = Join-Path $fixtureRoot 'Cmder (test)'
    $bundledGit = Join-Path $bundledRoot 'vendor\git-for-windows'
    $null = New-Item -ItemType Directory -Path (Join-Path $bundledGit 'cmd'), (Join-Path $bundledGit 'usr\bin'), (Join-Path $bundledGit 'etc\profile.d') -Force
    [IO.File]::WriteAllText((Join-Path $bundledGit 'cmd\git.exe'), '')
    [IO.File]::WriteAllText((Join-Path $bundledGit 'usr\bin\bash.exe'), '')
    $legacyHook = Join-Path $bundledGit 'etc\profile.d\cmder.sh'
    [IO.File]::WriteAllText($legacyHook, '')
    [IO.File]::WriteAllText((Join-Path $bundledGit 'etc\profile.d\zz-cmder.sh'), '')
    $helper = Join-Path $repoRoot 'vendor\lib\lib_git_shell.cmd'
    $cmdText = @(
        '@echo off'
        "set `"CMDER_ROOT=$bundledRoot`""
        'set "debug_output=1"'
        'set "fast_init=1"'
        'set "verbose_output=0"'
        "call `"$helper`" initialize bash start_git_bash"
    ) -join "`r`n"
    [IO.File]::WriteAllText($cmdFile, $cmdText + "`r`n", [Text.Encoding]::ASCII)
    $output = & $env:ComSpec /d /c "`"$cmdFile`""
    Assert-Equal $LASTEXITCODE 0 'Bundled shell setup parses with debug output'
    Assert-Equal (@($output | Where-Object { $_ -match 'DEBUG\(start_git_bash\): Removing legacy Bash hook:' }).Count) 1 'Bundled hook cleanup reports through console debug output'
    Assert-Equal (Test-Path -LiteralPath $legacyHook) $false 'Bundled hook cleanup still runs with debug output'

    $cases = @(
        @{ Name = 'UCRT64 only'; Dirs = @('ucrt64'); Native = 'ucrt64' },
        @{ Name = 'MinGW64 only'; Dirs = @('mingw64'); Native = 'mingw64' },
        @{ Name = 'MinGW32 only'; Dirs = @('mingw32'); Native = 'mingw32' },
        @{ Name = 'Mixed layouts'; Dirs = @('ucrt64', 'mingw64', 'mingw32'); Native = 'ucrt64' },
        @{ Name = 'Older mixed layouts'; Dirs = @('mingw64', 'mingw32'); Native = 'mingw64' },
        @{ Name = 'No native directory'; Dirs = @(); Native = '' }
    )
    $basePath = $systemPath
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
        $bashText = @'
debug_output() { :; }
__cmder_find_git_root() { GIT_INSTALL_ROOT="$fixture_git_root"; }
fixture_git_root="$1"
PROCESSOR_ARCHITECTURE="$2"
PROCESSOR_ARCHITEW6432="$3"
MINGW_PREFIX="/layout-test-missing-prefix"
PATH="/layout-test-base"
'@ + "`n" + $bashMatch.Value + "`n" + 'printf ''%s\n'' "$PATH"' + "`n"
        [IO.File]::WriteAllText($bashFile, ($bashText -replace "`r`n", "`n"), (New-Object Text.UTF8Encoding($false)))
        $posixGitRoot = & $cygpath -u $gitRoot
        $posixScript = & $cygpath -u $bashFile
        foreach ($architecture in $architectures) {
            $env:PROCESSOR_ARCHITECTURE = $architecture.Process
            $env:PROCESSOR_ARCHITEW6432 = $architecture.Wow64
            $actual = & $BashExecutable --noprofile --norc $posixScript $posixGitRoot $architecture.Process $architecture.Wow64
            if ($LASTEXITCODE) { throw 'Bash selection failed.' }
            $expectedBash = "${posixGitRoot}/bin:/layout-test-base"
            if ($architecture.Native) { $expectedBash = (& $cygpath -u $architecture.Native) + ":$expectedBash" }
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

    $startupRoot = Join-Path $fixtureRoot 'Bash startup'
    $null = New-Item -ItemType Directory -Path (Join-Path $startupRoot 'config') -Force
    $startupVendor = Join-Path $startupRoot 'vendor'
    $startupLib = Join-Path $startupVendor 'lib'
    $null = New-Item -ItemType Directory -Path $startupLib -Force
    $startupGitRoot = Join-Path $startupRoot 'Selected Git'
    $null = New-Item -ItemType Directory -Path (Join-Path $startupGitRoot 'cmd'), (Join-Path $startupGitRoot 'bin'), (Join-Path $startupGitRoot 'ucrt64\bin') -Force
    [IO.File]::WriteAllText((Join-Path $startupGitRoot 'cmd\git.exe'), '')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'vendor\cmder.sh') -Destination $startupVendor
    Copy-Item -LiteralPath (Join-Path $repoRoot 'vendor\lib\lib_console.sh') -Destination $startupLib
    $startupProfile = Join-Path $startupRoot 'config\user_profile.sh'
    [IO.File]::WriteAllText($startupProfile, '')
    [IO.File]::WriteAllText((Join-Path $startupRoot '.bashrc'), "export PATH='/unexpected-bashrc'`n")
    $posixStartupRoot = & $cygpath -u $startupRoot
    $posixStartupGitRoot = & $cygpath -u $startupGitRoot
    $mountedBins = & $BashExecutable --noprofile --norc -c 'for dir in /ucrt64/bin /mingw64/bin /clangarm64/bin /mingw32/bin; do if [ -d $dir ]; then echo $dir; fi; done'
    $mountedBin = @($mountedBins)[0]
    if (!$mountedBin) { throw 'No native bin found in the Git Bash runtime.' }
    $startupScript = Join-Path $fixtureRoot 'bundled-startup.sh'
    [IO.File]::WriteAllText($startupScript, 'export CMDER_ROOT="$1" HOME="$1" MINGW_PREFIX="${3%/bin}" PATH="$4" GIT_INSTALL_ROOT="$5" PROCESSOR_ARCHITECTURE=AMD64 PROCESSOR_ARCHITEW6432=; unset CMDER_USER_CONFIG DEBUG debug_output; . "$2"; printf "%s\n" "$PATH"' + "`n")
    $posixStartupScript = & $cygpath -u $startupScript
    $baseline = "${posixStartupRoot}/bin:${mountedBin}:/usr/bin:/c/Program Files/Custom/bin:/usr/bin/core_perl"
    $actual = & $BashExecutable --noprofile --norc $posixStartupScript $posixStartupRoot $posixSource $mountedBin $baseline $posixStartupGitRoot
    Assert-Equal $LASTEXITCODE 0 'Bash startup with the standard Git Bash PATH'
    Assert-Equal $actual "${posixStartupRoot}/bin:${posixStartupRoot}/vendor/bin:${posixStartupGitRoot}/ucrt64/bin:${posixStartupGitRoot}/bin:${baseline}" 'Cmder uses selected Git tools and prepends its own bins without forcing .bashrc'

    $posixShim = & $cygpath -u (Join-Path $repoRoot 'vendor\cmder_exinit')
    $debugScript = Join-Path $fixtureRoot 'test-bash-debug.sh'
    $debugLog = Join-Path $fixtureRoot 'bash-debug.log'
    [IO.File]::WriteAllText($debugScript, 'export CMDER_ROOT="$1" HOME="$1" MINGW_PREFIX="${3%/bin}" PATH="$4" GIT_INSTALL_ROOT="$7" PROCESSOR_ARCHITECTURE=AMD64 PROCESSOR_ARCHITEW6432= DEBUG=1; unset CMDER_USER_CONFIG CMDER_EXINIT debug_output; if [ "$5" != unset ]; then export debug_output="$5"; fi; . "$2" 2>"$6"; printf "%s\n" "$PATH"' + "`n")
    $posixDebugScript = & $cygpath -u $debugScript
    $posixDebugLog = & $cygpath -u $debugLog
    foreach ($entry in @($posixSource, $posixShim)) {
        foreach ($debug in @('unset', '0', '-1', '1', '2')) {
            $actual = & $BashExecutable --noprofile --norc $posixDebugScript $posixStartupRoot $entry $mountedBin $baseline $debug $posixDebugLog $posixStartupGitRoot
            Assert-Equal $LASTEXITCODE 0 "Bash startup via $entry with debug_output=$debug"
            Assert-Equal $actual "${posixStartupRoot}/bin:${posixStartupRoot}/vendor/bin:${posixStartupGitRoot}/ucrt64/bin:${posixStartupGitRoot}/bin:${baseline}" "Debug output preserves startup PATH via $entry"
            $debugText = [IO.File]::ReadAllText($debugLog)
            Assert-Equal ($debugText -match '(?m)^\d{2}:\d{2}:\d{2} DEBUG\(cmder\.sh\): Cmder root:') ($debug -in @('1', '2')) "Bash debug output follows debug_output=$debug via $entry"
            if ($entry -eq $posixShim) {
                Assert-Equal ($debugText -match '(?m)^\d{2}:\d{2}:\d{2} DEBUG\(cmder_exinit\): Sourcing startup script:') ($debug -in @('1', '2')) "Shim debug output follows debug_output=$debug"
            }
        }
    }

    $startupConsole = Join-Path $startupLib 'lib_console.sh'
    $hiddenConsole = Join-Path $startupLib 'lib_console.hidden'
    Rename-Item -LiteralPath $startupConsole -NewName 'lib_console.hidden'
    try {
        [IO.File]::WriteAllText($debugScript, 'export CMDER_ROOT="$1" GIT_INSTALL_ROOT="$4"; unset CMDER_EXINIT; . "$2" 2>"$3"' + "`n")
        foreach ($entry in @($posixSource, $posixShim)) {
            & $BashExecutable --noprofile --norc $posixDebugScript $posixStartupRoot $entry $posixDebugLog $posixStartupGitRoot
            Assert-Equal $LASTEXITCODE 1 "Missing console library fails via $entry"
            Assert-Equal ([IO.File]::ReadAllText($debugLog).Contains('Cannot read console library:')) $true "Missing console library reports an error via $entry"
        }
    } finally {
        Rename-Item -LiteralPath $hiddenConsole -NewName 'lib_console.sh'
    }

    [IO.File]::WriteAllText($startupProfile, "export PATH='/usr/bin:/custom/bin'`n")
    $actual = & $BashExecutable --noprofile --norc $posixStartupScript $posixStartupRoot $posixSource $mountedBin $baseline $posixStartupGitRoot
    Assert-Equal $LASTEXITCODE 0 'Bash startup with a Cmder profile PATH reset'
    Assert-Equal $actual "${posixStartupGitRoot}/ucrt64/bin:/usr/bin:/custom/bin" 'Selected Git native bin is restored after a Cmder profile resets PATH'

    $installer = Join-Path $repoRoot 'vendor\setup_external_git_bash.ps1'
    $installerAst = [System.Management.Automation.Language.Parser]::ParseFile($installer, [ref]$null, [ref]$parseErrors)
    if ($parseErrors.Count) { throw $parseErrors[0].Message }
    foreach ($definition in $installerAst.EndBlock.Statements) {
        if ($definition -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
            . ([scriptblock]::Create($definition.Extent.Text))
        }
    }

    $externalRoot = Join-Path $fixtureRoot 'External Git'
    $externalProfiles = Join-Path $externalRoot 'etc\profile.d'
    $externalHook = Join-Path $externalProfiles 'zz-cmder_exinit.sh'
    $legacyHook = Join-Path $externalProfiles 'cmder_exinit.sh'
    $externalCmder = Join-Path $fixtureRoot "External Cmder's root"
    $null = New-Item -ItemType Directory -Path $externalProfiles, (Join-Path $externalCmder 'vendor'), (Join-Path $externalCmder 'config\profile.d')
    $externalVendor = Join-Path $externalCmder 'vendor'
    $null = New-Item -ItemType Directory -Path (Join-Path $externalVendor 'bin'), (Join-Path $externalVendor 'psmodules')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'vendor\bin\select-git-installation.ps1') -Destination (Join-Path $externalVendor 'bin')
    Copy-Item -LiteralPath $modulePath -Destination (Join-Path $externalVendor 'psmodules\Cmder.ps1')
    $sharedStartup = Join-Path $externalCmder 'vendor\cmder.sh'
    Copy-Item -LiteralPath (Join-Path $repoRoot 'vendor\cmder_exinit'), (Join-Path $repoRoot 'vendor\cmder.sh') -Destination (Join-Path $externalCmder 'vendor')
    $externalLib = Join-Path $externalCmder 'vendor\lib'
    $null = New-Item -ItemType Directory -Path $externalLib
    Copy-Item -LiteralPath (Join-Path $repoRoot 'vendor\lib\lib_console.sh') -Destination $externalLib
    [IO.File]::WriteAllText((Join-Path $externalCmder 'config\profile.d\with spaces.sh'), "printf '%s\n' fragment`n")
    [IO.File]::WriteAllText((Join-Path $externalCmder 'config\user_profile.sh'), "printf '%s\n' profile`n")
    [IO.File]::WriteAllText($legacyHook, 'existing legacy hook')
    $fixtureProfile = "C:\Fixture Users\O'Neil"
    $installArgs = @{ GitRoot = $externalRoot; CmderRoot = $externalCmder; UserProfile = $fixtureProfile; ComputerName = 'HOST-A' }
    $optOut = Join-Path $externalCmder 'config\user_cmder_state.txt'
    & {
        function Read-Host { throw 'Migrating an existing hook must not prompt.' }
        Install-CmderExternalGitHook @installArgs
    }
    $legacyBackups = @(Get-ChildItem -LiteralPath $externalProfiles -Filter 'cmder_exinit.sh.*.bak' -File)
    Assert-Equal (Test-Path -LiteralPath $legacyHook) $false 'Legacy external hook is removed from the active profile'
    Assert-Equal $legacyBackups.Count 1 'Legacy external hook is preserved in a dated backup'
    Assert-Equal ([IO.File]::ReadAllText($legacyBackups[0].FullName)) 'existing legacy hook' 'Dated backup preserves the old hook contents'
    Assert-Equal ($legacyBackups[0].Name -match '\.sh$') $false 'Dated backup is not sourced as a shell hook'
    Assert-Equal (Test-Path -LiteralPath $externalHook) $true 'Legacy external hook is automatically replaced with the late-running hook'
    [IO.File]::WriteAllText($legacyHook, 'duplicate legacy hook')
    & {
        function Read-Host { throw 'Cleaning up a duplicate legacy hook must not prompt.' }
        Install-CmderExternalGitHook @installArgs
    }
    $legacyBackups = @(Get-ChildItem -LiteralPath $externalProfiles -Filter 'cmder_exinit.sh.*.bak' -File)
    Assert-Equal (Test-Path -LiteralPath $legacyHook) $false 'Legacy external hook is backed up when the new hook already exists'
    Assert-Equal $legacyBackups.Count 2 'Repeated legacy-hook cleanup uses a distinct dated backup'
    $posixExternalHook = & $cygpath -u $externalHook
    $posixExternalCmder = & $cygpath -u $externalCmder
    $posixSelectorUserRoot = & $cygpath -u $selectorUserRoot
    $externalStartup = Join-Path $fixtureRoot 'external-startup.sh'
    [IO.File]::WriteAllText($externalStartup, 'unset CMDER_ROOT CMDER_USER_CONFIG CMDER_EXINIT DEBUG debug_output; export USERPROFILE="$2" PATH="$3" MINGW_PREFIX="${4%/bin}" GIT_INSTALL_ROOT="$5"; . "$1"; . "$1"; printf "%s\n" "$PATH"' + "`n")
    $posixExternalStartup = & $cygpath -u $externalStartup
    $actual = & $BashExecutable --noprofile --norc $posixExternalStartup $posixExternalHook $fixtureProfile $baseline $mountedBin $posixSelectorUserRoot
    Assert-Equal $LASTEXITCODE 0 'Generated external hook is valid Bash'
    Assert-Equal ($actual -join "`n") "fragment`nprofile`n${posixExternalCmder}/bin:${posixExternalCmder}/vendor/bin:${posixSelectorUserRoot}/ucrt64/bin:${posixSelectorUserRoot}/bin:${baseline}" 'External hook uses the selected Git root, preserves PATH, and runs once'
    $actual = & $BashExecutable --noprofile --norc $posixExternalStartup $posixExternalHook 'C:\Other User' $baseline $mountedBin $posixSelectorUserRoot
    Assert-Equal $actual $baseline 'Generated hook does not enable Cmder for another Windows profile'
    [IO.File]::AppendAllText($sharedStartup, "printf '%s\n' updated`n")
    $actual = & $BashExecutable --noprofile --norc $posixExternalStartup $posixExternalHook $fixtureProfile $baseline $mountedBin $posixSelectorUserRoot
    Assert-Equal (@($actual)[2]) 'updated' 'Installed external shim sees edits to the shared startup without reinstalling'
    Remove-Item -LiteralPath $externalHook
    & {
        function Read-Host { 'n' }
        Install-CmderExternalGitHook @installArgs
    }
    Assert-Equal (Test-Path -LiteralPath $optOut) $false 'Not now does not save a permanent opt-out'
    & {
        function Read-Host { 'never' }
        Install-CmderExternalGitHook @installArgs
    }
    & {
        function Read-Host { throw 'An explicit opt-out must suppress future setup offers.' }
        Install-CmderExternalGitHook @installArgs
    }
    Assert-Equal (Test-Path -LiteralPath $externalHook) $false 'Skipping setup leaves the external Git installation unchanged'
    $optOutContent = [IO.File]::ReadAllText($optOut)
    Assert-Equal ($optOutContent.Contains('Remove an entry')) $true 'Portable opt-out explains how to restore the offer'
    Assert-Equal ($optOutContent.Contains('[external-git-bash-opt-outs]')) $true 'Portable opt-outs have their own section'
    Assert-Equal ($optOutContent.Contains("HOST-A`t$externalRoot")) $true 'Portable opt-out identifies the computer and Git installation'
    & {
        function Read-Host { 'never' }
        Install-CmderExternalGitHook -GitRoot $externalRoot -CmderRoot $externalCmder -UserProfile $fixtureProfile -ComputerName 'HOST-B'
    }
    Assert-Equal ([IO.File]::ReadAllText($optOut).Contains("HOST-B`t$externalRoot")) $true 'The same Git path on another computer has an independent offer'
    & {
        function Read-Host { throw 'Matching computer and Git path must suppress the offer.' }
        Install-CmderExternalGitHook -GitRoot $externalRoot.ToUpperInvariant() -CmderRoot $externalCmder -UserProfile $fixtureProfile -ComputerName 'host-b'
    }
    $secondRoot = Join-Path $fixtureRoot 'Second Git'
    $null = New-Item -ItemType Directory -Path (Join-Path $secondRoot 'etc\profile.d') -Force
    & {
        function Read-Host { 'never' }
        Install-CmderExternalGitHook -GitRoot $secondRoot -CmderRoot $externalCmder -UserProfile $fixtureProfile -ComputerName 'HOST-A'
    }
    $optOutContent = [IO.File]::ReadAllText($optOut)
    Assert-Equal ($optOutContent.Contains($externalRoot) -and $optOutContent.Contains($secondRoot)) $true 'Opting out another Git preserves existing entries'
    Save-CmderExternalGitOptOut -ConfigDirectory (Split-Path $optOut -Parent) -GitRoot $secondRoot.ToUpperInvariant() -ComputerName 'host-a'
    Assert-Equal ([IO.File]::ReadAllText($optOut)) $optOutContent 'Saving the same Git path again does not duplicate it'
    $defaultHostRoot = Join-Path $fixtureRoot 'Default host Git'
    $null = New-Item -ItemType Directory -Path (Join-Path $defaultHostRoot 'etc\profile.d') -Force
    & {
        function Read-Host { 'never' }
        Install-CmderExternalGitHook -GitRoot $defaultHostRoot -CmderRoot $externalCmder -UserProfile $fixtureProfile
    }
    Assert-Equal ([IO.File]::ReadAllText($optOut).Contains("$([Environment]::MachineName)`t$defaultHostRoot")) $true 'Default opt-out uses the current computer name'
    [IO.File]::AppendAllText($optOut, '# User note without a final newline')
    $thirdRoot = Join-Path $fixtureRoot 'Third Git'
    Save-CmderExternalGitOptOut -ConfigDirectory (Split-Path $optOut -Parent) -GitRoot $thirdRoot -ComputerName 'HOST-A'
    Assert-Equal ([IO.File]::ReadAllText($optOut).Contains("# User note without a final newline`r`nHOST-A`t$thirdRoot")) $true 'Appending preserves a user-edited file without a final newline'
    $otherEntry = "HOST-C`t$externalRoot"
    [IO.File]::AppendAllText($optOut, "[other-state]`r`n$otherEntry`r`nsetting=value`r`n")
    $beforeAppend = [IO.File]::ReadAllText($optOut)
    Assert-Equal (Test-CmderExternalGitOptOut -Content $beforeAppend -Entry $otherEntry) $false 'A matching line in another section does not suppress the offer'
    Save-CmderExternalGitOptOut -ConfigDirectory (Split-Path $optOut -Parent) -GitRoot $externalRoot -ComputerName 'HOST-C'
    $afterAppend = [IO.File]::ReadAllText($optOut)
    Assert-Equal ($afterAppend.StartsWith($beforeAppend)) $true 'Appending an opt-out preserves other sections and their contents'
    Assert-Equal (Test-CmderExternalGitOptOut -Content $afterAppend -Entry $otherEntry) $true 'A later opt-out section is read correctly'
    Assert-Equal (Test-CmderExternalGitOptOut -Content $afterAppend -Entry "HOST-A`t$externalRoot") $true 'An earlier opt-out section remains readable'
    $movedCmder = Join-Path $fixtureRoot 'Moved Cmder'
    $null = New-Item -ItemType Directory -Path (Join-Path $movedCmder 'config') -Force
    Copy-Item -LiteralPath $optOut -Destination (Join-Path $movedCmder 'config')
    & {
        function Read-Host { throw 'A copied portable opt-out must suppress the offer.' }
        Install-CmderExternalGitHook -GitRoot $externalRoot.ToUpperInvariant() -CmderRoot $movedCmder -UserProfile $fixtureProfile -ComputerName 'host-a'
    }

    $remainingLines = @([IO.File]::ReadAllLines($optOut) | Where-Object { $_ -ne "HOST-A`t$externalRoot" })
    [IO.File]::WriteAllLines($optOut, [string[]]$remainingLines)
    Assert-Equal ([IO.File]::ReadAllText($optOut).Contains("HOST-B`t$externalRoot")) $true 'Removing one computer entry preserves another computer opt-out'
    & {
        function Read-Host { 'yes' }
        Install-CmderExternalGitHook @installArgs
    }
    Assert-Equal (Test-Path -LiteralPath $externalHook) $true 'Removing a Git path re-enables its setup offer'
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

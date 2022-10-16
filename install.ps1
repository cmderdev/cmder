# Issue Tracker: https://github.com/ScoopInstaller/Install/issues
# Unlicense License:
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>

<#
.SYNOPSIS
    Scoop installer.
.DESCRIPTION
    The installer of Scoop. For details please check the website and wiki.
.PARAMETER ScoopDir
    Specifies Scoop root path.
    If not specified, Scoop will be installed to '$env:USERPROFILE\scoop'.
.PARAMETER ScoopGlobalDir
    Specifies directory to store global apps.
    If not specified, global apps will be installed to '$env:ProgramData\scoop'.
.PARAMETER ScoopCacheDir
    Specifies cache directory.
    If not specified, caches will be downloaded to '$ScoopDir\cache'.
.PARAMETER NoProxy
    Bypass system proxy during the installation.
.PARAMETER Proxy
    Specifies proxy to use during the installation.
.PARAMETER ProxyCredential
    Specifies credential for the given prxoy.
.PARAMETER ProxyUseDefaultCredentials
    Use the credentials of the current user for the proxy server that is specified by the -Proxy parameter.
.PARAMETER RunAsAdmin
    Force to run the installer as administrator.
.LINK
    https://scoop.sh
.LINK
    https://github.com/ScoopInstaller/Scoop/wiki
#>
param(
    [String] $ScoopDir,
    [String] $ScoopGlobalDir,
    [String] $ScoopCacheDir,
    [Switch] $NoProxy,
    [Uri] $Proxy,
    [System.Management.Automation.PSCredential] $ProxyCredential,
    [Switch] $ProxyUseDefaultCredentials,
    [Switch] $RunAsAdmin
)

# Disable StrictMode in this script
Set-StrictMode -Off

function Write-InstallInfo {
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $String,
        [Parameter(Mandatory = $False, Position = 1)]
        [System.ConsoleColor] $ForegroundColor = $host.UI.RawUI.ForegroundColor
    )

    $backup = $host.UI.RawUI.ForegroundColor

    if ($ForegroundColor -ne $host.UI.RawUI.ForegroundColor) {
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
    }

    Write-Output "$String"

    $host.UI.RawUI.ForegroundColor = $backup
}

function Deny-Install {
    param(
        [String] $message,
        [Int] $errorCode = 1
    )

    Write-InstallInfo -String $message -ForegroundColor DarkRed
    Write-InstallInfo "Abort."

    # Don't abort if invoked with iex that would close the PS session
    if ($IS_EXECUTED_FROM_IEX) {
        break
    } else {
        exit $errorCode
    }
}

function Test-ValidateParameter {
    if ($null -eq $Proxy -and ($null -ne $ProxyCredential -or $ProxyUseDefaultCredentials)) {
        Deny-Install "Provide a valid proxy URI for the -Proxy parameter when using the -ProxyCredential or -ProxyUseDefaultCredentials."
    }

    if ($ProxyUseDefaultCredentials -and $null -ne $ProxyCredential) {
        Deny-Install "ProxyUseDefaultCredentials is conflict with ProxyCredential. Don't use the -ProxyCredential and -ProxyUseDefaultCredentials together."
    }
}

function Test-IsAdministrator {
    return ([Security.Principal.WindowsPrincipal]`
            [Security.Principal.WindowsIdentity]::GetCurrent()`
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Prerequisite {
    # Scoop requires PowerShell 5 at least
    if (($PSVersionTable.PSVersion.Major) -lt 5) {
        Deny-Install "PowerShell 5 or later is required to run Scoop. Go to https://microsoft.com/powershell to get the latest version of PowerShell."
    }

    # Scoop requires TLS 1.2 SecurityProtocol, which exists in .NET Framework 4.5+
    if ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -notcontains 'Tls12') {
        Deny-Install "Scoop requires .NET Framework 4.5+ to work. Go to https://microsoft.com/net/download to get the latest version of .NET Framework."
    }

    # Ensure Robocopy.exe is accessible
    if (!([bool](Get-Command -Name 'robocopy' -ErrorAction SilentlyContinue))) {
        Deny-Install "Scoop requires 'C:\Windows\System32\Robocopy.exe' to work. Please make sure 'C:\Windows\System32' is in your PATH."
    }

    # Detect if RunAsAdministrator, there is no need to run as administrator when installing Scoop.
    if (!$RunAsAdmin -and (Test-IsAdministrator)) {
        Deny-Install "Running the installer as administrator is disabled by default, see https://github.com/ScoopInstaller/Install#for-admin for details."
    }

    # Show notification to change execution policy
    $allowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')
    if ((Get-ExecutionPolicy).ToString() -notin $allowedExecutionPolicy) {
        Deny-Install "PowerShell requires an execution policy in [$($allowedExecutionPolicy -join ", ")] to run Scoop. For example, to set the execution policy to 'RemoteSigned' please run 'Set-ExecutionPolicy RemoteSigned -Scope CurrentUser'."
    }

    # Test if scoop is installed, by checking if scoop command exists.
    if ([bool](Get-Command -Name 'scoop' -ErrorAction SilentlyContinue)) {
        Deny-Install "Scoop is already installed. Run 'scoop update' to get the latest version."
    }
}

function Optimize-SecurityProtocol {
    # .NET Framework 4.7+ has a default security protocol called 'SystemDefault',
    # which allows the operating system to choose the best protocol to use.
    # If SecurityProtocolType contains 'SystemDefault' (means .NET4.7+ detected)
    # and the value of SecurityProtocol is 'SystemDefault', just do nothing on SecurityProtocol,
    # 'SystemDefault' will use TLS 1.2 if the webrequest requires.
    $isNewerNetFramework = ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -contains 'SystemDefault')
    $isSystemDefault = ([System.Net.ServicePointManager]::SecurityProtocol.Equals([System.Net.SecurityProtocolType]::SystemDefault))

    # If not, change it to support TLS 1.2
    if (!($isNewerNetFramework -and $isSystemDefault)) {
        # Set to TLS 1.2 (3072), then TLS 1.1 (768), and TLS 1.0 (192). Ssl3 has been superseded,
        # https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netframework-4.5
        [System.Net.ServicePointManager]::SecurityProtocol = 3072 -bor 768 -bor 192
        Write-Verbose "SecurityProtocol has been updated to support TLS 1.2"
    }
}

function Get-Downloader {
    $downloadSession = New-Object System.Net.WebClient

    # Set proxy to null if NoProxy is specificed
    if ($NoProxy) {
        $downloadSession.Proxy = $null
    } elseif ($Proxy) {
        # Prepend protocol if not provided
        if (!$Proxy.IsAbsoluteUri) {
            $Proxy = New-Object System.Uri("http://" + $Proxy.OriginalString)
        }

        $Proxy = New-Object System.Net.WebProxy($Proxy)

        if ($null -ne $ProxyCredential) {
            $Proxy.Credentials = $ProxyCredential.GetNetworkCredential()
        } elseif ($ProxyUseDefaultCredentials) {
            $Proxy.UseDefaultCredentials = $true
        }

        $downloadSession.Proxy = $Proxy
    }

    return $downloadSession
}

function Test-isFileLocked {
    param(
        [String] $path
    )

    $file = New-Object System.IO.FileInfo $path

    if (!(Test-Path $path)) {
        return $false
    }

    try {
        $stream = $file.Open(
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None
        )
        if ($stream) {
            $stream.Close()
        }
        return $false
    } catch {
        # The file is locked by a process.
        return $true
    }
}

function Expand-ZipArchive {
    param(
        [String] $path,
        [String] $to
    )

    if (!(Test-Path $path)) {
        Deny-Install "Unzip failed: can't find $path to unzip."
    }

    # Check if the zip file is locked, by antivirus software for example
    $retries = 0
    while ($retries -le 10) {
        if ($retries -eq 10) {
            Deny-Install "Unzip failed: can't unzip because a process is locking the file."
        }
        if (Test-isFileLocked $path) {
            Write-InstallInfo "Waiting for $path to be unlocked by another process... ($retries/10)"
            $retries++
            Start-Sleep -Seconds 2
        } else {
            break
        }
    }

    # Workaround to suspend Expand-Archive verbose output,
    # upstream issue: https://github.com/PowerShell/Microsoft.PowerShell.Archive/issues/98
    $oldVerbosePreference = $VerbosePreference
    $global:VerbosePreference = 'SilentlyContinue'
    # PowerShell 5+: use Expand-Archive to extract zip files
    Microsoft.PowerShell.Archive\Expand-Archive -Path $path -DestinationPath $to -Force
    $global:VerbosePreference = $oldVerbosePreference
}

function Out-UTF8File {
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [Alias("Path")]
        [String] $FilePath,
        [Switch] $Append,
        [Switch] $NoNewLine,
        [Parameter(ValueFromPipeline = $True)]
        [PSObject] $InputObject
    )
    process {
        if ($Append) {
            [System.IO.File]::AppendAllText($FilePath, $InputObject)
        } else {
            if (!$NoNewLine) {
                # Ref: https://stackoverflow.com/questions/5596982
                # Performance Note: `WriteAllLines` throttles memory usage while
                # `WriteAllText` needs to keep the complete string in memory.
                [System.IO.File]::WriteAllLines($FilePath, $InputObject)
            } else {
                # However `WriteAllText` does not add ending newline.
                [System.IO.File]::WriteAllText($FilePath, $InputObject)
            }
        }
    }
}

function Import-ScoopShim {
    Write-InstallInfo "Creating shim..."
    # The scoop executable
    $path = "$SCOOP_APP_DIR\bin\scoop.ps1"

    if (!(Test-Path $SCOOP_SHIMS_DIR)) {
        New-Item -Type Directory $SCOOP_SHIMS_DIR | Out-Null
    }

    # The scoop shim
    $shim = "$SCOOP_SHIMS_DIR\scoop"

    # Convert to relative path
    Push-Location $SCOOP_SHIMS_DIR
    $relativePath = Resolve-Path -Relative $path
    Pop-Location
    $absolutePath = Resolve-Path $path

    # if $path points to another drive resolve-path prepends .\ which could break shims
    $ps1text = if ($relativePath -match '^(\.\\)?\w:.*$') {
        @(
            "# $absolutePath",
            "`$path = `"$path`"",
            "if (`$MyInvocation.ExpectingInput) { `$input | & `$path $arg @args } else { & `$path $arg @args }",
            "exit `$LASTEXITCODE"
        )
    } else {
        @(
            "# $absolutePath",
            "`$path = Join-Path `$PSScriptRoot `"$relativePath`"",
            "if (`$MyInvocation.ExpectingInput) { `$input | & `$path $arg @args } else { & `$path $arg @args }",
            "exit `$LASTEXITCODE"
        )
    }
    $ps1text -join "`r`n" | Out-UTF8File "$shim.ps1"

    # make ps1 accessible from cmd.exe
    @(
        "@rem $absolutePath",
        "@echo off",
        "setlocal enabledelayedexpansion",
        "set args=%*",
        ":: replace problem characters in arguments",
        "set args=%args:`"='%",
        "set args=%args:(=``(%",
        "set args=%args:)=``)%",
        "set invalid=`"='",
        "if !args! == !invalid! ( set args= )",
        "where /q pwsh.exe",
        "if %errorlevel% equ 0 (",
        "    pwsh -noprofile -ex unrestricted -file `"$absolutePath`" $arg %args%",
        ") else (",
        "    powershell -noprofile -ex unrestricted -file `"$absolutePath`" $arg %args%",
        ")"
    ) -join "`r`n" | Out-UTF8File "$shim.cmd"

    @(
        "#!/bin/sh",
        "# $absolutePath",
        "if command -v pwsh.exe > /dev/null 2>&1; then",
        "    pwsh.exe -noprofile -ex unrestricted -file `"$absolutePath`" $arg `"$@`"",
        "else",
        "    powershell.exe -noprofile -ex unrestricted -file `"$absolutePath`" $arg `"$@`"",
        "fi"
    ) -join "`n" | Out-UTF8File $shim -NoNewLine
}

function Get-Env {
    param(
        [String] $name,
        [Switch] $global
    )

    $target = if ($global) { 'Machine' } else { 'User' }
    return [Environment]::GetEnvironmentVariable($name, $target)
}

function Add-ShimsDirToPath {
    # Get $env:PATH of current user
    $userEnvPath = Get-Env 'PATH'

    if ($userEnvPath -notmatch [Regex]::Escape($SCOOP_SHIMS_DIR)) {
        $h = (Get-PSProvider 'FileSystem').Home
        if (!$h.EndsWith('\')) {
            $h += '\'
        }

        if (!($h -eq '\')) {
            $friendlyPath = "$SCOOP_SHIMS_DIR" -Replace ([Regex]::Escape($h)), "~\"
            Write-InstallInfo "Adding $friendlyPath to your path."
        } else {
            Write-InstallInfo "Adding $SCOOP_SHIMS_DIR to your path."
        }

        # For future sessions
        [System.Environment]::SetEnvironmentVariable('PATH', "$SCOOP_SHIMS_DIR;$userEnvPath", 'User')
        # For current session
        $env:PATH = "$SCOOP_SHIMS_DIR;$env:PATH"
    }
}

function Use-Config {
    if (!(Test-Path $SCOOP_CONFIG_FILE)) {
        return $null
    }

    try {
        return (Get-Content $SCOOP_CONFIG_FILE -Raw | ConvertFrom-Json -ErrorAction Stop)
    } catch {
        Deny-Install "ERROR loading $SCOOP_CONFIG_FILE`: $($_.Exception.Message)"
    }
}

function Add-Config {
    param (
        [Parameter(Mandatory = $True, Position = 0)]
        [String] $Name,
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Value
    )

    $scoopConfig = Use-Config

    if ($scoopConfig -is [System.Management.Automation.PSObject]) {
        if ($Value -eq [bool]::TrueString -or $Value -eq [bool]::FalseString) {
            $Value = [System.Convert]::ToBoolean($Value)
        }
        if ($null -eq $scoopConfig.$Name) {
            $scoopConfig | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
        } else {
            $scoopConfig.$Name = $Value
        }
    } else {
        $baseDir = Split-Path -Path $SCOOP_CONFIG_FILE
        if (!(Test-Path $baseDir)) {
            New-Item -Type Directory $baseDir | Out-Null
        }

        $scoopConfig = New-Object PSObject
        $scoopConfig | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }

    if ($null -eq $Value) {
        $scoopConfig.PSObject.Properties.Remove($Name)
    }

    ConvertTo-Json $scoopConfig | Set-Content $SCOOP_CONFIG_FILE -Encoding ASCII
    return $scoopConfig
}

function Add-DefaultConfig {
    # If user-level SCOOP env not defined, save to rootPath
    if (!(Get-Env 'SCOOP')) {
        if ($SCOOP_DIR -ne "$env:USERPROFILE\scoop") {
            Write-Verbose "Adding config rootPath: $SCOOP_DIR"
            Add-Config -Name 'rootPath' -Value $SCOOP_DIR | Out-Null
        }
    }

    # Use system SCOOP_GLOBAL, or set system SCOOP_GLOBAL
    # with $env:SCOOP_GLOBAL if RunAsAdmin, otherwise save to globalPath
    if (!(Get-Env 'SCOOP_GLOBAL' -global)) {
        if ((Test-IsAdministrator) -and $env:SCOOP_GLOBAL) {
            Write-Verbose "Setting System Environment Variable SCOOP_GLOBAL: $env:SCOOP_GLOBAL"
            [Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', $env:SCOOP_GLOBAL, 'Machine')
        } else {
            if ($SCOOP_GLOBAL_DIR -ne "$env:ProgramData\scoop") {
                Write-Verbose "Adding config globalPath: $SCOOP_GLOBAL_DIR"
                Add-Config -Name 'globalPath' -Value $SCOOP_GLOBAL_DIR | Out-Null
            }
        }
    }

    # Use system SCOOP_CACHE, or set system SCOOP_CACHE
    # with $env:SCOOP_CACHE if RunAsAdmin, otherwise save to cachePath
    if (!(Get-Env 'SCOOP_CACHE' -global)) {
        if ((Test-IsAdministrator) -and $env:SCOOP_CACHE) {
            Write-Verbose "Setting System Environment Variable SCOOP_CACHE: $env:SCOOP_CACHE"
            [Environment]::SetEnvironmentVariable('SCOOP_CACHE', $env:SCOOP_CACHE, 'Machine')
        } else {
            if ($SCOOP_CACHE_DIR -ne "$SCOOP_DIR\cache") {
                Write-Verbose "Adding config cachePath: $SCOOP_CACHE_DIR"
                Add-Config -Name 'cachePath' -Value $SCOOP_CACHE_DIR | Out-Null
            }
        }
    }

    # save current datatime to lastUpdate
    Add-Config -Name 'lastUpdate' -Value ([System.DateTime]::Now.ToString('o')) | Out-Null
}

function Install-Scoop {
    Write-InstallInfo "Initializing..."
    # Validate install parameters
    Test-ValidateParameter
    # Check prerequisites
    Test-Prerequisite
    # Enable TLS 1.2
    Optimize-SecurityProtocol

    # Download scoop zip from GitHub
    Write-InstallInfo "Downloading..."
    $downloader = Get-Downloader
    # 1. download scoop
    $scoopZipfile = "$SCOOP_APP_DIR\scoop.zip"
    if (!(Test-Path $SCOOP_APP_DIR)) {
        New-Item -Type Directory $SCOOP_APP_DIR | Out-Null
    }
    Write-Verbose "Downloading $SCOOP_PACKAGE_REPO to $scoopZipfile"
    $downloader.downloadFile($SCOOP_PACKAGE_REPO, $scoopZipfile)
    # 2. download scoop main bucket
    $scoopMainZipfile = "$SCOOP_MAIN_BUCKET_DIR\scoop-main.zip"
    if (!(Test-Path $SCOOP_MAIN_BUCKET_DIR)) {
        New-Item -Type Directory $SCOOP_MAIN_BUCKET_DIR | Out-Null
    }
    Write-Verbose "Downloading $SCOOP_MAIN_BUCKET_REPO to $scoopMainZipfile"
    $downloader.downloadFile($SCOOP_MAIN_BUCKET_REPO, $scoopMainZipfile)

    # Extract files from downloaded zip
    Write-InstallInfo "Extracting..."
    # 1. extract scoop
    $scoopUnzipTempDir = "$SCOOP_APP_DIR\_tmp"
    Write-Verbose "Extracting $scoopZipfile to $scoopUnzipTempDir"
    Expand-ZipArchive $scoopZipfile $scoopUnzipTempDir
    Copy-Item "$scoopUnzipTempDir\scoop-*\*" $SCOOP_APP_DIR -Recurse -Force
    # 2. extract scoop main bucket
    $scoopMainUnzipTempDir = "$SCOOP_MAIN_BUCKET_DIR\_tmp"
    Write-Verbose "Extracting $scoopMainZipfile to $scoopMainUnzipTempDir"
    Expand-ZipArchive $scoopMainZipfile $scoopMainUnzipTempDir
    Copy-Item "$scoopMainUnzipTempDir\Main-*\*" $SCOOP_MAIN_BUCKET_DIR -Recurse -Force

    # Cleanup
    Remove-Item $scoopUnzipTempDir -Recurse -Force
    Remove-Item $scoopZipfile
    Remove-Item $scoopMainUnzipTempDir -Recurse -Force
    Remove-Item $scoopMainZipfile

    # Create the scoop shim
    Import-ScoopShim
    # Finially ensure scoop shims is in the PATH
    Add-ShimsDirToPath
    # Setup initial configuration of Scoop
    Add-DefaultConfig

    Write-InstallInfo "Scoop was installed successfully!" -ForegroundColor DarkGreen
    Write-InstallInfo "Type 'scoop help' for instructions."
}

function Write-DebugInfo {
    param($BoundArgs)

    Write-Verbose "-------- PSBoundParameters --------"
    $BoundArgs.GetEnumerator() | ForEach-Object { Write-Verbose $_ }
    Write-Verbose "-------- Environment Variables --------"
    Write-Verbose "`$env:USERPROFILE: $env:USERPROFILE"
    Write-Verbose "`$env:ProgramData: $env:ProgramData"
    Write-Verbose "`$env:SCOOP: $env:SCOOP"
    Write-Verbose "`$env:SCOOP_CACHE: $SCOOP_CACHE"
    Write-Verbose "`$env:SCOOP_GLOBAL: $env:SCOOP_GLOBAL"
    Write-Verbose "-------- Selected Variables --------"
    Write-Verbose "SCOOP_DIR: $SCOOP_DIR"
    Write-Verbose "SCOOP_CACHE_DIR: $SCOOP_CACHE_DIR"
    Write-Verbose "SCOOP_GLOBAL_DIR: $SCOOP_GLOBAL_DIR"
    Write-Verbose "SCOOP_CONFIG_HOME: $SCOOP_CONFIG_HOME"
}

# Prepare variables
$IS_EXECUTED_FROM_IEX = ($null -eq $MyInvocation.MyCommand.Path)

# Scoop root directory
$SCOOP_DIR = $ScoopDir, $env:SCOOP, "$env:USERPROFILE\scoop" | Where-Object { -not [String]::IsNullOrEmpty($_) } | Select-Object -First 1
# Scoop global apps directory
$SCOOP_GLOBAL_DIR = $ScoopGlobalDir, $env:SCOOP_GLOBAL, "$env:ProgramData\scoop" | Where-Object { -not [String]::IsNullOrEmpty($_) } | Select-Object -First 1
# Scoop cache directory
$SCOOP_CACHE_DIR = $ScoopCacheDir, $env:SCOOP_CACHE, "$SCOOP_DIR\cache" | Where-Object { -not [String]::IsNullOrEmpty($_) } | Select-Object -First 1
# Scoop shims directory
$SCOOP_SHIMS_DIR = "$SCOOP_DIR\shims"
# Scoop itself directory
$SCOOP_APP_DIR = "$SCOOP_DIR\apps\scoop\current"
# Scoop main bucket directory
$SCOOP_MAIN_BUCKET_DIR = "$SCOOP_DIR\buckets\main"
# Scoop config file location
$SCOOP_CONFIG_HOME = $env:XDG_CONFIG_HOME, "$env:USERPROFILE\.config" | Select-Object -First 1
$SCOOP_CONFIG_FILE = "$SCOOP_CONFIG_HOME\scoop\config.json"

# TODO: Use a specific version of Scoop and the main bucket
$SCOOP_PACKAGE_REPO = "https://github.com/ScoopInstaller/Scoop/archive/master.zip"
$SCOOP_MAIN_BUCKET_REPO = "https://github.com/ScoopInstaller/Main/archive/master.zip"

# Quit if anything goes wrong
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

# Logging debug info
Write-DebugInfo $PSBoundParameters
# Bootstrap function
Install-Scoop

# Reset $ErrorActionPreference to original value
$ErrorActionPreference = $oldErrorActionPreference

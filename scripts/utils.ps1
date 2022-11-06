function Ensure-Exists($path) {
    if (-not (Test-Path $path)) {
        Write-Error "Missing required $path! Ensure it is installed"
        exit 1
    }
    return $true > $null
}

function Ensure-Executable($command) {
    try { Get-Command $command -ErrorAction Stop > $null }
    catch {
        if( ($command -eq "7z") -and (Test-Path "$env:programfiles\7-zip\7z.exe") ){
            Set-Alias -Name "7z" -Value "$env:programfiles\7-zip\7z.exe" -Scope script
        }
        elseif( ($command -eq "7z") -and (Test-Path "$env:programw6432\7-zip\7z.exe") ) {
            Set-Alias -Name "7z" -Value "$env:programw6432\7-zip\7z.exe" -Scope script
        }
        else {
            Write-Error "Missing $command! Ensure it is installed and on in the PATH"
            exit 1
        }
    }
}

function Delete-Existing($path) {
    if (Test-Path $path) {
        Write-Verbose "Remove existing $path"
    }
    Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
}

function Extract-Archive($source, $target) {
    Write-Verbose $("Extracting Archive '$cmder_root\vendor\" + $source.replace('/','\') + " to '$cmder_root\vendor\$target'")
    Invoke-Expression "7z x -y -o`"$($target)`" `"$source`"  > `$null"
    if ($LastExitCode -ne 0) {
        Write-Error "Extracting of $source failed"
    }
    Remove-Item $source
}

function Create-Archive($source, $target, $params) {
    $command = "7z a -x@`"$source\packignore`" $params `"$target`" `"*`"  > `$null"
    Write-Verbose "Creating Archive from '$source' in '$target' with parameters '$params'"
    Push-Location $source
    Invoke-Expression $command
    Pop-Location
    if ($LastExitCode -ne 0) {
        Write-Error "Compressing $source failed"
    }
}

# If directory contains only one child directory
# Flatten it instead
function Flatten-Directory($name) {
    $name = Resolve-Path $name
    $moving = "$($name)_moving"
    Rename-Item $name -NewName $moving
    Write-Verbose "Flattening the '$name' directory..."
    $child = (Get-ChildItem $moving)[0] | Resolve-Path
    Move-Item -Path $child -Destination $name
    Remove-Item -Recurse $moving
}

function Digest-Hash($path) {
    if (Get-Command Get-FileHash -ErrorAction SilentlyContinue) {
        return (Get-FileHash -Algorithm SHA256 -Path $path).Hash
    }

    return Invoke-Expression "md5sum $path"
}

function Set-GHVariable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    Write-Verbose "Setting CI variable $Name to $Value" -Verbose

    if ($env:GITHUB_ENV) {
        Write-Output "$Name=$Value" | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
    }
}

function Get-GHTempPath {
    $temp = [System.IO.Path]::GetTempPath()
    if ($env:RUNNER_TEMP) {
        $temp = $env:RUNNER_TEMP
    }

    Write-Verbose "Get CI Temp path: $temp" -Verbose
    return $temp
}

function Get-VersionStr {
    # Clear existing variable
    if ($string) { Clear-Variable -name string }

    # Determine if git is available
    if (Get-Command "git.exe" -ErrorAction SilentlyContinue) {
        # Determine if the current directory is a git repository
        $GitPresent = Invoke-Expression "git rev-parse --is-inside-work-tree" -ErrorAction SilentlyContinue

        if ( $GitPresent -eq 'true' ) {
            $string = Invoke-Expression "git describe --abbrev=0 --tags"
        }
    }

    # Fallback used when Git is not available
    if ( -not($string) ) {
        $string = Parse-Changelog ($PSScriptRoot + '\..\' + 'CHANGELOG.md')
    }

    # Add build number, if AppVeyor is present
    if ( $Env:APPVEYOR -eq 'True' ) {
        $string = $string + '.' + $Env:APPVEYOR_BUILD_NUMBER
    }
    elseif ( $Env:GITHUB_ACTIONS -eq 'true' ) {
        $string = $string + '.' + $Env:GITHUB_RUN_NUMBER
    }

    # Remove starting 'v' characters
    $string = $string -replace '^v+','' # normalize version string

    return $string
}

function Parse-Changelog($file) {
    # Define the regular expression to match the version string from changelog
    [regex]$regex = '^## \[(?<version>[\w\-\.]+)\]\([^\n()]+\)\s+\([^\n()]+\)$';

    # Find the first match of the version string which means the latest version
    $version = Select-String -Path $file -Pattern $regex | Select-Object -First 1 | ForEach-Object { $_.Matches.Groups[1].Value }

    return $version
}

function Create-RC($string, $path) {
    $version  = $string + '.0.0.0.0' # padding for version string

    if ( !(Test-Path "$path.sample") ) {
        throw "Invalid path provided for resources file."
    }

    $resource = Get-Content -Path "$path.sample"
    $pattern  = @( "Cmder-Major-Version", "Cmder-Minor-Version", "Cmder-Revision-Version", "Cmder-Build-Version" )
    $index    = 0

    # Replace all non-numeric characters to dots and split to array
    $version = $version -replace '[^0-9]+','.' -split '\.'

    foreach ($fragment in $version) {
        if ( !$fragment ) { break }
        elseif ($index -le $pattern.length) {
            $resource = $resource.Replace( "{" + $pattern[$index++] + "}", $fragment )
        }
    }

    # Add the version string
    $resource = $resource.Replace( "{Cmder-Version-Str}", '"' + $string + '"' )

    # Write the results
    Set-Content -Path $path -Value $resource
}

function Register-Cmder() {
    [CmdletBinding()]
    Param
    (
        # Text for the context menu item.
        $MenuText = "Cmder Here"

        , # Defaults to the current cmder directory when run from cmder.
        $PathToExe = (Join-Path $env:CMDER_ROOT "cmder.exe")

        , # Commands the context menu will execute.
        $Command = "%V"

        , # Defaults to the icons folder in the cmder package.
        $icon = (Split-Path $PathToExe | Join-Path -ChildPath 'icons/cmder.ico')
    )
    Begin
    {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT > $null
    }
    Process
    {
        New-Item         -Path "HKCR:\Directory\Shell\Cmder" -Force -Value $MenuText
        New-ItemProperty -Path "HKCR:\Directory\Shell\Cmder" -Force -Name "Icon" -Value `"$icon`"
        New-ItemProperty -Path "HKCR:\Directory\Shell\Cmder" -Force -Name "NoWorkingDirectory"
        New-Item         -Path "HKCR:\Directory\Shell\Cmder\Command" -Force -Value "`"$PathToExe`" `"$Command`" "

        New-Item         -Path "HKCR:\Directory\Background\Shell\Cmder" -Force -Value $MenuText
        New-ItemProperty -Path "HKCR:\Directory\Background\Shell\Cmder" -Force -Name "Icon" -Value `"$icon`"
        New-ItemProperty -Path "HKCR:\Directory\Background\Shell\Cmder" -Force -Name "NoWorkingDirectory"
        New-Item         -Path "HKCR:\Directory\Background\Shell\Cmder\Command" -Force -Value "`"$PathToExe`" `"$Command`" "
    }
    End
    {
        Remove-PSDrive -Name HKCR
    }
}

function Unregister-Cmder {
    Begin
    {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT > $null
    }
    Process
    {
        Remove-Item -Path "HKCR:\Directory\Shell\Cmder" -Recurse
        Remove-Item -Path "HKCR:\Directory\Background\Shell\Cmder" -Recurse
    }
    End
    {
        Remove-PSDrive -Name HKCR
    }
}

function Download-File {
    param (
        $Url,
        $File
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $useBitTransfer = $null -ne (Get-Module -Name BitsTransfer -ListAvailable) -and ($PSVersionTable.PSVersion.Major -le 5)

    $File = $File -replace "/", "\"

    try {
        if ($useBitTransfer) {
            Start-BitsTransfer -Source $Url -Destination $File -DisplayName "Downloading '$Url' to $File"
            return
        }
    }
    catch {
        Write-Error "Failed to download file using BITS, reason: $_`nUsing fallback method instead...`n" -ErrorAction:Continue
    }

    Write-Verbose "Downloading from $Url to $File`n"

    $wc = New-Object System.Net.WebClient
    if ($env:https_proxy) {
        $wc.proxy = (New-Object System.Net.WebProxy($env:https_proxy))
    }
    $wc.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials;
    $wc.DownloadFile($Url, $File)
}

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

        , # Defaults to the current Cmder directory when run from Cmder.
        $PathToExe = (Join-Path $env:CMDER_ROOT "cmder.exe")

        , # Commands the context menu will execute.
        $Command = "%V"

        , # Defaults to the icons folder in the Cmder package.
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

function Format-FileSize {
    <#
    .SYNOPSIS
    Formats a file size in bytes to a human-readable string using binary units.
    
    .DESCRIPTION
    Converts file sizes to appropriate binary units (B, KiB, MiB, GiB) for better readability.
    
    .PARAMETER Bytes
    The file size in bytes to format.
    
    .EXAMPLE
    Format-FileSize -Bytes 1024
    Returns "1.00 KiB"
    
    .EXAMPLE
    Format-FileSize -Bytes 15728640
    Returns "15.00 MiB"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )
    
    if ($Bytes -ge 1GB) {
        return "{0:N2} GiB" -f ($Bytes / 1GB)
    } elseif ($Bytes -ge 1MB) {
        return "{0:N2} MiB" -f ($Bytes / 1MB)
    } elseif ($Bytes -ge 1KB) {
        return "{0:N2} KiB" -f ($Bytes / 1KB)
    } else {
        return "{0:N0} B" -f $Bytes
    }
}

function Get-ArtifactDownloadUrl {
    <#
    .SYNOPSIS
    Retrieves the download URL for a GitHub Actions artifact with retry logic.
    
    .DESCRIPTION
    Uses the GitHub CLI to fetch artifact information from the GitHub API with automatic retries.
    Falls back to returning $null if all attempts fail.
    
    .PARAMETER ArtifactName
    The name of the artifact to retrieve the download URL for.
    
    .PARAMETER Repository
    The GitHub repository in the format "owner/repo".
    
    .PARAMETER RunId
    The GitHub Actions workflow run ID.
    
    .PARAMETER MaxRetries
    Maximum number of retry attempts. Default is 3.
    
    .PARAMETER DelaySeconds
    Delay in seconds between retry attempts. Default is 2.
    
    .EXAMPLE
    Get-ArtifactDownloadUrl -ArtifactName "cmder.zip" -Repository "cmderdev/cmder" -RunId "123456789"
    
    .EXAMPLE
    Get-ArtifactDownloadUrl -ArtifactName "build-output" -Repository "owner/repo" -RunId "987654321" -MaxRetries 5 -DelaySeconds 3
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ArtifactName,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$RunId,
        
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 2
    )
    
    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            # Use GitHub CLI to get artifact information
            $artifactsJson = gh api "repos/$Repository/actions/runs/$RunId/artifacts" --jq ".artifacts[] | select(.name == `"$ArtifactName`")"
            
            if ($artifactsJson) {
                $artifact = $artifactsJson | ConvertFrom-Json
                if ($artifact.id) {
                    # Construct browser-accessible GitHub Actions artifact download URL
                    # Format: https://github.com/owner/repo/actions/runs/{run_id}/artifacts/{artifact_id}
                    return "https://github.com/$Repository/actions/runs/$RunId/artifacts/$($artifact.id)"
                }
            }
        } catch {
            Write-Host "Attempt $($i + 1) failed to get artifact URL for $ArtifactName : $_"
        }
        
        if ($i -lt ($MaxRetries - 1)) {
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    
    return $null
}

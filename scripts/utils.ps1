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
        If( ($command -eq "7z") -and (Test-Path "$env:programfiles\7-zip\7z.exe") ){
            set-alias -Name "7z" -Value "$env:programfiles\7-zip\7z.exe" -Scope script
        }
        ElseIf( ($command -eq "7z") -and (Test-Path "$env:programw6432\7-zip\7z.exe") ) {
            set-alias -Name "7z" -Value "$env:programw6432\7-zip\7z.exe" -Scope script
        }
        Else {
            Write-Error "Missing $command! Ensure it is installed and on in the PATH"
            exit 1
        }
    }
}

function Delete-Existing($path) {
    Write-Verbose "Remove $path"
    Remove-Item -Recurse -force $path -ErrorAction SilentlyContinue
}

function Extract-Archive($source, $target) {
    Write-Verbose $("Extracting Archive '$cmder_root\vendor\" + $source.replace('/','\') + " to '$cmder_root\vendor\$target'")
    Invoke-Expression "7z x -y -o`"$($target)`" `"$source`"  > `$null"
    if ($lastexitcode -ne 0) {
        Write-Error "Extracting of $source failied"
    }
    Remove-Item $source
}

function Create-Archive($source, $target, $params) {
    $command = "7z a -x@`"$source\packignore`" $params $target $source  > `$null"
    Write-Verbose "Running: $command"
    Invoke-Expression $command
    if ($lastexitcode -ne 0) {
        Write-Error "Compressing $source failied"
    }
}

# If directory contains only one child directory
# Flatten it instead
function Flatten-Directory($name) {
    $child = (Get-Childitem $name)[0]
    Rename-Item $name -NewName "$($name)_moving"
    Move-Item -Path "$($name)_moving\$child" -Destination $name
    Remove-Item -Recurse "$($name)_moving"
}

function Digest-Hash($path) {
    if(Get-Command Get-FileHash -ErrorAction SilentlyContinue){
        return (Get-FileHash -Algorithm SHA256 -Path $path).Hash
    }

    return Invoke-Expression "md5sum $path"
}

function Get-VersionStr() {

    # Clear existing variable
    if ($string) { Clear-Variable -name string }

    # Determine if git is available
    if (Get-Command "git.exe" -ErrorAction SilentlyContinue)
    {

        # Determine if the current diesctory is a git repository
        $GitPresent = Invoke-Expression "git rev-parse --is-inside-work-tree" -erroraction SilentlyContinue

        if ( $GitPresent -eq 'true' )
        {
            $string = Invoke-Expression "git describe --abbrev=0 --tags"
        }

    }

    # Fallback used when Git is not available
    if ( -not($string) )
    {
        $string = Parse-Changelog ($PSScriptRoot + '\..\' + 'CHANGELOG.md')
    }

    # Add build number, if AppVeyor is present
    if ( $Env:APPVEYOR -eq 'True' )
    {
        $string = $string + '.' + $Env:APPVEYOR_BUILD_NUMBER
    }

    # Remove starting 'v' characters
    $string = $string -replace '^v+','' # normalize version string

    return $string

}

function Parse-Changelog($file) {

    # Define the regular expression to match the version string from changelog
    [regex]$regex = '^## \[(?<version>[\w\-\.]+)\]\([^\n()]+\)\s+\([^\n()]+\)$';

    # Find the first match of the version string which means the latest version
    $version = Select-String -Path $file -Pattern $regex | Select-Object -First 1 | % { $_.Matches.Groups[1].Value }

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
    
    # I think this is the problem
    $File = $File -Replace "/", "\"
    Write-Verbose "Downloading from $Url to $File"
    $wc = New-Object System.Net.WebClient
    if ($env:https_proxy) {
      $wc.proxy = (New-Object System.Net.WebProxy($env:https_proxy))
    }
    $wc.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials;
    $wc.DownloadFile($Url, $File)
}

function Ensure-Exists ($path) {
    if (-not (Test-Path $path)) {
        Write-Error "Missing required $path! Ensure it is installed"
        exit 1
    }
    return $true > $null
}

function Ensure-Executable ($command) {
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

function Delete-Existing ($path) {
    Write-Verbose "Remove $path"
    Remove-Item -Recurse -force $path -ErrorAction SilentlyContinue
}

function Extract-Archive ($source, $target) {
    Write-Verbose $("Extracting Archive '$cmder_root\vendor\" + $source.replace('/','\') + " to '$cmder_root\vendor\$target'")
    Invoke-Expression "7z x -y -o`"$($target)`" `"$source`"  > `$null"
    if ($lastexitcode -ne 0) {
        Write-Error "Extracting of $source failied"
    }
    Remove-Item $source
}

function Create-Archive ($source, $target, $params) {
    $command = "7z a -x@`"$source\packignore`" $params $target $source  > `$null"
    Write-Verbose "Running: $command"
    Invoke-Expression $command
    if ($lastexitcode -ne 0) {
        Write-Error "Compressing $source failied"
    }
}

# If directory contains only one child directory
# Flatten it instead
function Flatten-Directory ($name) {
    $child = (Get-Childitem $name)[0]
    Rename-Item $name -NewName "$($name)_moving"
    Move-Item -Path "$($name)_moving\$child" -Destination $name
    Remove-Item -Recurse "$($name)_moving"
}

function Digest-MD5 ($path) {
    if(Get-Command Get-FileHash -ErrorAction SilentlyContinue){
        return (Get-FileHash -Algorithm MD5 -Path $path).Hash
    }

    return Invoke-Expression "md5sum $path"
}

function Register-Cmder(){
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
        $icon = (Split-Path $PathToExe | join-path -ChildPath 'icons/cmder.ico')
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

function Unregister-Cmder{
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
    # I think this is the problem
    $File = $File -Replace "/", "\"
    Write-Verbose "Downloading from $Url to $File"
    $wc = new-object System.Net.WebClient
    if ($env:https_proxy) {
      $wc.proxy = (new-object System.Net.WebProxy($env:https_proxy))
    }
    $wc.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials;
    $wc.DownloadFile($Url, $File)
}

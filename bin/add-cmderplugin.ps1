<#
.Synopsis
    Add a plugin to Cmder
.DESCRIPTION
    Use this script to add a plugin the currently running Cmder

    This script downloads and unpacks sources, configures users aliases, and runs pre and post commands defined in the supplied cmder-plugin-[name].json file.

    You will need to make this script executable by setting your Powershell Execution Policy to Remote signed.

    Then unblock the script for execution with UnblockFile .\add-cmderplugin.ps1
.EXAMPLE
    .\add-cmderplugin.ps1 -PluginPath '~/custom/cmder-plugin-[name].json'

    Reads the source json data and excutes the steps to install nad configue the plugin.
.EXAMPLE
    .\add-cmderplugin.ps1 -PluginPath '~/custom/cmder-plugin-[name].json' -verbose

    Reads the source json data and excutes the steps to install nad configue the plugin and see more detail as to what is going on.
.NOTES
    AUTHORS
    Dax Games, Samuel Vasko, Jack Bennett
    Part of the Cmder project.
.LINK
    http://cmder.net/ - Project Home
#>

[CmdletBinding(SupportsShouldProcess=$true)]
Param(
    # CmdletBinding will give us;
    # -verbose switch to turn on logging and
    # -whatif switch to not actually make changes

    # Path to the vendor configuration source file
    [string]$PluginPath = "$env:CMDER_ROOT\vendor\sources-plugins.json",

    # Replace the plugin
    [switch]$replace,

    # Vendor folder location
    [string]$saveTo = "$env:CMDER_ROOT\vendor\",

    # Config folder location
    [string]$config = "$env:CMDER_ROOT\config"
)


$ThisScript = Get-Item $MyInvocation.MyCommand.Definition

# Dot source util functions into this scope
. $($ThisScript.DirectoryName + "\utils.ps1")

$bash_user_profile = $($env:cmder_root + "\config\user-profile.sh")
$bash_user_aliases = $($env:cmder_root + "\config\user-aliases.sh")

if (test-path $bash_user_aliases) {
  $bash_aliases = $bash_user_aliases
} else {
  $bash_aliases = $bash_user_profile
}

$posh_user_profile = $($env:cmder_root + "\config\user-profile.ps1")
$posh_user_aliases = $($env:cmder_root + "\config\user-aliases.ps1")

if (test-path $posh_user_aliases) {
  $posh_aliases = $posh_user_aliases
} else {
  $posh_aliases = $posh_user_profile
}


$cmder_user_profile = $($env:cmder_root + "\config\user-profile.cmd")
$cmder_aliases = $($env:cmder_root + "\config\aliases")

$ErrorActionPreference = "Stop"

Push-Location -Path $saveTo
$sources = Get-Content $PluginPath | Out-String | Convertfrom-Json

# Check for requirements
Ensure-Exists $PluginPath
Ensure-Executable "7z"
New-Item -Type Directory -Path (Join-Path $saveTo "/tmp/") -ErrorAction SilentlyContinue >$null

$vend = $pwd
foreach ($s in $sources) {
    Write-Verbose "Getting $($s.name) from URL $($s.url)"

    foreach ($pre_command in $s.pre_commands) {
      write-host $("`nRunning '" + $pre_command + "'...")
      invoke-expression $pre_command
    }

    # We do not care about the extensions/type of archive
    $tempArchive = "tmp/$($s.name).tmp"
    Delete-Existing $tempArchive

    if ($replace -eq $true) {
      Delete-Existing $s.name
    }

    if (test-path -eq $false) {
      Download-File -Url $s.url -File $vend\$tempArchive -ErrorAction Stop
      Extract-Archive $tempArchive $s.name

      if ((Get-ChildItem $s.name).Count -eq 1) {
          Flatten-Directory($s.name)
      }

      foreach ($alias in $s.alias.psobject.properties) {
        foreach ($shell in $alias.value.psobject.properties) {
          if ($shell.name -eq "sh") {
            $aliases = get-content $bash_aliases
            $new_alias = $( "alias " + $alias.name + "='" + $shell.value + "'")
            if ($aliases -notcontains $new_alias) {
              write-host $("`nWriting alias '" + $alias.name + "' to '" + $bash_aliases + "'")
              write-host $new_alias
              $new_alias | Out-File $bash_aliases -Encoding ASCII -append
            }
          } elseif ($shell.name -eq "cmder") {
            $aliases = get-content $cmder_aliases
            $new_alias = $( $alias.name + "=" + $shell.value)
            if ($aliases -notcontains $new_alias) {
              write-host $("`nWriting alias '" + $alias.name + "' to '" + $cmder_aliases + "'")
              write-host $new_alias
              $new_alias | Out-File $cmder_aliases -Encoding ASCII -append
            }
          } elseif ($shell.name -eq "posh") {
            $aliases = get-content $posh_aliases
            $new_alias = $( "new-alias " + $alias.name + " " + $($shell.value -replace "/","\") + " -erroraction silentlycontinue")
            if ($aliases -notcontains $new_alias) {
              write-host $("`nWriting alias '" + $alias.name + "' to '" + $posh_aliases + "'")
              write-host $new_alias
              $new_alias | Out-File $posh_aliases -append
              . $posh_aliases
              get-alias $alias.name
            }
          }
        }
      }

      . $posh_aliases

      foreach ($post_command in $s.post_commands) {
        write-host $("`nRunning '" + $post_command + "'...")
        invoke-expression $post_command
      }
    } else {
      write-host "The plugin is already installed!  Use the -force switch to replace the currently installed plugin."
    }
}

Pop-Location

Write-Verbose "All good and done!"
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
    Invoke-Expression "7z x -y -o$($target) '$source' > `$null"
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
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    }
    Process
    {
        New-Item -Path "HKCR:\Directory\Shell\Cmder" -Force -Value $MenuText
        New-ItemProperty -Path "HKCR:\Directory\Shell\Cmder" -Force -Name "Icon" -Value `"$icon`"
        New-ItemProperty -Path "HKCR:\Directory\Shell\Cmder" -Force -Name "NoWorkingDirectory"
        New-Item -Path "HKCR:\Directory\Shell\Cmder\Command" -Force -Value "`"$PathToExe`" `"$Command`" "
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
    $wc.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials;    
    $wc.DownloadFile($Url, $File)
}

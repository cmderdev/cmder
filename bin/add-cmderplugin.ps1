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
    [switch]$force,

    # Vendor folder location
    [string]$saveTo = "$env:CMDER_ROOT\vendor\",

    # Config folder location
    [string]$config = "$env:CMDER_ROOT\config"
)


# Get the scripts and cmder root dirs we are building in.
$ScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$cmder_root = $ScriptRoot.replace("\bin","")

# Dot source util functions into this scope
. $($ScriptRoot + "\utils.ps1")

$bash_shared_profile = $($cmder_root + "\config\profile.d\001-shared-profile.sh")
$bash_shared_aliases = $($cmder_root + "\config\profile.d\shared-aliases.sh")

$posh_shared_profile = $($cmder_root + "\config\profile.d\001-shared-profile.ps1")
$posh_shared_aliases = $($cmder_root + "\config\profile.d\shared-aliases.ps1")

$cmder_shared_profile = $($cmder_root + "\config\profile.d\001-shared-profile.cmd")
$cmder_shared_aliases = $($cmder_root + "\config\profile.d\shared-aliases.cmd")

$ErrorActionPreference = "Stop"

# Check for requirements
Ensure-Exists $PluginPath
Ensure-Executable "7z"

$sources = Get-Content $PluginPath | Out-String | Convertfrom-Json

Push-Location -Path $saveTo

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

    if ($force -eq $true) {
      write-host $("`nDeleting existing install of the '" + $s.name + "' plugin...")
      Delete-Existing $s.name
    }

    if ((test-path $s.name) -eq $false) {
      write-host $("Downloading '" + $s.url + "' to '" + $vend + "\" + $tempArchive + "'...")
      Download-File -Url $s.url -File $vend\$tempArchive -ErrorAction Stop

      write-host $("Extracting '" + $vend + "\" + $tempArchive + "' to '" + $s.name + "'...")
      Extract-Archive $tempArchive $s.name

      if ((Get-ChildItem $s.name).Count -eq 1) {
          Flatten-Directory($s.name)
      }

      foreach ($shared_alias in $s.shared_alias.psobject.properties) {
        foreach ($shell in $shared_alias.value.psobject.properties) {
          if ($shell.name -eq "sh") {
            if (-not (test-path $bash_shared_aliases)) {
              "# this is a shared aliases for the bash shell" | out-file $bash_shared_aliases -Encoding ASCII
            }

            $aliases = get-content $bash_shared_aliases
            $new_alias = $( "alias " + $shared_alias.name + "='" + $shell.value + "'")
            if ($aliases -notcontains $new_alias) {
              write-host $("`nWriting alias '" + $shared_alias.name + "' to '" + $bash_shared_aliases + "'")
              write-host $new_alias
              $new_alias | Out-File $bash_shared_aliases -Encoding ASCII -append
            }
          } elseif ($shell.name -eq "cmder") {
            if (-not (test-path $cmder_shared_aliases)) {
              ";= echo off" | out-file -Encoding ASCII $cmder_shared_aliases
              ";= rem Call DOSKEY and use this file as the macrofile" | out-file -Encoding ASCII -append $cmder_shared_aliases
              ";= %SystemRoot%\system32\doskey /listsize=1000 /macrofile=%0%" | out-file -Encoding ASCII -append $cmder_shared_aliases
              ";= rem In batch mode, jump to the end of the file" | out-file -append -Encoding ASCII $cmder_shared_aliases
              ";= set aliases=%cmder_root%\config\profile.d\shared-aliases.cmd" | out-file -Encoding ASCII -append $cmder_shared_aliases
              ";= goto :eof" | out-file -Encoding ASCII -append $cmder_shared_aliases
            }

            $aliases = get-content $cmder_shared_aliases
            $new_alias = $( $shared_alias.name + "=" + $shell.value)
            if ($aliases -notcontains $new_alias) {
              write-host $("`nWriting alias '" + $shared_alias.name + "' to '" + $cmder_shared_aliases + "'")
              write-host $new_alias
              $new_alias | Out-File $cmder_shared_aliases -Encoding ASCII -append
            }
          } elseif ($shell.name -eq "posh") {
            if (-not (test-path $posh_shared_aliases)) {
              "# this is a shared aliases for Powershell" | out-file $posh_shared_aliases
            }

            $aliases = get-content $posh_shared_aliases
            $new_alias = $( "new-alias " + $shared_alias.name + " '" + $($shell.value -replace "/","\") + "' -erroraction silentlycontinue")
            if ($aliases -notcontains $new_alias) {
              write-host $("`nWriting alias '" + $shared_alias.name + "' to '" + $posh_shared_aliases + "'")
              write-host $new_alias
              $new_alias | Out-File $posh_shared_aliases -append
            }
          }
        }
      }

      foreach ($shared_profile in $s.shared_profile.psobject.properties) {
        foreach ($shell in $shared_profile.value.psobject.properties) {
          if ($shell.name -eq "sh") {
            if (-not (test-path $bash_shared_profile)) {
              "# this is a shared profile for the bash shell" | out-file $bash_shared_profile -Encoding ASCII
            }

            $profile_lines = get-content $bash_shared_profile
            if ($profile_lines -notcontains $shell.value) {
              write-host $("`nWriting to '" + $bash_shared_profile + "'")
              write-host $shell.value
              $shell.value | Out-File $bash_shared_profile -Encoding ASCII -append
            }
          } elseif ($shell.name -eq "cmder") {
            if (-not (test-path $cmder_shared_profile)) {
              "REM this is a shared profile for the cmd shell" | out-file $cmder_shared_profile -Encoding ASCII
            }

            $profile_lines = get-content $cmder_shared_profile
            if ($profile_lines -notcontains $shell.value) {
              write-host $("`nWriting to '" + $cmder_shared_profile + "'")
              write-host $shell.value
              $shell.value | Out-File $cmder_shared_profile -Encoding ASCII -append
            }
          } elseif ($shell.name -eq "posh") {
            if (-not (test-path $posh_shared_profile)) {
              "# this is a shared profile for Powershell" | out-file $posh_shared_profile
            }

            $profile_lines = get-content $posh_shared_profile
            if ($profile_lines -notcontains $shell.value) {
              write-host $("`nWriting to '" + $posh_shared_profile + "'")
              write-host $shell.value
              $shell.value | Out-File $posh_shared_profile -append
            }
          }
        }
      }

      foreach ($post_command in $s.post_commands) {
        write-host $("`nRunning '" + $post_command + "'...")
        invoke-expression $post_command
      }
    } else {
      write-host "The plugin is already installed!  Use the -force switch to replace the currently installed plugin."
    }
}

Pop-Location

Write-host "Restart ALL cmder sessions for the plugin install to be complete!"



function readVersion($gitPath) {
    $gitExecutable = "${gitPath}\git.exe"

    if (!(test-path "$gitExecutable")) {
        return $null
    }

    $gitVersion = (cmd /c "${gitExecutable}" --version)

    if ($gitVersion -match 'git version') {
        ($trash1, $trash2, $gitVersion) = $gitVersion.split(' ', 3)
    } else {
        pause
        return $null
    }

    return $gitVersion.toString()
}

function isGitShim($gitPath) {
    # check if there's shim - and if yes follow the path
    
    if (test-path "${gitPath}\git.shim") {
      $shim = (get-content "${gitPath}\git.shim")
      ($trash, $gitPath) = $shim.replace(' ','').split('=')

      $gitPath=$gitPath.replace('\git.exe','')  
    } 
 
    return $gitPath.toString()
}

function compareVersions($userVersion, $vendorVersion) {
    if (-not($userVersion -eq $null)) {
        ($userMajor, $userMinor, $userPatch, $userBuild) = $userVersion.split('.', 4)
    } else {
        return -1
    }

    if (-not($vendorVersion -eq $null)) {
        ($vendorMajor, $vendorMinor, $vendorPatch, $vendorBuild) = $vendorVersion.split('.', 4)
    } else {
        return 1
    }

    if ($userMajor -gt $vendorMajor) {return 1}
    if ($userMajor -lt $vendorMajor) {return -1}

    if ($userMinor -gt $vendorMinor) {return 1}
    if ($userMinor -lt $vendorMinor) {return -1}

    if ($userPatch -gt $vendorPatch) {return 1}
    if ($userPatch -lt $vendorPatch) {return -1}

    if ($userBuild -gt $vendorBuild) {return 1}
    if ($userBuild -lt $vendorBuild) {return -1}

    return 0
}

function compare_git_versions($userVersion, $vendorVersion) {
    $result = compareVersions -userVersion $userVersion -vendorVersion $vendorVersion

    # write-host "Compare Versions Result: ${result}"
    if ($result -ge 0) {
        return $userVersion
    } else {
        return $vendorVersion
    }

}

function Configure-Git($gitRoot, $gitType){
  # # Current Cmder Behavior
  # $GIT_INSTALL_ROOT_ESC=$GIT_INSTALL_ROOT.replace('\','\\')
  # if (!($env:Path -match "$GIT_INSTALL_ROOT_ESC\\cmd")) {
  #     $env:Path = $($GIT_INSTALL_ROOT + "\cmd" + ";" + $env:Path)
  # }
  #
  # # Add "$GIT_INSTALL_ROOT\usr\bin" to the path if exists and not done already
  # if ((test-path "$GIT_INSTALL_ROOT\usr\bin") -and -not ($env:path -match "$GIT_INSTALL_ROOT_ESC\\usr\\bin")) {
  #     $env:path = "$env:path;$GIT_INSTALL_ROOT\usr\bin"
  # }

  # $env:Path = $($env:Path + ";" $GIT_INSTALL_ROOT + "\cmd")

  # # Add "$GIT_INSTALL_ROOT\mingw[32|64]\bin" to the path if exists and not done already
  # if ((test-path "$GIT_INSTALL_ROOT\mingw32\bin") -and -not ($env:path -match "$GIT_INSTALL_ROOT_ESC\\mingw32\\bin")) {
  #     $env:path = "$env:path;$GIT_INSTALL_ROOT\mingw32\bin"
  # } elseif ((test-path "$GIT_INSTALL_ROOT\mingw64\bin") -and -not ($env:path -match "$GIT_INSTALL_ROOT_ESC\\mingw64\\bin")) {
  #     $env:path = "$env:path;$GIT_INSTALL_ROOT\mingw64\bin"
  # }

  # Proposed Behavior
  $gitRootEsc = $gitRoot.replace('\','\\')
  if (!($env:Path -match "$gitRootEsc\\cmd")) {
      $env:Path = $($gitRoot + "\cmd" + ";" + $env:Path)
  }

  # Modify the path if we are using VENDORED Git do nothing if using USER Git.
  # If User Git is installed but older match its path config adding paths
  # in the same path positions allowing a user to configure Cmder Git path
  # using locally installed Git Path Config.
  if ($gitType -eq 'VENDOR') {
      if (isNixCommand -filename 'curl.exe' -all $true) {
          if (isNixCommand -filename 'curl.exe') {
              $pathPosition = 'start'
          } else {
              $pathPosition = 'end'
          }

          if ($pathPosition -eq 'end') {
              # Add "$gitRoot\mingw[32|64]\bin" to the path if exists and not done already
              if ((test-path "$gitRoot\mingw32\bin") -and -not ($env:path -match "$gitRootEsc\\mingw32\\bin")) {
                  $env:path = "$env:path;$gitRoot\mingw32\bin"
              } elseif ((test-path "$gitRoot\mingw64\bin") -and -not ($env:path -match "$gitRootEsc\\mingw64\\bin")) {
                  $env:path = "$env:path;$gitRoot\mingw64\bin"
              }
          } elseif ($pathPosition -eq 'start') {
              if ((test-path "$gitRoot\mingw32\bin") -and -not ($env:path -match "$gitRootEsc\\mingw32\\bin")) {
                  $env:path = "$gitRoot\mingw32\bin;$env:path"
              } elseif ((test-path "$gitRoot\mingw64\bin") -and -not ($env:path -match "$gitRootEsc\\mingw64\\bin")) {
                  $env:path = "$gitRoot\mingw64\bin;$env:path"
              }
          }
      }

      if (isNixCommand -filename 'find' -all $true) {
          if (isNixCommand -filename 'find') {
              $pathPosition = 'start'
          } else {
              $pathPosition = 'end'
          }

          if ($pathPosition -eq 'end') {
              $env:path = "$env:path;$gitRoot\usr\bin"
          } elseif ($pathPosition -eq 'start') {
              $env:path = "$gitRoot\usr\bin;$env:path"
          }
      }
  }
}

function isWindowsCommand($filename, $all=$false) {
    if ($all) {
        $commands = (get-command $filename -All).source
    } else {
        $commands = (get-command $filename).source
    }

    return ($commands -match $env:systemroot.replace('\','\\'))
}

function isNixCommand($filename, $all=$false) {
    if ($all) {
        $commands = (get-command $filename -All).source
    } else {
        $commands = (get-command $filename).source
    }

    return ($commands -match '\\git' -and $commands.replace('\','\\') -match '\\bin\\')
}

function Import-Git(){

    $GitModule = Get-Module -Name Posh-Git -ListAvailable
    if($GitModule | select version | where version -le ([version]"0.6.1.20160330")){
        Import-Module Posh-Git > $null
    }
    if(-not ($GitModule) ) {
        Write-Warning "Missing git support, install posh-git with 'Install-Module posh-git' and restart cmder."
    }
    # Make sure we only run once by alawys returning true
    return $true
}

function checkGit($Path) {  
    if (Test-Path -Path (Join-Path $Path '.git') ) {
      if($env:gitLoaded -eq 'false') {
        $env:gitLoaded = Import-Git
      }

      if (getGitStatusSetting -eq $true) {
        Write-VcsStatus
      }

      return
    }
    $SplitPath = split-path $path
    if ($SplitPath) {
        checkGit($SplitPath)
    }
}

function getGitStatusSetting() {
    $gitStatus = (git --no-pager config -l) | out-string

    ForEach ($line in $($gitStatus -split "`r`n")) {
        if ($line -match 'cmder.status=false' -or $line -match 'cmder.psstatus=false') {
            return $false
        }
    }

    return $true
}

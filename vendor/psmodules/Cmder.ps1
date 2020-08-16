function readVersion($gitPath) {
    $gitExecutable = "${gitPath}\git.exe"

    #write-host "Git Path: ${gitExecutable}"
    if (!(test-path "$gitExecutable")) {
        return $null
    }

    $gitVersion = (cmd /c "${gitExecutable}" --version)
    #write-host "Git Version: ${gitVersion}"

    if ($gitVersion -match 'git version') {
        ($trash1, $trash2, $gitVersion) = $gitVersion.split(' ', 3)
    } else {
        #write-hose "'git --version' returned an inproper version string!"
        pause
        return $null
    }
    #write-host "Git Semantic Version: ${gitVersion}"

    return $gitVersion.toString()
}

function compareVersions($userVersion, $vendorVersion) {
    ($userMajor, $user_minor, $userPatch, $userBuild) = $userVersion.split('.', 4)
    ($vendorMajor, $vendorMinor, $vendorPatch, $vendorBuild) = $vendorVersion.split('.', 4)

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

    if ($result -eq 0) {
        return $userVersion
    } else {
        return $null
    }

}
function Configure-Git($GIT_INSTALL_ROOT){
  $GIT_INSTALL_ROOT_ESC=$GIT_INSTALL_ROOT.replace('\','\\')
  if (!($env:Path -match "$GIT_INSTALL_ROOT_ESC\\cmd")) {
      $env:Path = $($GIT_INSTALL_ROOT + "\cmd" + ";" + $env:Path)
  }

  # Add "$GIT_INSTALL_ROOT\usr\bin" to the path if exists and not done already
  if ((test-path "$GIT_INSTALL_ROOT\usr\bin") -and -not ($env:path -match "$GIT_INSTALL_ROOT_ESC\\usr\\bin")) {
      $env:path = "$env:path;$GIT_INSTALL_ROOT\usr\bin"
  }

  # Add "$GIT_INSTALL_ROOT\mingw[32|64]\bin" to the path if exists and not done already
  if ((test-path "$GIT_INSTALL_ROOT\mingw32\bin") -and -not ($env:path -match "$GIT_INSTALL_ROOT_ESC\\mingw32\\bin")) {
      $env:path = "$env:path;$GIT_INSTALL_ROOT\mingw32\bin"
  } elseif ((test-path "$GIT_INSTALL_ROOT\mingw64\bin") -and -not ($env:path -match "$GIT_INSTALL_ROOT_ESC\\mingw64\\bin")) {
      $env:path = "$env:path;$GIT_INSTALL_ROOT\mingw64\bin"
  }
}

function Import-Git(){

    $GitModule = Get-Module -Name Posh-Git -ListAvailable
    if($GitModule | select version | where version -le ([version]"0.6.1.20160330")){
        Import-Module Posh-Git > $null
    }
    if(-not ($GitModule) ) {
        Write-Warning "Missing git support, install posh-git with 'Install-Module posh-git' and restart cmder."
      A
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

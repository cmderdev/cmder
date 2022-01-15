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

    if (($userMajor -eq $vendorMajor) -and  ($userMinor -eq $vendorMinor) -and  ($userPatch -eq $vendorPatch) -and  ($userBuild -eq $vendorBuild)) {
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

function Configure-Git($gitRoot, $gitType, $gitPathUser){
    # Proposed Behavior

    # Modify the path if we are using VENDORED Git do nothing if using USER Git.
    # If User Git is installed but older match its path config adding paths
    # in the same path positions allowing a user to configure Cmder Git path
    # using locally installed Git Path Config.
    if ($gitType -eq 'VENDOR') {
        # If User Git is installed replace its path config with Newer Vendored Git Path
        if ($gitPathUser -ne '' -and $gitPathUser -ne $null) {
            # write-host "Cmder 'profile.ps1': Replacing older user Git path '$gitPathUser' with newer vendored Git path '$gitRoot' in the system path..."

            $newPath = ($env:path -ireplace [regex]::Escape($gitPathUser), $gitRoot)
        } else {
            if (!($env:Path -match [regex]::Escape("$gitRoot\cmd"))) {
                # write-host "Adding $gitRoot\cmd to the path"
                $newPath = $($gitRoot + "\cmd" + ";" + $env:Path)
            }

            # Add "$gitRoot\mingw[32|64]\bin" to the path if exists and not done already
            if ((test-path "$gitRoot\mingw32\bin") -and -not ($env:path -match [regex]::Escape("$gitRoot\mingw32\bin"))) {
                # write-host "Adding $gitRoot\mingw32\bin to the path"
                $newPath = "$newPath;$gitRoot\mingw32\bin"
            } elseif ((test-path "$gitRoot\mingw64\bin") -and -not ($env:path -match [regex]::Escape("$gitRoot\mingw64\bin"))) {
                # write-host "Adding $gitRoot\mingw64\bin to the path"
                $newPath = "$newPath;$gitRoot\mingw64\bin"
            }

            # Add "$gitRoot\usr\bin" to the path if exists and not done already
            if ((test-path "$gitRoot\usr\bin") -and -not ($env:path -match [regex]::Escape("$gitRoot\usr\bin"))) {
                # write-host "Adding $gitRoot\usr\bin to the path"
                $newPath = "$newPath;$gitRoot\usr\bin"
            }
        }

        return $newPath
    }

    return $env:path
}

function Import-Git(){
    $GitModule = Get-Module -Name Posh-Git -ListAvailable
    if($GitModule | select version | where version -le ([version]"0.6.1.20160330")){
        Import-Module Posh-Git > $null
    }
    if($GitModule | select version | where version -ge ([version]"1.0.0")){
        Import-Module Posh-Git > $null
        $GitPromptSettings.AnsiConsole = $false
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
      } else {
        $headContent = Get-Content (Join-Path $Path '.git/HEAD')
        if ($headContent -like "ref: refs/heads/*") {
            $branchName = $headContent.Substring(16)
        } else {
            $branchName = "HEAD detached at $($headContent.Substring(0, 7))"
        }
        Write-Host " [$branchName]" -NoNewline -ForegroundColor White
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

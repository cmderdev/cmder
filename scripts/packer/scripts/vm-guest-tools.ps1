if (!( Test-Path "C:\Windows\Temp\7z1900-x64.msi")) {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://www.7-zip.org/a/7z1900-x64.msi', 'C:\Windows\Temp\7z1900-x64.msi')
}
if (!(Test-Path "C:\Windows\Temp\7z1900-x64.msi")) {
  Start-Sleep 5; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://www.7-zip.org/a/7z1900-x64.msi', 'C:\Windows\Temp\7z1900-x64.msi')
}
cmd /c msiexec /qb /i C:\Windows\Temp\7z1900-x64.msi

if ("$env:PACKER_BUILDER_TYPE" -eq "vmware-iso") {

  Write-Output "Using VMware"
  if (Test-Path "C:\Users\vagrant\windows.iso") {
    Move-Item -force C:\Users\vagrant\windows.iso C:\Windows\Temp
  }

  if (!(Test-Path "C:\Windows\Temp\windows.iso")) {
    Try {
      # Disabling the progress bar speeds up IWR https://github.com/PowerShell/PowerShell/issues/2138
      $ProgressPreference = 'SilentlyContinue'
      $pageContentLinks = (Invoke-WebRequest('https://softwareupdate.vmware.com/cds/vmw-desktop/ws') -UseBasicParsing).Links | where-object { $_.href -Match "[0-9]" } | Select-Object href | ForEach-Object { $_.href.Trim('/') }
      $versionObject = $pageContentLinks | ForEach-Object { new-object System.Version ($_) } | sort-object -Descending | select-object -First 1 -Property:Major, Minor, Build
      $newestVersion = $versionObject.Major.ToString() + "." + $versionObject.Minor.ToString() + "." + $versionObject.Build.ToString() | out-string
      $newestVersion = $newestVersion.TrimEnd("`r?`n")

      $nextURISubdirectoryObject = (Invoke-WebRequest("https://softwareupdate.vmware.com/cds/vmw-desktop/ws/$newestVersion/") -UseBasicParsing).Links | where-object { $_.href -Match "[0-9]" } | Select-Object href | where-object { $_.href -Match "[0-9]" }
      $nextUriSubdirectory = $nextURISubdirectoryObject.href | Out-String
      $nextUriSubdirectory = $nextUriSubdirectory.TrimEnd("`r?`n")
      $newestVMwareToolsURL = "https://softwareupdate.vmware.com/cds/vmw-desktop/ws/$newestVersion/$nextURISubdirectory/windows/packages/tools-windows.tar"
      Write-Output "The latest version of VMware tools has been determined to be downloadable from $newestVMwareToolsURL"
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile("$newestVMwareToolsURL", 'C:\Windows\Temp\vmware-tools.tar')
    }
    Catch {
      Write-Output "Unable to determine the latest version of VMware tools. Falling back to hardcoded URL."
      (New-Object System.Net.WebClient).DownloadFile('https://softwareupdate.vmware.com/cds/vmw-desktop/ws/15.5.5/16285975/windows/packages/tools-windows.tar', 'C:\Windows\Temp\vmware-tools.tar')
    }
    cmd /c "C:\PROGRA~1\7-Zip\7z.exe" x C:\Windows\Temp\vmware-tools.tar -oC:\Windows\Temp
    Move-Item c:\windows\temp\VMware-tools-windows-*.iso c:\windows\temp\windows.iso
    Try { Remove-Item "C:\Program Files (x86)\VMWare" -Recurse -Force -ErrorAction Stop } Catch { Write-Output "Directory didn't exist to be removed." }
  }

  cmd /c "C:\PROGRA~1\7-Zip\7z.exe" x "C:\Windows\Temp\windows.iso" -oC:\Windows\Temp\VMWare
  cmd /c C:\Windows\Temp\VMWare\setup.exe /S /v"/qn REBOOT=R\"

  Remove-Item -Force "C:\Windows\Temp\vmware-tools.tar"
  Remove-Item -Force "C:\Windows\Temp\windows.iso"
  Remove-Item -Force -Recurse "C:\Windows\Temp\VMware"
}

if ("$env:PACKER_BUILDER_TYPE" -eq "virtualbox-iso") {
  Write-Output "Using Virtualbox"
  if (Test-Path "C:\Users\vagrant\VBoxGuestAdditions.iso") {
    Move-Item -Force C:\Users\vagrant\VBoxGuestAdditions.iso C:\Windows\Temp
  }

  if (!(Test-Path "C:\Windows\Temp\VBoxGuestAdditions.iso")) {
    Try {
      $pageContentLinks = (Invoke-WebRequest('https://download.virtualbox.org/virtualbox') -UseBasicParsing).Links | where-object { $_.href -Match "[0-9]" } | Select-Object href |  where-object { $_.href -NotMatch "BETA" } |  where-object { $_.href -NotMatch "RC" } |   where-object { $_.href -Match "[0-9]\.[0-9]" } | ForEach-Object { $_.href.Trim('/') }
      $versionObject = $pageContentLinks | ForEach-Object { new-object System.Version ($_) } | sort-object -Descending | select-object -First 1 -Property:Major, Minor, Build
      $newestVersion = $versionObject.Major.ToString() + "." + $versionObject.Minor.ToString() + "." + $versionObject.Build.ToString() | out-string
      $newestVersion = $newestVersion.TrimEnd("`r?`n")

      $nextURISubdirectoryObject = (Invoke-WebRequest("https://download.virtualbox.org/virtualbox/$newestVersion/") -UseBasicParsing).Links | Select-Object href | where-object { $_.href -Match "GuestAdditions" }
      $nextUriSubdirectory = $nextURISubdirectoryObject.href | Out-String
      $nextUriSubdirectory = $nextUriSubdirectory.TrimEnd("`r?`n")
      $newestVboxToolsURL = "https://download.virtualbox.org/virtualbox/$newestVersion/$nextUriSubdirectory"
      Write-Output "The latest version of VirtualBox tools has been determined to be downloadable from $newestVboxToolsURL"
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile("$newestVboxToolsURL", 'C:\Windows\Temp\VBoxGuestAdditions.iso')
    }
    Catch {
      Write-Output "Unable to determine the latest version of VBox tools. Falling back to hardcoded URL."
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://download.virtualbox.org/virtualbox/6.1.8/VBoxGuestAdditions_6.1.8.iso', 'C:\Windows\Temp\VBoxGuestAdditions.iso')
    }
  }

  cmd /c ""C:\PROGRA~1\7-Zip\7z.exe" x C:\Windows\Temp\VBoxGuestAdditions.iso -oC:\Windows\Temp\virtualbox"
  Get-ChildItem "C:\Windows\Temp\virtualbox\cert\" -Filter vbox*.cer | Foreach-Object { C:\Windows\Temp\virtualbox\cert\VBoxCertUtil add-trusted-publisher $_.FullName --root $_.FullName }
  cmd /c C:\Windows\Temp\virtualbox\VBoxWindowsAdditions.exe /S
  cmd /c rd /S /Q "C:\Windows\Temp\virtualbox"
}

if ("$env:PACKER_BUILDER_TYPE" -eq "parallels-iso") {
  Write-Output "Using Parallels Desktop"
  # This is required when using Parallels Desktop
  # Currently the installation of Parallels Tools is broken if you're installing in Windows Server & Windows Server Core
  # You will encounter an error in printui.dll module not found message.
  # This feature will add the required libraries for printing services.

  # Parallels Tools is required for sync_folder to work.
  # Vagrantfile config: v.update_guest_tools = true will be installed with no issues
  if ($(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName.StartsWith("Windows Server")) {
    Write-Output "Installing Print Server service"
    Install-WindowsFeature -Name Print-Server
  }  
}

cmd /c msiexec /qb /x C:\Windows\Temp\7z1900-x64.msi

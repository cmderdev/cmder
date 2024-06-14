[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param($global:RestartRequired = 0,
  $global:MoreUpdates = 0,
  $global:MaxCycles = 5,
  $MaxUpdatesPerCycle = 500,
  $BeginWithRestart = 0)

$Logfile = "C:\Windows\Temp\win-updates.log"

$enable_winrm_script = 'a:\enable-winrm.ps1'
if (test-path 'e:\enable-winrm.ps1') {
  $enable_winrm_script = 'e:\enable-winrm.ps1'
}

function LogWrite {
  Param ([string]$logstring)
  $now = Get-Date -format s
  Add-Content $Logfile -value "$now $logstring"
  Write-Output $logstring
}

function Check-ContinueRestartOrEnd() {
  $RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
  $RegistryEntry = "InstallWindowsUpdates"
  switch ($global:RestartRequired) {
    0 {
      $prop = (Get-ItemProperty $RegistryKey).$RegistryEntry
      if ($prop) {
        LogWrite "Restart Registry Entry Exists - Removing It"
        Remove-ItemProperty -Path $RegistryKey -Name $RegistryEntry -ErrorAction SilentlyContinue
      }

      LogWrite "No Restart Required"
      Check-WindowsUpdates

      if (($global:MoreUpdates -eq 1) -and ($script:Cycles -le $global:MaxCycles)) {
        Install-WindowsUpdates
      }
      elseif ($script:Cycles -gt $global:MaxCycles) {
        LogWrite "Exceeded Cycle Count - Stopping"
        LogWrite "==> Running '$enable_winrm_script'..."
        & $enable_winrm_script
      }
      else {
        LogWrite "Done Installing Windows Updates"
        LogWrite "==> Running '$enable_winrm_script'..."
        & $enable_winrm_script
      }
    }
    1 {
      $prop = (Get-ItemProperty $RegistryKey).$RegistryEntry
      if (-not $prop) {
        LogWrite "Restart Registry Entry Does Not Exist - Creating It"
        Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File $($script:ScriptPath) -MaxUpdatesPerCycle $($MaxUpdatesPerCycle)"
      }
      else {
        LogWrite "Restart Registry Entry Exists Already"
      }

      LogWrite "Restart Required - Restarting..."
      Restart-Computer
    }
    default {
      LogWrite "Unsure If A Restart Is Required"
      break
    }
  }
}

function Install-WindowsUpdates()
 {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
  param()
  $script:Cycles++
  LogWrite "Evaluating Available Updates with limit of $($MaxUpdatesPerCycle):"
  $UpdatesToDownload = New-Object -ComObject 'Microsoft.Update.UpdateColl'
  $script:i = 0;
  $CurrentUpdates = $SearchResult.Updates
  while ($script:i -lt $CurrentUpdates.Count -and $script:CycleUpdateCount -lt $MaxUpdatesPerCycle) {
    $Update = $CurrentUpdates.Item($script:i)
    if ($null -ne $Update) {
      [bool]$addThisUpdate = $false
      if ($Update.InstallationBehavior.CanRequestUserInput) {
        LogWrite "> Skipping: $($Update.Title) because it requires user input"
      }
      else {
        if (!($Update.EulaAccepted)) {
          LogWrite "> Note: $($Update.Title) has a license agreement that must be accepted. Accepting the license."
          $Update.AcceptEula()
          [bool]$addThisUpdate = $true
          $script:CycleUpdateCount++
        }
        else {
          [bool]$addThisUpdate = $true
          $script:CycleUpdateCount++
        }
      }

      if ([bool]$addThisUpdate) {
        LogWrite "Adding: $($Update.Title)"
        $UpdatesToDownload.Add($Update) | Out-Null
      }
    }
    $script:i++
  }

  if ($UpdatesToDownload.Count -eq 0) {
    LogWrite "No Updates To Download..."
  }
  else {
    LogWrite 'Downloading Updates...'
    $ok = 0;
    while (! $ok) {
      try {
        $Downloader = $UpdateSession.CreateUpdateDownloader()
        $Downloader.Updates = $UpdatesToDownload
        $Downloader.Download()
        $ok = 1;
      }
      catch {
        LogWrite $_.Exception | Format-List -force
        LogWrite "Error downloading updates. Retrying in 30s."
        $script:attempts = $script:attempts + 1
        Start-Sleep -s 30
      }
    }
  }

  $UpdatesToInstall = New-Object -ComObject 'Microsoft.Update.UpdateColl'
  [bool]$rebootMayBeRequired = $false
  LogWrite 'The following updates are downloaded and ready to be installed:'
  foreach ($Update in $SearchResult.Updates) {
    if (($Update.IsDownloaded)) {
      LogWrite "> $($Update.Title)"
      $UpdatesToInstall.Add($Update) | Out-Null

      if ($Update.InstallationBehavior.RebootBehavior -gt 0) {
        [bool]$rebootMayBeRequired = $true
      }
    }
  }

  if ($UpdatesToInstall.Count -eq 0) {
    LogWrite 'No updates available to install...'
    $global:MoreUpdates = 0
    $global:RestartRequired = 0
    LogWrite "==> Running '$enable_winrm_script'..."
    & $enable_winrm_script
    break
  }

  if ($rebootMayBeRequired) {
    LogWrite 'These updates may require a reboot'
    $global:RestartRequired = 1
  }

  LogWrite 'Installing updates...'

  $Installer = $script:UpdateSession.CreateUpdateInstaller()
  $Installer.Updates = $UpdatesToInstall
  $InstallationResult = $Installer.Install()

  LogWrite "Installation Result: $($InstallationResult.ResultCode)"
  LogWrite "Reboot Required: $($InstallationResult.RebootRequired)"
  LogWrite 'Listing of updates installed and individual installation results:'
  if ($InstallationResult.RebootRequired) {
    $global:RestartRequired = 1
  }
  else {
    $global:RestartRequired = 0
  }

  for ($i = 0; $i -lt $UpdatesToInstall.Count; $i++) {
    New-Object -TypeName PSObject -Property @{
      Title  = $UpdatesToInstall.Item($i).Title
      Result = $InstallationResult.GetUpdateResult($i).ResultCode
    }
    LogWrite "Item: $($UpdatesToInstall.Item($i).Title)"
    LogWrite "Result: $($InstallationResult.GetUpdateResult($i).ResultCode)"
  }

  Check-ContinueRestartOrEnd
}

function Check-WindowsUpdates() {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
  param()
  LogWrite "Checking For Windows Updates"
  $Username = $env:USERDOMAIN + "\" + $env:USERNAME
  LogWrite "Script: $script:ScriptPath `nScript User: $Username `nStarted: $(Get-Date)"

  $script:UpdateSearcher = $script:UpdateSession.CreateUpdateSearcher()
  $script:successful = $FALSE
  $script:attempts = 0
  $script:maxAttempts = 12
  while (-not $script:successful -and $script:attempts -lt $script:maxAttempts) {
    try {
      $script:SearchResult = $script:UpdateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
      $script:successful = $TRUE
    }
    catch {
      LogWrite $_.Exception | Format-List -force
      LogWrite "Search call to UpdateSearcher was unsuccessful. Retrying in 10s."
      $script:attempts = $script:attempts + 1
      Start-Sleep -s 10
    }
  }

  if ($SearchResult.Updates.Count -ne 0) {
    $Message = "There are " + $SearchResult.Updates.Count + " more updates."
    LogWrite $Message
    try {
      for ($i = 0; $i -lt $script:SearchResult.Updates.Count; $i++) {
        LogWrite $script:SearchResult.Updates.Item($i).Title
        LogWrite $script:SearchResult.Updates.Item($i).Description
        LogWrite $script:SearchResult.Updates.Item($i).RebootRequired
        LogWrite $script:SearchResult.Updates.Item($i).EulaAccepted
      }
      $global:MoreUpdates = 1
    }
    catch {
      LogWrite $_.Exception | Format-List -force
      LogWrite "Showing SearchResult was unsuccessful. Rebooting."
      $global:RestartRequired = 1
      $global:MoreUpdates = 0
      Check-ContinueRestartOrEnd
      LogWrite "Show never happen to see this text!"
      Restart-Computer
    }
  }
  else {
    LogWrite 'There are no applicable updates'
    $global:RestartRequired = 0
    $global:MoreUpdates = 0
  }
}

$script:ScriptName = $MyInvocation.MyCommand.ToString()
$script:ScriptPath = $MyInvocation.MyCommand.Path
$script:UpdateSession = New-Object -ComObject 'Microsoft.Update.Session'
$script:UpdateSession.ClientApplicationID = 'Packer Windows Update Installer'
$script:UpdateSearcher = $script:UpdateSession.CreateUpdateSearcher()
$script:SearchResult = New-Object -ComObject 'Microsoft.Update.UpdateColl'
$script:Cycles = 0
$script:CycleUpdateCount = 0

if ($BeginWithRestart) {
  $global:RestartRequired = 1
  Check-ContinueRestartOrEnd
}

Check-WindowsUpdates
if ($global:MoreUpdates -eq 1) {
  Install-WindowsUpdates
}
else {
  Check-ContinueRestartOrEnd
}

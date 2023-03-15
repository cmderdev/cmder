# Windows Terminal
$windowsTerminalFolder = (dir "$env:userprofile/AppData/Local/Packages/Microsoft.WindowsTerminal_*").name
$windowsTerminalPath = "$env:userprofile/AppData/Local/Packages/$windowsTerminalFolder"
$windowsTerminalSettings = $windowsTerminalPath + '/localState/settings.json'
$windowsTerminalSettingsNew = $windowsTerminalPath + '/localState/settings-new.json'

if (test-path "$env:userprofile/Documents/windows_terminal_settings.json.default") {
  if (test-path "$windowsTerminalPath/LocalState/settings.json") {
    del "$env:userprofile/Documents/windows_terminal_settings.json.default"
  } else {
    move-item -path $env:userprofile/Documents/windows_terminal_settings.json.default -destination $windowsTerminalPath/LocalState/settings.json
  }
}

if (test-path "$env:userprofile/Documents/windows_terminal_state.json.default") {
  if (test-path "$windowsTerminalPath/LocalState/state.json") {
    del "$env:userprofile/Documents/windows_terminal_state.json.default"
  } else {
    move-item -path $env:userprofile/Documents/windows_terminal_state.json.default -destination $windowsTerminalPath/LocalState/state.json
  }
}

$json = get-content $windowsTerminalSettings | ConvertFrom-Json

$json.defaultProfile="{00000000-0000-0000-ba54-000000000132}"

$cmderFound = $false
$cmderAsAdminFound = $false

foreach ($profile in $json.profiles.list) {
  if ($profile.Name -eq "Cmder") {
    $cmderFound = $true
  }
  elseIf ($profile.Name -eq "Cmder as Admin") {
    $cmderAsAdminFound = $true
  }
}

if (-not $cmderFound) {
  write-host "Adding 'Cmder' to Windows Terminal..."

  $json.profiles.list += @{
    commandline="cmd.exe /k `"%USERPROFILE%/cmderdev/vendor/init.bat`"";
    startingDirectory="%USERPROFILE%/cmderdev";
    icon="%USERPROFILE%/cmderdev/icons/cmder.ico";
    closeOnExit="graceful";
    guid="{00000000-0000-0000-ba54-000000000132}";
    hidden=$false;
    name="Cmder"
  }
}

if (-not $cmderAsAdminFound) {
  write-host "Adding 'Cmder as Admin' to Windows Terminal..."

  $json.profiles.list += @{
    commandline="cmd.exe /k `"%USERPROFILE%/cmderdev/vendor/init.bat`"";
    startingDirectory="%USERPROFILE%/cmderdev";
    icon="%USERPROFILE%/cmderdev/icons/cmder_red.ico";
    closeOnExit="graceful";
    guid="{00000000-0000-0000-ba54-000000000133}";
    hidden=$false;
    elevate=$true;
    name="Cmder as Admin"
  }
}

$json | ConvertTo-Json -depth 100 | set-content $windowsTerminalSettings



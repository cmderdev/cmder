if (test-path "c:\windows\set-shortcut.ps1") {
  $setShortcut = "c:\windows\set-shortcut.ps1"
}

if (test-path "${env:USERPROFILE}\cmderdev") {
  $env:cmder_root = "${env:USERPROFILE}\cmderdev"
  write-host "Creating '${env:USERPROFILE}\Desktop\Cmderdev.lnk'..."

  if (test-path "${env:USERPROFILE}\cmderdev\vendor\bin\set-shortcut.ps1") {
    $setShortcut = "$env:cmder_root\vendor\bin\set-shortcut.ps1"
  }

  start-process -NoNewWindow -filePath "powershell.exe" -ArgumentList "-file `"${setShortcut}`" -sourceexe `"${env:cmder_root}\Cmder.exe`" -DestinationPath `"${env:USERPROFILE}\Desktop\Cmderdev.lnk`" -WorkingDirectory `"${env:cmder_root}`""
}

if (test-path "${env:USERPROFILE}\cmder") {
  $env:cmder_root = "${env:USERPROFILE}\cmder"

  if (test-path "${cmder_root}\vendor\bin\set-shortcut.ps1") {
    $setShortcut = "$env:cmder_root\vendor\bin\set-shortcut.ps1"
  }

  write-host "Creating '${env:USERPROFILE}\Desktop\Cmder.lnk'..."
  start-process -NoNewWindow -filePath "powershell.exe" -ArgumentList "-file `"${setShortcut}`" -sourceexe `"$env:cmder_root\Cmder.exe`" -DestinationPath `"${env:USERPROFILE}\Desktop\Cmder.lnk`" -WorkingDirectory `"${env:USERPROFILE}`""
} elseif (test-path "C:\tools\cmder") {
  $env:cmder_root = "C:\tools\cmder"

  if (test-path "${cmder_root}\vendor\bin\set-shortcut.ps1") {
    $setShortcut = "$env:cmder_root\vendor\bin\set-shortcut.ps1"
  }

  write-host "Creating '${env:USERPROFILE}\Desktop\Cmder.lnk'..."
  start-process -NoNewWindow -filePath "powershell.exe" -ArgumentList "-file `"${setShortcut}`" -sourceexe `"$env:cmder_root\Cmder.exe`" -DestinationPath `"${env:USERPROFILE}\Desktop\Cmder.lnk`" -WorkingDirectory `"${env:USERPROFILE}`""
}



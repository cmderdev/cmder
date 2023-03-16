if (test-path "${env:USERPROFILE}\cmder") {
  $env:cmder_root = "${env:USERPROFILE}\cmder"
  write-host "Creating '${env:USERPROFILE}\Desktop\Cmder.lnk'..."
  start-process -NoNewWindow -filePath "powershell.exe" -ArgumentList "-file `"$env:cmder_root\vendor\bin\set-shortcut.ps1`" -sourceexe `"$env:cmder_root\Cmder.exe`" -DestinationPath `"${env:USERPROFILE}\Desktop\Cmder.lnk`" -WorkingDirectory `"${env:USERPROFILE}`""
} elseif (test-path "C:\tools\cmder") {
  $env:cmder_root = "C:\tools\cmder"
  write-host "Creating '${env:USERPROFILE}\Desktop\Cmder.lnk'..."
  start-process -NoNewWindow -filePath "powershell.exe" -ArgumentList "-file `"$env:cmder_root\vendor\bin\set-shortcut.ps1`" -sourceexe `"$env:cmder_root\Cmder.exe`" -DestinationPath `"${env:USERPROFILE}\Desktop\Cmder.lnk`" -WorkingDirectory `"${env:USERPROFILE}`""
}

if (test-path "${env:USERPROFILE}\cmderdev") {
  $env:cmder_root = "${env:USERPROFILE}\cmderdev"
  write-host "Creating '${env:USERPROFILE}\Desktop\Cmderdev.lnk'..."
  start-process -NoNewWindow -filePath "powershell.exe" -ArgumentList "-file `"$env:cmder_root\vendor\bin\set-shortcut.ps1`" -sourceexe `"${env:cmder_root}\Cmder.exe`" -DestinationPath `"${env:USERPROFILE}\Desktop\Cmderdev.lnk`" -WorkingDirectory `"${env:cmder_root}`""
}


# Init Script for powershell.exe
# Sets some nice defaults
# Created as part of cmder project

# Setting prompt style
function prompt
{
  Write-Host $(get-location) -foregroundcolor Green
  Write-Host "λ" -nonewline  -foregroundcolor DarkGray
  Write-Host ""  -nonewline  -foregroundcolor White
  return " "
}


# Set home path

# cd into users homedir
Set-Location -Path "$env:userprofile"
Write-Output "Welcome to cmder!" ""

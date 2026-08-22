[CmdletBinding()]
param(
    [Parameter()]
    [string]$SourceExe,
    [string]$Arguments,
    [string]$DestinationPath,
    [string]$WorkingDirectory,
    [String]$IconLocation
)

if ($IconLocation -eq '') {
    $IconLocation = $SourceExe
}

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($destinationPath)
$Shortcut.TargetPath = $SourceExe
$Shortcut.Arguments = $Arguments
$shortcut.WorkingDirectory = $WorkingDirectory
$shortcut.IconLocation = $IconLocation
$Shortcut.Save()

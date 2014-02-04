# Autoinclude every .ps1 script in the autorun folder.
Get-ChildItem -Filter *.ps1 -File "$PSScriptRoot\autorun\" | ForEach-Object {
    . $_.FullName
}

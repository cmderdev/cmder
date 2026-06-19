if (Test-Path "$env:TEMP\cmder_diag_ps.log") {
    Remove-Item "$env:TEMP\cmder_diag_ps.log"
}

$CmderDiag = {
    ""
    "------------------------------------"
    "Get-ChildItem env:"
    "------------------------------------"
    Get-ChildItem env: | Format-Table -AutoSize -Wrap 2>&1

    ""
    "------------------------------------"
    "Get-Command git -All -ErrorAction SilentlyContinue"
    "------------------------------------"
    Get-Command git -All -ErrorAction SilentlyContinue

    ""
    "------------------------------------"
    "Get-Command clink -All -ErrorAction SilentlyContinue"
    "------------------------------------"
    Get-Command clink -All -ErrorAction SilentlyContinue

    ""
    "------------------------------------"
    "Systeminfo"
    "------------------------------------"
    systeminfo 2>&1

    "------------------------------------"
    "Get-ChildItem '$env:CMDER_ROOT'"
    "------------------------------------"
    Get-ChildItem "$env:CMDER_ROOT" | Format-Table LastWriteTime, Mode, Length, FullName

    ""
    "------------------------------------"
    "Get-ChildItem '$env:CMDER_ROOT/vendor'"
    "------------------------------------"
    Get-ChildItem "$env:CMDER_ROOT/vendor" | Format-Table LastWriteTime, Mode, Length, FullName

    ""
    "------------------------------------"
    "Get-ChildItem -Recurse '$env:CMDER_ROOT/bin'"
    "------------------------------------"
    Get-ChildItem -Recurse "$env:CMDER_ROOT/bin" | Format-Table LastWriteTime, Mode, Length, FullName

    ""
    "------------------------------------"
    "Get-ChildItem -Recurse '$env:CMDER_ROOT/config'"
    "------------------------------------"
    Get-ChildItem -Recurse "$env:CMDER_ROOT/config" | Format-Table LastWriteTime, Mode, Length, FullName

    ""
    "------------------------------------"
    "Make sure you sanitize this output of private data prior to posting it online for review by the CMDER Team!"
    "------------------------------------"
}

& $CmderDiag | Out-File -FilePath "$env:TEMP\cmder_diag_ps.log"

Get-Content "$env:TEMP\cmder_diag_ps.log"

Write-Host ""
Write-Host "Above output was saved in $env:TEMP\cmder_diag_ps.log"

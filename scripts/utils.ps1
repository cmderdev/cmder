function Ensure-Exists ($path) {
    if (-not (Test-Path $path)) {
        Write-Error "Missing required $path! Ensure it is installed"
        exit 1
    }
    return $true > $null
}

function Ensure-Executable ($command) {
    try { Get-Command $command -ErrorAction Stop > $null }
    catch {
        If( ($command -eq "7z") -and (Test-Path "$env:programfiles\7-zip\7z.exe") ){
            set-alias -Name "7z" -Value "$env:programfiles\7-zip\7z.exe" -Scope script
        }
        ElseIf( ($command -eq "7z") -and (Test-Path "$env:programw6432\7-zip\7z.exe") ) {
            set-alias -Name "7z" -Value "$env:programw6432\7-zip\7z.exe" -Scope script             
        }
        Else {
            Write-Error "Missing $command! Ensure it is installed and on in the PATH"
            exit 1
        }
    }
}

function Delete-Existing ($path) {
    Write-Verbose "Remove $path"
    Remove-Item -Recurse -force $path -ErrorAction SilentlyContinue
}

function Extract-Archive ($source, $target) {
    Invoke-Expression "7z x -y -o$($target) $source  > `$null"
    if ($lastexitcode -ne 0) {
        Write-Error "Extracting of $source failied"
    }
    Remove-Item $source
}

function Create-Archive ($source, $target, $params) {
    $command = "7z a -x@`"$source\packignore`" $params $target $source  > `$null"
    Write-Verbose "Running: $command"
    Invoke-Expression $command
    if ($lastexitcode -ne 0) {
        Write-Error "Compressing $source failied"
    }
}

# If directory contains only one child directory
# Flatten it instead
function Flatten-Directory ($name) {
    $child = (Get-Childitem $name)[0]
    Rename-Item $name -NewName "$($name)_moving"
    Move-Item -Path "$($name)_moving\$child" -Destination $name
    Remove-Item -Recurse "$($name)_moving"
}

function Digest-MD5 ($path) {
    return Invoke-Expression "md5sum $path"
}

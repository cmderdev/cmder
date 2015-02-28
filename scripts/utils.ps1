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
        if (($command -eq "7z") -and (Test-Path "$env:programfiles\7-zip\7z.exe") ){
            Set-Alias -Name "7z" -Value "$env:programfiles\7-zip\7z.exe" -Scope script
        }
        elseif (($command -eq "7z") -and (Test-Path "$env:programw6432\7-zip\7z.exe") ) {
            Set-Alias -Name "7z" -Value "$env:programw6432\7-zip\7z.exe" -Scope script             
        }
        else {
            Write-Error "Missing $command! Ensure it is installed and on in the PATH"
            exit 1
        }
    }
}

function Delete-Existing ($path) {
    Write-Verbose "Remove $path"
    Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
}

function Extract-Archive ($source, $target) {
    # Get the information of the archive
    $archiveType = Invoke-Expression "7z l $source"
    
    # Loop through each line until we find the type of the archive
    foreach ($line in $archiveType) {
        if ($line -match "Type = (.+)") {
            $archiveType = $matches[1]

            # We found the line so stop checking
            break
        }
    }

    # Do special things if the file is gzipped
    if ($archiveType -eq "gzip") {
        # Filename is hub.tmp, extracting to filename hub
        Invoke-Expression "7z x -y $source > `$null"

        # Remove the original .tmp file
        Remove-Item $source

        # File is extracted so the filename is now the original without extension
        $extractedName = $source.Replace(".tmp", "")

        # The new name should be extracted filename with added .gz extension
        $newName = "$extractedName.gz"
        Write-Verbose "name $extName"

        # Rename extracted filename without extension to new name with .gz extension
        Rename-Item $extractedName -NewName $newName

        # The source is now filename with .gz extension instead of .tmp
        $source = $newName
    }

    Invoke-Expression "7z x -y -o$($target) $source > `$null"
    if ($lastexitcode -ne 0) {
        Write-Error "Extracting of $source failed"
    }
    Remove-Item $source
}

function Create-Archive ($source, $target, $params) {
    $command = "7z a -x@`"$source\packignore`" $params $target $source  > `$null"
    Write-Verbose "Running: $command"
    Invoke-Expression $command
    if ($lastexitcode -ne 0) {
        Write-Error "Compressing $source failed"
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

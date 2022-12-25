<#
.Synopsis
    Update Cmder vendored dependencies
.DESCRIPTION
    This script updates dependencies to the latest version in vendor/sources.json file.

    You will need to make this script executable by setting your Powershell Execution Policy to Remote signed
    Then unblock the script for execution with UnblockFile .\build.ps1
.EXAMPLE
    .\build.ps1

    Updates the dependency sources in the default location, the vendor/sources.json file.
.EXAMPLE
    .\build -verbose

    Updates the dependency sources and see what's going on.
.EXAMPLE
    .\build.ps1 -SourcesPath '~/custom/vendors.json'

    Specify the path to update dependency sources file at.
.NOTES
    AUTHORS
    David Refoua <David@Refoua.me>
    Part of the Cmder project.
.LINK
    http://cmder.app/ - Project Home
#>
[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    # CmdletBinding will give us;
    # -verbose switch to turn on logging and
    # -whatif switch to not actually make changes

    # Path to the vendor configuration source file
    [string]$sourcesPath = "$PSScriptRoot\..\vendor\sources.json"
)

# Get the root directory of the cmder project.
$cmder_root = Resolve-Path "$PSScriptRoot\.."

# Dot source util functions into this scope
. "$PSScriptRoot\utils.ps1"
$ErrorActionPreference = "Stop"

# Attempts to match the current link with the new link, returning the count of matching characters.
function Match-Filenames {
    param (
        $url,
        $downloadUrl,
        $fromEnd
    )

    $filename = [System.IO.Path]::GetFileName($url)
    $filenameDownload = [System.IO.Path]::GetFileName($downloadUrl)

    $position = 0

    if ([String]::IsNullOrEmpty($filename) -or [String]::IsNullOrEmpty($filenameDownload)) {
        throw "Either one or both filenames are empty!"
    }

    if ($fromEnd) {
        $arr = $filename -split ""
        [array]::Reverse($arr)
        $filename = $arr -join ''
        $arr = $filenameDownload -split ""
        [array]::Reverse($arr)
        $filenameDownload = $arr -join ''
    }

    while ($filename.Substring($position, 1) -eq $filenameDownload.Substring($position, 1)) {
        $position++

        if ( ($position -ge $filename.Length) -or ($position -ge $filenameDownload.Length) ) {
            break
        }
    }

    return $position
}

# Uses the GitHub api in order to fetch the current download links for the latest releases of the repo.
function Fetch-DownloadUrl {
    param (
        [Parameter(Mandatory = $true)]
        $urlStr
    )

    $url = [uri] $urlStr

    if ((-not $url) -or ($null -eq $url) -or ($url -eq '')) {
        throw "Failed to parse url: $urlStr"
    }

    if (-not ("http", "https" -contains $url.Scheme)) {
        throw "unknown source scheme: $($url.Scheme)"
    }

    if (-not ($url.Host -ilike "*github.com")) {
        throw "unknown source domain: $($url.Host)"
    }

    $p = $url.Segments.Split([Environment]::NewLine)

    $headers = @{}

    if ($env:GITHUB_TOKEN) {
        $headers["Authorization"] = "token $($env:GITHUB_TOKEN)"
    }

    # Api server for GitHub
    $urlHost = "api.github.com"

    # Path for releases end-point
    $urlPath = [IO.Path]::Combine('repos', $p[1], $p[2], 'releases').Trim('/')

    $apiUrl = [uri] (New-Object System.UriBuilder -ArgumentList $url.Scheme, $urlHost, -1, $urlPath).Uri

    $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers

    $downloadLinks = (New-Object System.Collections.Generic.List[System.Object])

    $charCount = 0

    if (-not ($info -is [array])) {
        throw "The response received from API server is invalid"
    }

    :loop foreach ($i in $info) {
        if (-not ($i.assets -is [array])) {
            continue
        }

        foreach ($a in $i.assets) {
            if ([String]::IsNullOrEmpty($a.browser_download_url)) {
                continue
            }

            # Skip some download links as we're not interested in them
            if ( $a.browser_download_url -ilike "*_symbols*" ) {
                continue
            }

            $score = Match-Filenames $url $a.browser_download_url

            # Skip links that don't match or are less similar
            if ( ($score -eq 0) -or ($score -lt $charCount) ) {
                continue
            }

            # If we reach the same download link as we have
            if ( $score -eq [System.IO.Path]::GetFileName($url).Length ) {
            }

            $charCount = $score
            $downloadLinks.Add($a.browser_download_url)
        }

        # If at least one download link was found, don't continue with older releases
        if ( $downloadLinks.Length -gt 0 ) {
            break :loop
        }
    }

    # Special case for archive downloads of repository
    if (($null -eq $downloadLinks) -or (-not $downloadLinks)) {
        if ((($p | ForEach-Object { $_.Trim('/') }) -contains "archive") -and $info[0].tag_name) {
            for ($i = 0; $i -lt $p.Length; $i++) {
                if ($p[$i].Trim('/') -eq "archive") {
                    $p[$i + 1] = $info[0].tag_name + ".zip"
                    $downloadLinks = $url.Scheme + "://" + $url.Host + ($p -join '')
                    return $downloadLinks
                }
            }
        }
        return ''
    }

    $temp = $downloadLinks | Where-Object { (Match-Filenames $url $_) -eq $charCount }

    $downloadLinks = (New-Object System.Collections.Generic.List[System.Object])

    $charCount = 0

    foreach ($l in $temp) {
        $score = Match-Filenames $url $l true

        if ( ($score -eq 0) -or ($score -lt $charCount) ) {
            continue
        }

        $charCount = $score
    }

    $downloadLinks = $temp | Where-Object { (Match-Filenames $url $_ true) -eq $charCount }

    if (($null -eq $downloadLinks) -or (-not $downloadLinks)) {
        throw "No suitable download links matched for the url!"
    }

    if (-not($downloadLinks -is [String])) {
        throw "Found multiple matches for the same url:`n" + $downloadLinks
    }

    return $downloadLinks
}

$count = 0

# Read the current sources content
$sources = Get-Content $sourcesPath | Out-String | ConvertFrom-Json

foreach ($s in $sources) {
    Write-Verbose "Updating sources link for $($s.name)..."

    Write-Verbose "Old Link: $($s.url)"

    $downloadUrl = Fetch-DownloadUrl $s.url

    if (($null -eq $downloadUrl) -or ($downloadUrl -eq '')) {
        Write-Verbose "No new links were found"
        continue
    }

    Write-Verbose "Link: $downloadUrl"

    $url = [uri] $downloadUrl

    $version = ''

    if (($url.Segments[-3] -eq "download/") -and ($url.Segments[-2].StartsWith("v"))) {
        $version = $url.Segments[-2].TrimStart('v').TrimEnd('/')
    }

    if (($url.Segments[-2] -eq "archive/")) {
        $version = [System.IO.Path]::GetFileNameWithoutExtension($url.Segments[-1].TrimStart('v').TrimEnd('/'))
    }

    if ($version -eq '') {
        throw "Unable to extract version from url string"
    }

    Write-Verbose "Version: $version"

    if ( $s.version -ne $version ) {
        # if ( ([System.Version] $s.version) -gt ([System.Version] $version) ) {
        # 	throw "The current version $($s.version) is already newer than the found version $version!"
        # }

        $count++
    }

    $s.url = $downloadUrl
    $s.version = $version
}

$sources | ConvertTo-Json | Set-Content $sourcesPath

if ($count -eq 0) {
    Write-Host -ForegroundColor yellow "No new releases were found."
    return
}

if ($Env:APPVEYOR -eq 'True') {
    Add-AppveyorMessage -Message "Successfully updated $count dependencies." -Category Information
}

if ($Env:GITHUB_ACTIONS -eq 'true') {
    Write-Output "::notice title=Task Complete::Successfully updated $count dependencies."
}

Write-Host -ForegroundColor green "Successfully updated $count dependencies."

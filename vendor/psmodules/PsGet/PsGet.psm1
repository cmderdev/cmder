<#
.SYNOPSIS
    PowerShell module installation stuff.
    URL: https://github.com/psget/psget
    Based on http://poshcode.org/1875 Install-Module by Joel Bennett
#>
#requires -Version 2.0

#region Setup

Write-Debug 'Set up the global scope config variables.'
$global:UserModuleBasePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'WindowsPowerShell\Modules'
$global:CommonGlobalModuleBasePath = Join-Path -Path $env:CommonProgramFiles -ChildPath 'Modules'

if (-not (Test-Path -Path:variable:global:PsGetDirectoryUrl)) {
    $global:PsGetDirectoryUrl = 'https://github.com/psget/psget/raw/master/Directory.xml'
}
# NOTE: $global:PsGetDestinationModulePath is used by Install-Module as configuration if set by user.

Write-Debug 'Set up needed constants.'
Set-Variable -Name PSGET_ZIP -Value 'ZIP' -Option Constant -Scope Script
Set-Variable -Name PSGET_PSM1 -Value 'PSM1' -Option Constant -Scope Script
Set-Variable -Name PSGET_PSD1 -Value 'PSD1' -Option Constant -Scope Script

#endregion

#region Exported Cmdlets

<#
    .SYNOPSIS
        Installs PowerShell modules from a variety of sources including: Nuget, PsGet module directory, local directory, zipped folder and web URL.

    .DESCRIPTION
        Supports installing modules for the current user or all users (if elevated).

    .PARAMETER Module
        Name of the module to install.

    .PARAMETER ModuleUrl
        URL to the module to install; Can be direct link to PSM1 file or ZIP file. Can be a shortened link.

    .PARAMETER ModulePath
        Local path to the module to install.

    .PARAMETER ModuleName
       In context with -ModuleUrl or -ModulePath it is not always possible to interfere the right ModuleName, eg. the filename is unknown or the zip archive contains multiple modules.

    .PARAMETER Type
        When ModuleUrl or ModulePath specified, allows specifying type of the package. Can be ZIP or PSM1.

    .PARAMETER NuGetPackageId
        NuGet package name containing the module to install.

    .PARAMETER PackageVersion
        Allows a specific version of the specified NuGet package to used, if not specified then the latest stable version will be used.

    .PARAMETER NugetSource
        URL to the NuGet feed containing the package.

    .PARAMETER PreRelease
        If PackageVersion is not specified, then this switch allows the latest prerelease package to be used.

    .PARAMETER PreReleaseTag
        If PackageVersion is not specified, then this parameter allows the latest version of a particular prerelease tag to be used

    .PARAMETER Destination
        When specified the module will be installed below this path. Defaults to '$global:PsGetDestinationModulePath' if defined.

    .PARAMETER ModuleHash
        When ModuleHash is specified the chosen module will only be installed if its contents match the provided hash.

    .PARAMETER Global
        If set, attempts to install the module to the all users location in C:\Program Files\Common Files\Modules...

        NOTE: If the -Destination directory is specified, then -Global will only have an effect in combination with '-PersistEnvironment'. This is also the case if '$global:PsGetDestinationModulePath' is defined.

    .PARAMETER DoNotImport
        Indicates that command should not import module after installation

    .PARAMETER AddToProfile
        Adds Import-Module statement for installed module to the profile.ps1

    .PARAMETER Update
        Forces module to be updated

    .PARAMETER DirectoryUrl
        URL to central directory. By default it uses the value in the $global:PsGetDirectoryUrl variable

    .PARAMETER PersistEnvironment
        If this switch is specified, the installation destination path will be added to either the User's PSModulePath environment variable or Machine's PSModulePath environment variable (if -Global specified)

    .PARAMETER InstallWithModuleName
        Allows to specify the name of the module and override the ModuleName normally used.
        NOTE: This parameter allows to install a module from the PsGet-Directory more than once and PsGet does not remember that this module is installed with a different name.

    .PARAMETER DoNotPostInstall
        If defined, the PostInstallHook is not executed.

    .PARAMERTER PostInstallHook
        Defines the name of a script inside the installed module folder which should be executed after installation.
        Default: definition in directory file or 'Install.ps1'

    .PARAMETER Force
        OBSOLATE
        Alternative name for 'Update'.

    .PARAMETER Startup
        OBSOLATE
        Alternative name for 'AddToProfile'.

    .LINK
        http://psget.net

    .EXAMPLE
        # Install-Module PsConfig -DoNotImport

        Description
        -----------
        Installs the module witout importing it to the current session

    .EXAMPLE
        # Install-Module PoshHg -AddToProfile

        Description
        -----------
        Installs the module and then adds impoer of the given module to your profile.ps1 file

    .EXAMPLE
        # Install-Module PsUrl

        Description
        -----------
        This command will query module information from central registry and install required stuff.

    .EXAMPLE
        # Install-Module -ModulePath .\Authenticode.psm1 -Global

        Description
        -----------
        Installs the Authenticode module to the System32\WindowsPowerShell\v1.0\Modules for all users to use.

    .EXAMPLE
        # Install-Module -ModuleUrl https://github.com/chaliy/psurl/raw/master/PsUrl/PsUrl.psm1

        Description
        -----------
        Installs the PsUrl module to the users modules folder

    .EXAMPLE
        # Install-Module -ModuleUrl http://bit.ly/e1X4BO -ModuleName "PsUrl"

        Description
        -----------
        Installs the PsUrl module with name specified, because command will not be able to guess it

    .EXAMPLE
        # Install-Module -ModuleUrl https://github.com/psget/psget/raw/master/TestModules/HelloWorld.zip

        Description
        -----------
        Downloads HelloWorld module (module can have more than one file) and installs it

    .EXAMPLE
        # Install-Module -NugetPackageId SomePackage

        Description
        -----------
        Downloads the latest stable version of the 'SomePackage' module from the NuGet Gallery

    .EXAMPLE
        # Install-Module -NugetPackageId SomePackage -PackageVersion 1.0.2-beta

        Description
        -----------
        Downloads the specified version of the 'SomePackage' module from the NuGet Gallery

    .EXAMPLE
        # Install-Module -NugetPackageId SomePackage -PreRelease

        Description
        -----------
        Downloads the latest pre-release version of the 'SomePackage' module from the NuGet Gallery

    .EXAMPLE
        # Install-Module -NugetPackageId SomePackage -PreReleaseTag beta -NugetSource http://myget.org/F/myfeed

        Description
        -----------
        Downloads the latest 'beta' pre-release version of the 'SomePackage' module from a custom NuGet feed
#>
function Install-Module {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true, ParameterSetName='CentralDirectory')]
        [String] $Module,

        [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory=$true, ParameterSetName='Web')]
        [String] $ModuleUrl,

        [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory=$true, ParameterSetName='Local')]
        [String] $ModulePath,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='Web')]
        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='Local')]
        [String] $ModuleName,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='Web')]
        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='Local')]
        [ValidateSet('ZIP', 'PSM1', 'PSD1', '')] # $script:PSGET_ZIP, $script:PSGET_PSM1 or $script:PSGET_PSD1
        [String] $Type,

        [Parameter(ValueFromPipelineByPropertyName=$true, Mandatory=$true, ParameterSetName='NuGet')]
        [ValidatePattern('^\w+([_.-]\w+)*$')] # regex from NuGet.PackageIdValidator._idRegex
        [ValidateLength(1,100)] # maximum length from NuGet.PackageIdValidator.MaxPackageIdLength
        [String] $NuGetPackageId,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='NuGet')]
        [String] $PackageVersion,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='NuGet')]
        [String] $NugetSource = 'https://nuget.org/api/v2/',

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='NuGet')]
        [Switch] $PreRelease,

        [Parameter(ValueFromPipelineByPropertyName=$true, ParameterSetName='NuGet')]
        [String] $PreReleaseTag,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $Destination = $global:PsGetDestinationModulePath,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $ModuleHash,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Global,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotImport,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $AddToProfile,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Update,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $DirectoryUrl = $global:PsGetDirectoryUrl,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $PersistEnvironment,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $InstallWithModuleName,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotPostInstall,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $PostInstallHook,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Force,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Startup
    )
    process {

        if ($Force) {
            Write-Verbose 'Force parameter is considered obsolete. Please use Update instead.'
            $Update = $true
        }

        if ($Startup) {
            Write-Verbose 'Startup parameter is considered obsolete. Please use AddToProfile instead.'
            $AddToProfile = $true
        }

        if (-not $Destination) {
            $Destination = if ($Global) { $global:CommonGlobalModuleBasePath } else { $global:UserModuleBasePath }

            #Because we are using the default location, always ensure it is persisted
            $PersistEnvironment = $true
        }

        if (-not $Destination) {
            throw 'The destination path was not added to the PSModulePath environment variable, ensure you have the rights to modify environment variables'
        }

        $Destination = ConvertTo-CanonicalPath -Path $Destination

        Write-Debug "Execute installation for '$($PSCmdlet.ParameterSetName)' type."

        switch($PSCmdlet.ParameterSetName) {
            CentralDirectory {
                Install-ModuleFromDirectory -Module:$Module -Destination:$Destination -ModuleHash:$ModuleHash -Global:$Global -PersistEnvironment:$PersistEnvironment -DoNotImport:$DoNotImport -AddToProfile:$AddToProfile -Update:$Update -DirectoryUrl:$DirectoryUrl -InstallWithModuleName:$InstallWithModuleName -DoNotPostInstall:$DoNotPostInstall -PostInstallHook:$PostInstallHook
            }
            Web {
                Install-ModuleFromWeb -ModuleUrl:$ModuleUrl -ModuleName:$ModuleName -Type:$Type -Destination:$Destination -ModuleHash:$ModuleHash -Global:$Global -PersistEnvironment:$PersistEnvironment -DoNotImport:$DoNotImport -AddToProfile:$AddToProfile -Update:$Update -InstallWithModuleName:$InstallWithModuleName -DoNotPostInstall:$DoNotPostInstall -PostInstallHook:$PostInstallHook
            }
            Local {
                Install-ModuleFromLocal -ModulePath:$ModulePath -ModuleName:$ModuleName -Type:$Type -Destination:$Destination -ModuleHash:$ModuleHash -Global:$Global -PersistEnvironment:$PersistEnvironment -DoNotImport:$DoNotImport -AddToProfile:$AddToProfile -Update:$Update -InstallWithModuleName:$InstallWithModuleName -DoNotPostInstall:$DoNotPostInstall -PostInstallHook:$PostInstallHook
            }
            NuGet {
                Install-ModuleFromNuGet -NuGetPackageId:$NuGetPackageId -PackageVersion:$PackageVersion -NugetSource:$NugetSource -PreRelease:$PreRelease -PreReleaseTag:$PreReleaseTag -Destination:$Destination -ModuleHash:$ModuleHash -Global:$Global -PersistEnvironment:$PersistEnvironment -DoNotImport:$DoNotImport -AddToProfile:$AddToProfile -Update:$Update -InstallWithModuleName:$InstallWithModuleName -DoNotPostInstall:$DoNotPostInstall -PostInstallHook:$PostInstallHook
            }
            default {
                throw "Unknown ParameterSetName '$($PSCmdlet.ParameterSetName)'"
            }
        }
    }
}

<#
    .SYNOPSIS
        Updates a module.

    .DESCRIPTION
        Supports updating modules for the current user or all users (if elevated).

    .PARAMETER Module
        Name of the module to update.

    .PARAMETER All
        If -All is defined. all to PsGet known modules will be updated.

    .PARAMETER Destination
        When specified the module will be updated below this path.

    .PARAMETER ModuleHash
        When ModuleHash is specified the chosen module will only be installed if its contents match the provided hash.

    .PARAMETER Global
        If set, attempts to install the module to the all users location in Windows\System32...

    .PARAMETER DoNotImport
        Indicates that command should not import module after installation.

    .PARAMETER AddToProfile
        Adds installed module to the profile.ps1.

    .PARAMETER Update
        Forces module to be updated.

    .PARAMETER DirectoryUrl
        URL to central directory. By default it uses the value in the $PsGetDirectoryUrl global variable.

    .PARAMETER DoNotPostInstall
        If defined, the PostInstallHook is not executed.

    .PARAMERTER PostInstallHook
        Defines the name of a script inside the installed module folder which should be executed after installation.
        Will not be check in combination with -All switch.
        Default: 'Install.ps1'

    .LINK
        http://psget.net

    .LINK
        Install-Module

    .EXAMPLE
        # Update-Module PsUrl

        Description
        -----------
        Updates the module
#>
function Update-Module {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        [String] $Module,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $All,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $Destination = $global:PsGetDestinationModulePath,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $ModuleHash,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Global,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotImport,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $AddToProfile,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $DirectoryUrl = $global:PsGetDirectoryUrl,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotPostInstall,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $PostInstallHook
    )
    process {
        if ($All) {
            Install-Module -Module PSGet -Force -DoNotImport

            Get-PsGetModuleInfo -ModuleName '*' | Where-Object {
                    if ($_.Id -ne 'PSGet') {
                        Get-Module -Name:($_.ModuleName) -ListAvailable
                    }
                } | Install-Module -Update

            Import-Module -Name PSGet -Force -DoNotPostInstall:$DoNotPostInstall

        }
        else {
            Install-Module -Module:$Module -Destination:$Destination -ModuleHash:$ModuleHash -Global:$Global -DoNotImport:$DoNotImport -AddToProfile:$AddToProfile -DirectoryUrl:$DirectoryUrl -Updat -DoNotPostInstall:$DoNotPostInstall -PostInstallHook:$PostInstallHook
        }
    }
}

<#
    .SYNOPSIS
        Retrieve information about module from central directory

    .DESCRIPTION
        Command will query central directory to get information about module specified.

    .PARAMETER ModuleName
        Name of module to look for in directory. Supports wildcards.

    .PARAMETER DirectoryUrl
        URL to central directory. By default it uses the value in the $PsGetDirectoryUrl global variable.

    .LINK
        http://psget.net

    .EXAMPLE
        Get-PsGetModuleInfo PoshCo*

        Description
        -----------
        Retrieves information about all registerd modules that starts with PoshCo.
#>
function Get-PsGetModuleInfo {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        [String] $ModuleName,
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $DirectoryUrl = $global:PsGetDirectoryUrl
    )
    begin {
        $client = (new-object Net.WebClient)
        $client.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

        $PsGetDataPath = Join-Path -Path $Env:APPDATA -ChildPath psget
        $DirectoryCachePath = Join-Path -Path $PsGetDataPath -ChildPath directorycache.clixml
        $DirectoryCache = @()
        $CacheEntry = $null
        if (Test-Path -Path $DirectoryCachePath) {
            $DirectoryCache = Import-Clixml -Path $DirectoryCachePath
            $CacheEntry = $DirectoryCache | Where-Object { $_.Url -eq $DirectoryUrl } | Select-Object -First 1
        }
        if (-not $CacheEntry) {
            $CacheEntry = @{
                Url = $DirectoryUrl
                File = '{0}.xml' -f [Guid]::NewGuid().Tostring()
                ETag = $null
            }
            $DirectoryCache += @($CacheEntry)
        }
        $CacheEntryFilePath = Join-Path -Path $PsGetDataPath -ChildPath $CacheEntry.File
        if ($CacheEntry -and $CacheEntry.ETag -and (Test-Path -Path $CacheEntryFilePath)) {
            if ((Get-Item -Path $CacheEntryFilePath).LastWriteTime.AddDays(1) -gt (Get-Date)) {
                # use cached directory if it is less than 24 hours old
                $client.Headers.Add('If-None-Match', $CacheEntry.ETag)
            }
        }

        try {
            Write-Verbose "Downloading modules repository from $DirectoryUrl"
            $repoRaw = $client.DownloadString($DirectoryUrl)
            $StatusCode = 200
        }
        catch [System.Net.WebException] {
            $Response = $_.Exception.Response
            if ($Response) { $StatusCode = [int]$Response.StatusCode }
        }

        if ($StatusCode -eq 200) {
            $repoXml = [xml]$repoRaw

            $CacheEntry.ETag = $client.ResponseHeaders['ETag']
            if (-not (Test-Path -Path $PsGetDataPath)) {
                New-Item -Path $PsGetDataPath -ItemType Container | Out-Null
            }
            $repoXml.Save($CacheEntryFilePath)
            Export-Clixml -InputObject $DirectoryCache -Path $DirectoryCachePath
        }
        elseif (Test-Path -Path $CacheEntryFilePath) {
            if ($StatusCode -ne 304) {
                Write-Warning "Could not retrieve modules repository from '$DirectoryUrl'. Status code: $StatusCode"
            }
            Write-Verbose 'Using cached copy of modules repository'
            $repoXml = [xml](Get-Content -Path $CacheEntryFilePath)
        }
        else {
            throw "Could not retrieve modules repository from '$DirectoryUrl'. Status code: $StatusCode"
        }

        $nss = @{ a = 'http://www.w3.org/2005/Atom';
                  pg = 'urn:psget:v1.0' }

        $feed = $repoXml.feed
        $title = $feed.title.innertext
        Write-Verbose "Processing $title feed..."
    }
    process {
        # Very naive, ignoring namespaces and so on.
        $feed.entry | Where-Object { $_.id -like $ModuleName } |
            ForEach-Object {
                $Type = ''
                switch -regex ($_.content.type) {
                    'application/zip' { $Type = $PSGET_ZIP  }
                    default { $Type = $PSGET_PSM1  }
                }

                $Verb = if ($_.properties.Verb -imatch 'POST') { 'POST' } else { 'GET' }

                New-Object PSObject -Property @{
                    Title = $_.title.innertext
                    Description = $_.summary.'#text'
                    Updated = [DateTime]$_.updated
                    Author= $_.author.name
                    Id = $_.id
                    ModuleName = if ($_.properties.ModuleName) { $_.properties.ModuleName } else { $_.id }
                    Type = $Type
                    DownloadUrl = $_.content.src
                    Verb = $Verb
                    #This was changed from using the  $_.properties.ProjectUrl because the value for ModuleUrl needs to be the full path to the module file
                    #This change was required to get the tests to pass
                    ModuleUrl = $_.content.src
                    NoPostInstallHook = if ($_.properties.NoPostInstallHook -eq 'true') { $true } else { $false }
                    PostInstallHook = $_.properties.PostInstallHook
                    PostUpdateHook = $_.properties.PostUpdateHook
                } |
                    Select-Object Title, ModuleName, Id, Description, Updated, Type, Verb, ModuleUrl, DownloadUrl, NoPostInstallHook, PostInstallHook, PostUpdateHook
            }
    }
}

<#
    .SYNOPSIS
        Calculate the hash value of a module.

    .DESCRIPTION
        Calculate the hash value of the specified module directory for usage with the 'ModuleHash' parameter for validation.

    .PARAMETER Path
        Path to the module directory

    .EXAMPLE
        Get-PsGetModuleHash $global:UserModuleBasePath\PsGet

        Description
        -----------
        Returns the hash value usable with the 'ModuleHash' parameter of 'Install-Module'

    .LINK
        Install-Module

    .LINK
        http://psget.net
#>
function Get-PsGetModuleHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Alias('ModuleBase')]
        [String] $Path
    )
    process {
        Get-FolderHash -Path (Resolve-Path -Path $Path).Path
    }
}

#endregion

#region Sub-Cmdlets

<#
    .SYNOPSIS
        Install a module from the defined PsGet directory.

    .PARAMETER Module
        Name of the module to install from PsGet directory.

    .PARAMETER Destination
        When specified the module will be installed below this path. Defaults to '$global:PsGetDestinationModulePath' if defined.

    .PARAMETER ModuleHash
        When ModuleHash is specified the chosen module will only be installed if its contents match the provided hash.

    .PARAMETER Global
        If set, attempts to install the module to the all users location in C:\Program Files\Common Files\Modules...

        NOTE: If the -Destination directory is specified, then -Global will only have an effect in combination with '-PersistEnvironment'. This is also the case if '$global:PsGetDestinationModulePath' is defined.

    .PARAMETER DoNotImport
        Indicates that command should not import module after installation

    .PARAMETER AddToProfile
        Adds Import-Module statement for installed module to the profile.ps1

    .PARAMETER Update
        Forces module to be updated

    .PARAMETER DirectoryUrl
        URL to central directory. By default it uses the value in the $global:PsGetDirectoryUrl variable

    .PARAMETER PersistEnvironment
        If this switch is specified, the installation destination path will be added to either the User's PSModulePath environment variable or Machine's PSModulePath environment variable (if -Global specified)

    .PARAMETER InstallWithModuleName
        Allows to specify the name of the module and override the ModuleName normally used.
        NOTE: This parameter allows to install a module from the PsGet-Directory more than once and PsGet does not remember that this module is installed with a different name.

    .PARAMETER DoNotPostInstall
        If defined, the PostInstallHook is not executed.

    .PARAMERTER PostInstallHook
        Defines the name of a script inside the installed module folder which should be executed after installation.
        Default: definition in directory file or 'Install.ps1'
#>
function Install-ModuleFromDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        [String] $Module,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $Destination = $global:PsGetDestinationModulePath,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $ModuleHash,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Global,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotImport,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $AddToProfile,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Update,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $DirectoryUrl = $global:PsGetDirectoryUrl,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $PersistEnvironment,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $InstallWithModuleName,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotPostInstall,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $PostInstallHook
    )
    process {
        $testModuleName = if ($InstallWithModuleName) { $InstallWithModuleName } else { $Module }
        if (Test-ModuleInstalledAndImport -ModuleName:$testModuleName -Destination:$Destination -Update:$Update -DoNotImport:$DoNotImport -ModuleHash:$ModuleHash) {
            return
        }

        Write-Verbose "Module $Module will be installed from central repository"
        $moduleData = Get-PsGetModuleInfo -ModuleName:$Module -DirectoryUrl:$DirectoryUrl | select -First 1
        if (-not $moduleData) {
            throw "Module $Module was not found in central repository"
        }

        # $Module and $moduleData.Id are not equally by garantee, so we have to test again.
        if (Test-ModuleInstalledAndImport -ModuleName:$moduleData.ModuleName -Destination:$Destination -Update:$Update -DoNotImport:$DoNotImport -ModuleHash:$ModuleHash) {
            return
        }

        if (-not $DoNotPostInstall) {
            $DoNotPostInstall = $moduledata.NoPostInstallHook
        }

        if (-not $PostInstallHook) {
            if ($Update) {
                $PostInstallHook = $moduleData.PostUpdateHook
            }
            else {
                $PostInstallHook = $moduleData.PostInstallHook
            }

            if (-not $PostInstallHook) {
                $PostInstallHook = 'Install.ps1'
            }
        }

        $result = Invoke-DownloadModuleFromWeb -DownloadUrl:$moduleData.DownloadUrl -ModuleName:$moduleData.ModuleName -Type:$moduleData.Type -Verb:$moduleData.Verb
        Install-ModuleToDestination -ModuleName:$result.ModuleName -InstallWithModuleName:$InstallWithModuleName -ModuleFolderPath:$result.ModuleFolderPath -TempFolderPath:$result.TempFolderPath -Destination:$Destination -ModuleHash:$ModuleHash -Global:$Global -PersistEnvironment:$PersistEnvironment -DoNotImport:$DoNotImport -AddToProfile:$AddToProfile -Update:$Update -DoNotPostInstall:$DoNotPostInstall -PostInstallHook:$PostInstallHook
    }
}

<#
    .SYNOPSIS
        Install a module from a provided download location.

    .PARAMETER ModuleUrl
        URL to the module to install; Can be direct link to PSM1 file or ZIP file. Can be a shortened link.

    .PARAMETER ModuleName
        It is not always possible to interfere the right ModuleName, eg. the filename is unknown or the zip archive contains multiple modules.

    .PARAMETER Type
        When ModuleUrl or ModulePath specified, allows specifying type of the package. Can be ZIP or PSM1.

    .PARAMETER Destination
        When specified the module will be installed below this path. Defaults to '$global:PsGetDestinationModulePath' if defined.

    .PARAMETER ModuleHash
        When ModuleHash is specified the chosen module will only be installed if its contents match the provided hash.

    .PARAMETER Global
        If set, attempts to install the module to the all users location in C:\Program Files\Common Files\Modules...

        NOTE: If the -Destination directory is specified, then -Global will only have an effect in combination with '-PersistEnvironment'. This is also the case if '$global:PsGetDestinationModulePath' is defined.

    .PARAMETER DoNotImport
        Indicates that command should not import module after installation

    .PARAMETER AddToProfile
        Adds Import-Module statement for installed module to the profile.ps1

    .PARAMETER Update
        Forces module to be updated

    .PARAMETER PersistEnvironment
        If this switch is specified, the installation destination path will be added to either the User's PSModulePath environment variable or Machine's PSModulePath environment variable (if -Global specified)

    .PARAMETER InstallWithModuleName
        Allows to specify the name of the module and override the ModuleName normally used.
        NOTE: This parameter allows to install a module from the PsGet-Directory more than once and PsGet does not remember that this module is installed with a different name.

    .PARAMETER DoNotPostInstall
        If defined, the PostInstallHook is not executed.

    .PARAMERTER PostInstallHook
        Defines the name of a script inside the installed module folder which should be executed after installation.
        Default: 'Install.ps1'
#>
function Install-ModuleFromWeb {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        [String] $ModuleUrl,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $ModuleName,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('ZIP', 'PSM1', 'PSD1', '')] # $script:PSGET_ZIP, $script:PSGET_PSM1 or $script:PSGET_PSD1
        [String] $Type,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $Destination = $global:PsGetDestinationModulePath,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $ModuleHash,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Global,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotImport,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $AddToProfile,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Update,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $PersistEnvironment,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $InstallWithModuleName,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotPostInstall,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $PostInstallHook
    )
    process {
        Write-Verbose "Module will be installed from $ModuleUrl"

        if ($InstallWithModuleName) {
            if (Test-ModuleInstalledAndImport -ModuleName:$InstallWithModuleName -Destination:$Destination -Update:$Update -DoNotImport:$DoNotImport -ModuleHash:$ModuleHash) {
                return
            }
        }

        $result = Invoke-DownloadModuleFromWeb -DownloadUrl:$ModuleUrl -ModuleName:$ModuleName -Type:$Type -Verb:'GET'

        if (-not $PostInstallHook) {
            $PostInstallHook = 'Install.ps1'
        }

        Install-ModuleToDestination -ModuleName:$result.ModuleName -InstallWithModuleName:$InstallWithModuleName -ModuleFolderPath:$result.ModuleFolderPath -TempFolderPath:$result.TempFolderPath -Destination:$Destination -ModuleHash:$ModuleHash -Global:$Global -PersistEnvironment:$PersistEnvironment -DoNotImport:$DoNotImport -AddToProfile:$AddToProfile -Update:$Update -DoNotPostInstall:$DoNotPostInstall -PostInstallHook:$PostInstallHook
    }
}

<#
    .SYNOPSIS
        Install a module from a provided local path.

    .PARAMETER ModulePath
        Local path to the module to install.

    .PARAMETER ModuleName
        It is not always possible to interfere the right ModuleName, eg. the filename is unknown or the zip archive contains multiple modules.

    .PARAMETER Type
        When ModuleUrl or ModulePath specified, allows specifying type of the package. Can be ZIP or PSM1.

    .PARAMETER Destination
        When specified the module will be installed below this path. Defaults to '$global:PsGetDestinationModulePath' if defined.

    .PARAMETER ModuleHash
        When ModuleHash is specified the chosen module will only be installed if its contents match the provided hash.

    .PARAMETER Global
        If set, attempts to install the module to the all users location in C:\Program Files\Common Files\Modules...

        NOTE: If the -Destination directory is specified, then -Global will only have an effect in combination with '-PersistEnvironment'. This is also the case if '$global:PsGetDestinationModulePath' is defined.

    .PARAMETER DoNotImport
        Indicates that command should not import module after installation

    .PARAMETER AddToProfile
        Adds Import-Module statement for installed module to the profile.ps1

    .PARAMETER Update
        Forces module to be updated

    .PARAMETER PersistEnvironment
        If this switch is specified, the installation destination path will be added to either the User's PSModulePath environment variable or Machine's PSModulePath environment variable (if -Global specified)

    .PARAMETER InstallWithModuleName
        Allows to specify the name of the module and override the ModuleName normally used.
        NOTE: This parameter allows to install a module from the PsGet-Directory more than once and PsGet does not remember that this module is installed with a different name.

    .PARAMETER DoNotPostInstall
        If defined, the PostInstallHook is not executed.

    .PARAMERTER PostInstallHook
        Defines the name of a script inside the installed module folder which should be executed after installation.
        Default: 'Install.ps1'
#>
function Install-ModuleFromLocal {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        [String] $ModulePath,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $ModuleName,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('ZIP', 'PSM1', 'PSD1', '')] # $script:PSGET_ZIP, $script:PSGET_PSM1 or $script:PSGET_PSD1
        [String] $Type,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $Destination = $global:PsGetDestinationModulePath,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $ModuleHash,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Global,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotImport,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $AddToProfile,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Update,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $PersistEnvironment,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $InstallWithModuleName,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotPostInstall,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $PostInstallHook
    )
    process {
        Write-Verbose 'Module will be installed from local path'

        $InstallWithModuleName = if ($InstallWithModuleName) { $InstallWithModuleName } else { $ModuleName }
        if ($InstallWithModuleName) {
            if (Test-ModuleInstalledAndImport -ModuleName:$InstallWithModuleName -Destination:$Destination -Update:$Update -DoNotImport:$DoNotImport -ModuleHash:$ModuleHash) {
                return
            }
        }

        $tempFolderPath = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
        New-Item $tempFolderPath -ItemType Directory | Out-Null
        Write-Debug "Temporary work directory created: $tempFolderPath"

        trap { Remove-Item -Path $tempFolderPath -Recurse -Force ; break }

        $newModulePath = Join-Path -Path $tempFolderPath -ChildPath 'module'
        New-Item $newModulePath -ItemType Directory | Out-Null

        if (Test-Path -Path $ModulePath -PathType Leaf) {
            $extension = (Get-Item $ModulePath).Extension
            if ($extension -eq '.psm1') {
                $Type = if ($Type) { $Type } else { $PSGET_PSM1 }
            } elseif ($extension -eq '.zip') {
                $Type = if ($Type) { $Type } else { $PSGET_ZIP }
            }

            if ($Type -eq $PSGET_ZIP) {
                Expand-ZipModule $ModulePath $newModulePath
            }
            else {
                Copy-Item -Path $ModulePath -Destination $newModulePath
            }
        }
        elseif (Test-Path -Path $ModulePath -PathType Container) {
            Copy-Item -Path $ModulePath -Destination $newModulePath -Force -Recurse
        }
        else {
            throw "ModulePath '$ModulePath' does not point to an module."
        }

        $foundResult = Find-ModuleNameAndFolder -Path $newModulePath -ModuleName $ModuleName

        if (-not $PostInstallHook) {
            $PostInstallHook = 'Install.ps1'
        }

        Install-ModuleToDestination -ModuleName:$foundResult.ModuleName -InstallWithModuleName:$InstallWithModuleName -ModuleFolderPath:$foundResult.ModuleFolderPath -TempFolderPath:$tempFolderPath -Destination:$Destination -ModuleHash:$ModuleHash -Global:$Global -PersistEnvironment:$PersistEnvironment -DoNotImport:$DoNotImport -AddToProfile:$AddToProfile -Update:$Update -DoNotPostInstall:$DoNotPostInstall -PostInstallHook:$PostInstallHook
    }
}

<#
    .SYNOPSIS
        Install a module from a NuGet source.

    .PARAMETER NuGetPackageId
        NuGet package name containing the module to install.

    .PARAMETER PackageVersion
        Allows a specific version of the specified NuGet package to used, if not specified then the latest stable version will be used.

    .PARAMETER NugetSource
        URL to the NuGet feed containing the package.

    .PARAMETER PreRelease
        If PackageVersion is not specified, then this switch allows the latest prerelease package to be used.

    .PARAMETER PreReleaseTag
        If PackageVersion is not specified, then this parameter allows the latest version of a particular prerelease tag to be used

    .PARAMETER Destination
        When specified the module will be installed below this path. Defaults to '$global:PsGetDestinationModulePath' if defined.

    .PARAMETER ModuleHash
        When ModuleHash is specified the chosen module will only be installed if its contents match the provided hash.

    .PARAMETER Global
        If set, attempts to install the module to the all users location in C:\Program Files\Common Files\Modules...

        NOTE: If the -Destination directory is specified, then -Global will only have an effect in combination with '-PersistEnvironment'. This is also the case if '$global:PsGetDestinationModulePath' is defined.

    .PARAMETER DoNotImport
        Indicates that command should not import module after installation

    .PARAMETER AddToProfile
        Adds Import-Module statement for installed module to the profile.ps1

    .PARAMETER Update
        Forces module to be updated

    .PARAMETER PersistEnvironment
        If this switch is specified, the installation destination path will be added to either the User's PSModulePath environment variable or Machine's PSModulePath environment variable (if -Global specified)

    .PARAMETER InstallWithModuleName
        Allows to specify the name of the module and override the ModuleName normally used.
        NOTE: This parameter allows to install a module from the PsGet-Directory more than once and PsGet does not remember that this module is installed with a different name.

    .PARAMETER DoNotPostInstall
        If defined, the PostInstallHook is not executed.

    .PARAMERTER PostInstallHook
        Defines the name of a script inside the installed module folder which should be executed after installation.
        Default: 'Install.ps1'
#>
function Install-ModuleFromNuGet {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$true)]
        [ValidatePattern('^\w+([_.-]\w+)*$')] # regex from NuGet.PackageIdValidator._idRegex
        [ValidateLength(1,100)] # maximum length from NuGet.PackageIdValidator.MaxPackageIdLength
        [String] $NuGetPackageId,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $PackageVersion,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $NugetSource = 'https://nuget.org/api/v2/',

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $PreRelease,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $PreReleaseTag,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $Destination = $global:PsGetDestinationModulePath,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $ModuleHash,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Global,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotImport,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $AddToProfile,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $Update,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $PersistEnvironment,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $InstallWithModuleName,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Switch] $DoNotPostInstall,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [String] $PostInstallHook
    )
    process {
        Write-Verbose 'Module will be installed from NuGet'
        $InstallWithModuleName = if ($InstallWithModuleName) { $InstallWithModuleName } else { $NuGetPackageId }

        if (Test-ModuleInstalledAndImport -ModuleName:$InstallWithModuleName -Destination:$Destination -Update:$Update -DoNotImport:$DoNotImport -ModuleHash:$ModuleHash) {
            return
        }

        if (-not $PostInstallHook) {
            $PostInstallHook = 'Install.ps1'
        }

        try {
            $result = Invoke-DownloadNugetPackage -NuGetPackageId $NuGetPackageId -PackageVersion $PackageVersion -Source $NugetSource -PreRelease:$PreRelease -PreReleaseTag $PreReleaseTag
            Install-ModuleToDestination -ModuleName:$result.ModuleName -InstallWithModuleName:$InstallWithModuleName -ModuleFolderPath:$result.ModuleFolderPath -TempFolderPath:$result.TempFolderPath -Destination:$Destination -ModuleHash:$ModuleHash -Global:$Global -PersistEnvironment:$PersistEnvironment -DoNotImport:$DoNotImport -AddToProfile:$AddToProfile -Update:$Update -DoNotPostInstall:$DoNotPostInstall -PostInstallHook:$PostInstallHook
        }
        catch {
            Write-Error $_.Exception.Message
            return
        }
    }
}

#endregion

#region Internal Cmdlets
#region Module Installation
<#
    .SYNOPSIS
        Adds value to a "Path" type of environment variable (PATH or PSModulePath).  Path type of variables munge the User and Machine values into the value for the current session.

    .PARAMETER Global
        The System.EnvironmentVariableTarget of what type of environment variable to modify ("Machine","User" or "Session")

    .PARAMETER PathToAdd
        The actual path to add to the environment variable

    .PARAMETER PersistEnvironment
        If specified, will permanently store the variable in registry

    .EXAMPLE
        AddPathToPSModulePath -Scope "Machine" -PathToAdd "$env:CommonProgramFiles\Modules"

        Description
        -----------
        This command add the path "$env:CommonProgramFiles\Modules" to the Machine PSModulePath environment variable
#>
function Add-PathToPSModulePath {
    [CmdletBinding()]
    param (

	    [Parameter(Mandatory=$true)]
	    [string] $PathToAdd,

        [switch] $PersistEnvironment,

        [switch] $Global
    )
    process {
        $PathToAdd = ConvertTo-CanonicalPath -Path $PathToAdd

        if(-not $PersistEnvironment) {
            if (-not ($env:PSModulePath.Contains($PathToAdd))) {
                Write-Warning "Module install destination `"$PathToAdd`" is not included in the PSModulePath environment variable."
            }
            return
        }

        $scope = 'User'
        if ($Global) {
            Write-Verbose 'The Machine environment variable PSModulePath will be modified.'
            $scope = 'Machine'
        }

        $pathValue = '' + [Environment]::GetEnvironmentVariable('PSModulePath', $scope)

        if (-not ($pathValue.Contains($PathToAdd))) {
            if ($pathValue -eq '') {
                Write-Debug "PSModulePath for scope '$scope' was read empty. Setting PowerShell default instead."
                if ($scope -eq 'User') {
                    $pathValue = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'WindowsPowerShell\Modules'
                }
                else {
                    $pathValue = Join-Path -Path $PSHOME -ChildPath 'Modules'
                }
            }

            if (-not ($pathValue.Contains($PathToAdd))) {
                $pathValue = "$pathValue;$PathToAdd"
            }

            [Environment]::SetEnvironmentVariable('PSModulePath', $pathValue, $scope)

            Update-PSModulePath

            Write-Host """$PathToAdd"" is added to the PSModulePath environment variable"
        }
        else {
            Write-Verbose """$PathToAdd"" already exists in PSModulePath environment variable"
        }
    }
}

<#
    .SYNOPSIS
        Standardize the provided path.

    .DESCRIPTION
        A simple routine to standardize path formats.

    .PARAMETER Path
#>
function ConvertTo-CanonicalPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $Path
    )
    process {
        return [IO.Path]::GetFullPath(($Path.Trim()))
    }
}

<#
    .SYNOPSIS
        Find the module file in the given path.

    .PARAMETER Path
        Path of module

    .PARAMETER ModuleName
        Name of the Module
#>
function Get-ModuleFile {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [String] $Path,

        [String] $ModuleName = '*'
    )
    process {
        $Includes = Get-PossibleModuleFileNames -ModuleName $ModuleName

        # Sort by folder length ensures that we use one from root folder(Issue #12)
        $DirectoryNameLengthProperty = @{
            E = { $_.DirectoryName.Length }
        }

        # sort by Includes to give PSD1 preference over PSM1, etc
        $IncludesPreferenceProperty = @{
            E = {
                for ($Index = 0; $Index -lt $Includes.Length; $Index++) {
                    if ($_.Name -like $Includes[$Index]) { break }
                }
                $Index
            }
        }

        Get-ChildItem -Path $Path -Include $Includes -Recurse |
            Where-Object { -not $_.PSIsContainer } |
            Sort-Object -Property $DirectoryNameLengthProperty, $IncludesPreferenceProperty |
            Select-Object -ExpandProperty FullName -First 1
    }
}

<#
    .SYNOPSIS
        Get list of possible names for the module file.

    .PARAMETER ModuleName
        Name of the module
#>
function Get-PossibleModuleFileNames {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [String] $ModuleName
    )
    process {
        'psd1','psm1','ps1','dll','cdxml','xaml' | ForEach-Object { "$ModuleName`.$_" }
    }
}

<#
    .SYNOPSIS
        Search in the provided folder for a module, if possible with the provided name.

    .PARAMETER Path
        Path to search in for the module.

    .PARAMETER ModuleName
        ModuleName which is expected.
#>
function Find-ModuleNameAndFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String] $Path,

        [String] $ModuleName
    )
    process {
        if ($ModuleName) {
            $moduleFile = Get-ModuleFile -Path $Path -ModuleName $ModuleName
            if (-not $moduleFile) {
                throw "Could not find a module with name '$ModuleName' in the provided file."
            }
        }
        else {
            $moduleFile = Get-ModuleFile -Path $Path
            if (-not $moduleFile) {
                throw 'Could not find any module in the provided file.'
            }
            $ModuleName = [IO.Path]::GetFileNameWithoutExtension($moduleFile)
        }

        $moduleFolderPath = Split-Path -Path $moduleFile

        return @{
            ModuleName = $ModuleName
            ModuleFolderPath = $moduleFolderPath
        }
    }
}

<#
    .SYNOPSIS
        Import given modele

    .DESCRIPTION
        Import given module with switch -Global (functions available to other modules) and avoid
        a Powershell bug related to binary modules.

    .$
#>
function Import-ModuleGlobally {
    [CmdletBinding()]
    param (
        [String] $ModuleName,
        [String] $ModuleBase,
        [Switch] $Force
    )
    process {
        Write-Verbose "Importing installed module '$ModuleName' from '$($installedModule.ModuleBase)'"
        Import-Module -Name $ModuleBase -Global -Force:$Force

        $IdentityExtension = [System.IO.Path]::GetExtension((Get-ModuleFile -Path $ModuleBase -ModuleName $ModuleName))
        if ($IdentityExtension -eq '.dll') {
            # import module twice for binary modules to workaround PowerShell bug:
            # https://connect.microsoft.com/PowerShell/feedback/details/733869/import-module-global-does-not-work-for-a-binary-module
            Import-Module -Name $ModuleBase -Global -Force:$Force
        }
    }
}

<#
    .SYNOPSIS
        Download module from URL

    .DESCRIPTION
        Download module from URL and try to interfere unknown parameter.
        If download target is a zip-archive it will be extracted.

        Returns a map containing the TempFolderPath, ModuleFolderPath and ModuleName.
        The TempFolderPath should be removed after processing the result.

    .PARAMETER DownloadUrl
        URL to the module delivery file.

    .PARAMETER ModuleName
        Name of the module.

    .PARAMETER Type
        Type of the module delivery file.

    .PARAMETER Verb
        Http method used for download.
#>
function Invoke-DownloadModuleFromWeb {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String] $DownloadUrl,

        [String] $ModuleName,

        [String] $Type,

        [String] $Verb
    )

    $tempFolderPath = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath ([Guid]::NewGuid().ToString())
    New-Item -Path $tempFolderPath -ItemType Directory | Out-Null
    Write-Debug "Temporary work directory created: $tempFolderPath"

    # make certain that the tempFolder will be deleted if there is an error
    trap { Remove-Item -Path $tempFolderPath -Recurse -Force; break }

    Write-Verbose "Downloading module from $DownloadUrl"
    $client = (new-object Net.WebClient)
    $client.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
    $downloadFilePath = Join-Path -Path $tempfolderPath -ChildPath 'download'
    if ($Verb -eq 'POST') {
        $client.Headers['Content-type'] = 'application/x-www-form-urlencoded'
        [IO.File]::WriteAllBytes($downloadFilePath, $client.UploadData($DownloadUrl, ''))
    }
    else {
        $client.DownloadFile($DownloadUrl, $downloadFilePath)
    }

    $candidateName = '{undefined}'
    $contentDisposition = $client.ResponseHeaders['Content-Disposition']
    Write-Debug "Try to get module file name from content disposition header: Content-Disposition = '$contentDisposition'"

    if ($contentDisposition -match '\bfilename="?(?<name>[^/]+)\.(?<ext>psm1|zip)"?') {
        $candidateName = $Matches.name
        $Type = if ($Type) { $Type } elseif ($Matches.ext -eq 'psm1') { $PSGET_PSM1 } elseif ($Matches.ext -eq 'zip') { $PSGET_ZIP }
    }
    else {
        Write-Debug "Try to get module file name from url: '$DownloadUrl'"
        if ($DownloadUrl -match '\b(?<name>[^/]+)\.(?<ext>psm1|zip)[\#\?]*') {
            $candidateName = $Matches.name
            $Type = if ($Type) { $Type } elseif ($Matches.ext -eq 'psm1') { $PSGET_PSM1 } elseif ($Matches.ext -eq 'zip') { $PSGET_ZIP }
        }
        else {
            $locationHeader = $client.ResponseHeaders['Location']
            Write-Debug "Check location header in case of redirect: '$locationHeader'"
            if ($locationHeader -match '\b(?<name>[^/]+)\.(?<ext>psm1|zip)[\#\?]*') {
                $candidateName = $Matches.name
                $Type = if ($Type) { $Type } elseif ($Matches.ext -eq 'psm1') { $PSGET_PSM1 } elseif ($Matches.ext -eq 'zip') { $PSGET_ZIP }
            }
        }
    }

    Write-Debug "Invoke-DownloadModuleFromWeb: CandidateName = '$candidateName'"

    if (-not $Type) {
        $contentType = $client.ResponseHeaders['Content-Type']
        Write-Debug "Download header Content-Type: '$contentType'"
        if ($contentType -eq 'application/zip') {
            $type = $PSGET_ZIP
        }
        # check downloaded file for the PKZip header
        elseif ((Get-Item -Path $downloadFilePath).Length -gt 4) {
            Write-Debug 'Search for PKZipHeader'
            $knownPKZipHeader = 0x50, 0x4b, 0x03, 0x04
            $fileHeader = Get-Content -Path $downloadFilePath -Encoding Byte -TotalCount 4
            if ([System.BitConverter]::ToString($knownPKZipHeader) -eq [System.BitConverter]::ToString($fileHeader)) {
                Write-Debug 'Found PKZipHeader => Type = ZIP'
                $type = $PSGET_ZIP
            }
            else {
                Write-Debug 'No PKZipHeader found => Type -ne ZIP'
            }
        }

        if (-not $Type) {
            Write-Debug 'If its most likely no zip it has to be an PSM1 file.'
            $Type = $PSGET_PSM1
        }
    }

    $moduleFolderPath = Join-Path -Path $tempFolderPath -ChildPath 'module'
    New-Item -Path $moduleFolderPath -ItemType Directory | Out-Null

    switch ($Type) {
        $PSGET_ZIP {
            $zipFilePath = $downloadFilePath + '.zip'
            Move-Item -Path $downloadFilePath -Destination $zipFilePath
            Expand-ZipModule -Path $zipFilePath -Destination $moduleFolderPath
        }
        $PSGET_PSM1 {
            if (-not $ModuleName) {
                if ($candidateName -eq '{undefined}') {
                    throw 'Cannot guess module name. Try specifying ModuleName argument!'
                }
                $ModuleName = $candidateName
            }

            $psmFilePath = Join-Path -Path $moduleFolderPath -ChildPath "$ModuleName.psm1"
            Move-Item -Path $downloadFilePath -Destination $psmFilePath
        }
        default {
            throw "Type $Type is not supported yet"
        }
    }

    $foundResult = Find-ModuleNameAndFolder -Path $moduleFolderPath -ModuleName $ModuleName

    Write-Debug "Invoke-DownloadModuleFromWeb: ModuleName = '$ModuleName'"

    return @{
        TempFolderPath = $tempFolderPath
        ModuleFolderPath = $foundResult.ModuleFolderPath
        ModuleName = $foundResult.ModuleName
    }
}

<#
    .SYNOPSIS
        Install the provided module into the defined destination.

    .DESCRIPTION
        Install the module inside of the provided directory into the defined destination
        and perform the following steps:

        * Rename module if requestes by provided InstallWithModuleName
        * If a ModuleHash is provided, check if it matches.
        * Add the destination path to the PSModulePath if necessary (depends on provided parameters)
        * Place the conventions-matching module folder in the destination folder
        * Import the module if necessary
        * Add the profile import to profile if necessary

    .PARAMETER ModuleName
        The name of the module.

    .PARAMETER InstallWithModuleName
        The name the module should get.

    .PARAMETER ModuleFolderPath
        The path to the module data, which contains the module main file, named according to ModuleName

    .PARAMETER TempFolderPath
        TempPath used by PsGet for doing the work. Contains the ModuleFolderPath and will be deleted after processing,

    .PARAMETER Destination
        Path to which the module will be installed.

    .PARAMETER ModuleHash
        When ModuleHash is specified the chosen module will only be installed if its contents match the provided hash.

    .PARAMETER Global
        Influence the PSModulePath changes and profile changes.

    .PARAMETER PersistEnvironment
        Defines if the PSModulePath changes should be persistent.

    .PARAMETER DoNotImport
        Defines if the installed module should be imported.

    .PARAMETER AddToProfile
        Defines if an 'Import-Module' statement should be added to the profile.

    .PARAMETER Update
        Defines if an already existing folder in the target may be deleted for installation of the module.

    .PARAMETER DoNotPostInstall
        If defined, the PostInstallHook is not executed.

    .PARAMERTER PostInstallHook
        Defines the name of a script inside the installed module folder which should be executed after installation.
#>
function Install-ModuleToDestination {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String] $ModuleName,

        [Parameter(Mandatory=$true)]
        [String] $ModuleFolderPath,

        [Parameter(Mandatory=$true)]
        [String] $TempFolderPath,

        [Parameter(Mandatory=$true)]
        [String] $Destination,

        [String] $InstallWithModuleName,

        [String] $ModuleHash,

        [Switch] $Global,

        [Switch] $PersistEnvironment,

        [Switch] $DoNotImport,

        [Switch] $AddToProfile,

        [Switch] $Update,

        [Switch] $DoNotPostInstall,

        [String] $PostInstallHook
    )
    process {
        # Make certain the temp folder is deleted
        trap { Remove-Item -Path $TempFolderPath -Recurse -Force; break }

        $InstallWithModuleName = if ($InstallWithModuleName) { $InstallWithModuleName } else { $ModuleName }
        # Case: no $InstallWithModuleName and module name interfered from install files
        if (Test-ModuleInstalledAndImport -ModuleName:$InstallWithModuleName -Destination:$Destination -Update:$Update -DoNotImport:$DoNotImport -ModuleHash:$ModuleHash) {
            Remove-Item -Path $TempFolderPath -Recurse -Force
            return
        }

        $moduleFilePath = Get-ModuleFile -Path $ModuleFolderPath -ModuleName $ModuleName
        # sanity checks
        if (-not $moduleFilePath) {
            throw 'BUG! Module installation failed in step Install-ModuleToDestination. Please report this issue including your command line.'
        }
        if ($ModuleFolderPath -ne (Split-Path -Path $moduleFilePath)) {
            throw 'BUG! Module installation failed in step Install-ModuleToDestination. Please report this issue including your command line.'
        }

        if ($InstallWithModuleName -ne $ModuleName) {
            Rename-Item -Path $moduleFilePath -NewName ($InstallWithModuleName + (Get-Item $moduleFilePath).Extension)
        }

        $targetFolderPath = Join-Path -Path $Destination -ChildPath $InstallWithModuleName

        if ($ModuleHash) {
            Write-Verbose 'Ensure that the hash of the module matches the specified hash'

            $newModuleHash = Get-PsGetModuleHash -Path $ModuleFolderPath
            Write-Verbose "Hash of module in '$ModuleFolderPath' is: $newModuleHash"
            if ($ModuleHash -ne $newModuleHash) {
                throw 'Module contents do not match specified module hash. Ensure the expected hash is correct and the module source is trusted.'
            }

            if ( Test-Path $targetFolderPath ) {
                Write-Verbose 'Module already exists in destination path. Check if hash in destination is correct. If not replace with to be installed module.'
                $destinationModuleHash = Get-PsGetModuleHash -Path $targetFolderPath
                if ($destinationModuleHash -ne $ModuleHash ) {
                    $Update = $true
                }
            }
        }

        #Add the Destination path to the User or Machine environment
        Add-PathToPSModulePath -PathToAdd:$Destination -PersistEnvironment:$PersistEnvironment -Global:$Global

        if (-not (Test-Path $targetFolderPath)) {
            New-Item $targetFolderPath -ItemType Directory -ErrorAction Continue -ErrorVariable FailMkDir | Out-Null
            ## Handle the error if they asked for -Global and don't have permissions
            if ($FailMkDir -and @($FailMkDir)[0].CategoryInfo.Category -eq 'PermissionDenied') {
                throw "You do not have permission to install a module to '$Destination'. You may need to be elevated."
            }
            Write-Verbose "Create module folder at $targetFolderPath"
        }

        Write-Debug 'Empty existing module folder before copying new files.'
        Get-ChildItem -Path $targetFolderPath -Force | Remove-Item -Force -Recurse -ErrorAction Stop

        Write-Debug 'Copy module files to destination folder'
        Get-ChildItem -Path $ModuleFolderPath | Copy-Item -Destination $targetFolderPath -Force -Recurse

        if (-not $DoNotPostInstall) {
            Write-Verbose "PostInstallHook $PostInstallHook"
            if ($PostInstallHook -like '*.ps1') {
                $postInstallScript = Join-Path -Path $targetFolderPath -ChildPath $PostInstallHook
                if (Test-Path -Path $postInstallScript -PathType Leaf) {
                    Write-Verbose "'$PostInstallHook' found in module. Let's execute it."
                    & $postInstallScript
                }
                else {
                    Write-Verbose "PostInstallHook '$PostInstallHook' not found."
                }
            }
        }

        $isDestinationInPSModulePath = $env:PSModulePath.Contains($Destination)
        if ($isDestinationInPSModulePath) {
            if (-not (Get-Module $ModuleName -ListAvailable)) {
                throw 'For some unexpected reasons module was not installed.'
            }
        }
        else {
            if (-not (Get-ModuleFile -Path $targetFolderPath)) {
                throw 'For some unexpected reasons module was not installed.'
            }
        }

        if ($Update) {
            Write-Host "Module $ModuleName was successfully updated." -Foreground Green
        }
        else {
            Write-Host "Module $ModuleName was successfully installed." -Foreground Green
        }

        if (-not $DoNotImport) {
            Import-ModuleGlobally -ModuleName:$ModuleName -ModuleBase:$targetFolderPath -Force:$Update
        }

        if ($isDestinationInPSModulePath -and $AddToProfile) {
            # WARNING $Profile is empty on Win2008R2 under Administrator
            if ($PROFILE) {
                if (-not (Test-Path $PROFILE)) {
                    Write-Verbose "Creating PowerShell profile...`n$PROFILE"
                    New-Item $PROFILE -Type File -Force -ErrorAction Stop
                }

                if (Select-String $PROFILE -Pattern "Import-Module $ModuleName") {
                    Write-Verbose "Import-Module $ModuleName command already in your profile"
                }
                else {
                    $signature = Get-AuthenticodeSignature -FilePath $PROFILE

                    if ($signature.Status -eq 'Valid') {
                        Write-Error "PsGet cannot modify code-signed profile '$PROFILE'."
                    }
                    else {
                        Write-Verbose "Add Import-Module $ModuleName command to the profile"
                        "`nImport-Module $ModuleName" | Add-Content $PROFILE
                    }
                }
            }

        }

        Write-Debug "Cleanup temporary work folder '$TempFolderPath'"
        Remove-Item -Path $TempFolderPath -Recurse -Force
    }
}

<#
    .SYNOPSIS
        Test if module is installed and import it then.

    .DESCRIPTION
        Test if module with provided name is installed in the target destination.
        If it is installed, it will be imported. Returns '$true' if installed.

    .PARAMETER ModuleName
        Name of the module

    .PARAMETER Destination
        Installation destination

    .PARAMETER Update
        If 'Update'-switch is set, this returns always '$true'.

    .PARAMETER DoNotImport
        Switch suppress the import of module.

    .PARAMETER ModuleHash
        If a hash is provided an installed module will only be accepted as installed if the hash match.
#>
function Test-ModuleInstalledAndImport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String] $ModuleName,

        [Parameter(Mandatory=$true)]
        [String] $Destination,

        [Switch] $Update,

        [Switch] $DoNotImport,

        [String] $ModuleHash
    )
    process {
        if ($Update) {
            #TODO: This implementation is more like the old -Force flag, because this will force an installation also if no installation in destination exists.
            Write-Verbose "Ignoring if module with name '$ModuleName' is already installed because of update mode."
            return $false
        }

        $installedModule = Get-Module -Name $ModuleName -ListAvailable

        if ($installedModule) {
            if ($installedModule.Count -gt 1) {
                $targetModule = $installedModule | Where-Object { (ConvertTo-CanonicalPath -Path (Split-Path $_.ModuleBase)) -eq $Destination } | Select-Object -First 1

                if (-not $targetModule) {
                    Write-Warning "Module with name '$ModuleName' was not found in '$Destination'. But it was found in:`n $($installedModule.ModuleBase | Format-List | Out-String)"
                    return $false
                }

                Write-Warning "The module '$ModuleName' was installed at more then one location. Installed paths:`n`t$($installedModule.ModuleBase | Format-List | Out-String)`n'$($firstInstalledModule.ModuleBase)' is the searched destination."
                $installedModule = $targetModule
            }
            elseif ((Split-Path $installedModule.ModuleBase) -ne $Destination) {
                Write-Verbose "Module with name '$ModuleName' was found in '$($installedModule.ModuleBase)' but not in '$Destination'."
                return $false
            }
        }
        else {
            $candidateModulePath = Join-Path -Path $Destination -ChildPath $ModuleName
            $possibleModuleFileNames = Get-PossibleModuleFileNames -ModuleName $ModuleName

            if (Test-Path -Path $candidateModulePath\* -Include $possibleModuleFileNames -PathType Leaf) {
                Write-Verbose "Module with name '$ModuleName' found in '$Destination' (note: destination is not in PSModulePath)"
                $installedModule = @{ ModuleBase = $CandidateModulePath }
            }
            else {
                Write-Verbose "Module with name '$ModuleName' is not installed."
                return $false
            }
        }

        if ($ModuleHash) {
            $installedModuleHash = Get-PsGetModuleHash -Path $installedModule.ModuleBase
            Write-Verbose "Hash of module in '$($installedModule.ModuleBase)' is: $InstalledModuleHash"
            if ($ModuleHash -ne $installedModuleHash) {
                Write-Verbose "Expected '$ModuleHash' but calculated '$installedModuleHash'."
                return $false
            }
        }

        Write-Verbose "'$ModuleName' already installed. Use -Update if you need update"

        if ($DoNotImport -eq $false) {
            Import-ModuleGlobally -ModuleName $ModuleName -ModuleBase $installedModule.ModuleBase -Force:$Update
        }

        return $true
    }
}

<#
    .SYNOPSIS
        Extract the content of the referenced zip file to the defind destination

    .PARAMATER Path
        Path to a zip file with the file extension '.zip'

    .Parameter Destination
        Path to which the zip content is extracted
#>
function Expand-ZipModule {
    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true)]
        [String] $Path,

        [Parameter(Position=1, Mandatory=$true)]
        [String] $Destination
    )
    process {
        Write-Debug "Unzipping $Path to $Destination..."

        # Check if powershell v3+ and .net v4.5 is available
        $netFailed = $true
        if ( $PSVersionTable.PSVersion.Major -ge 3 -and (Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4' -Recurse | Get-ItemProperty -Name Version | Where-Object { $_.Version -like '4.5*' }) ) {
            Write-Debug 'Attempting unzip using the .NET Framework...'

            try {
                [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
                [System.IO.Compression.ZipFile]::ExtractToDirectory($Path, $Destination)
                $netFailed = $false
            }
            catch {
            }
        }

        if ($netFailed) {
            try {
                Write-Debug 'Attempting unzip using the Windows Shell...'
                $shellApp = New-Object -Com Shell.Application
                $shellZip = $shellApp.NameSpace([String]$Path)
                $shellDest = $shellApp.NameSpace($Destination)
                $shellDest.CopyHere($shellZip.items())
            }
            catch {
                $shellFailed = $true
            }
        }

        # if failure already registered or no result
        if (($netFailed -and $shellFailed) -or ((Get-ChildItem $Destination | Measure-Object | Where-Object { $_.Count -eq 0}))) {
            Write-Warning 'We were unable to decompress the downloaded module. This tends to mean both of the following are true:'
            Write-Warning '1. You''ve disabled Windows Explorer Zip file integration or are running on Windows Server Core.'
            Write-Warning '2. You don''t have the .NET Framework 4.5 installed.'
            Write-Warning 'You''ll need to correct at least one of the above issues depending on your installation to proceed.'
            throw 'Unable to unzip downloaded module file!'
        }
    }
}

<#
    .SYNOPSIS
        Update '$env:PSModulePath' from 'User' and 'Machine' scope envrionment variables
#>
function Update-PSModulePath {
    process {
        # powershell default
        $psModulePath = "$env:ProgramFiles\WindowsPowershell\Modules\"

        $machineModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
        if (-not $machineModulePath) {
            # powershell default
            $machineModulePath = Join-Path -Path $PSHOME -ChildPath 'Modules'
        }

        $userModulePath = [Environment]::GetEnvironmentVariable('PSModulePath', 'User')
        if (-not $userModulePath) {
            # powershell default
            $userModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'WindowsPowerShell\Modules'
        }

        $newSessionValue = "$userModulePath;$machineModulePath;$psModulePath"

        #Set the value in the current process
        [Environment]::SetEnvironmentVariable('PSModulePath', $newSessionValue, 'Process')
    }
}
#endregion

#region NuGet Handling
<#
    .SYNOPSIS
        Download a module of type NuGet package

    .PARAMETER NuGetPackageId
        NuGet package id

    .PARAMETER PackageVersion
        Specific version to be installed. If not defined, install newest.

    .PARAMETER Source
        NuGet source url

    .PARAMETER PreRelease
        If no PackageVersion is defined, may PreReleases be used?

    .PARAMETER PreReleaseTag
        If PreReleases may be used, also use prereleases of a special tag?
#>
function Invoke-DownloadNuGetPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String] $NuGetPackageId,

        [String] $PackageVersion,

        [Parameter(Mandatory=$true)]
        [String] $Source,

        [Switch] $PreRelease,

        [String] $PreReleaseTag
    )
    process {
        $WebClient = New-Object -TypeName System.Net.WebClient
        $WebClient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

        if (-not $Source.EndsWith('/')) {
            $Source += '/'
        }

        Write-Verbose "Querying '$Source' repository for package with Id '$NuGetPackageId'"
        $Url = "{1}Packages()?`$filter=tolower(Id)+eq+'{0}'&`$orderby=Id" -f $NuGetPackageId.ToLower(), $Source
        Write-Debug "NuGet query url: $Url"

        try {
            $XmlDoc = [xml]$WebClient.DownloadString($Url)
        }
        catch {
            throw "Unable to download from NuGet feed: $($_.Exception.InnerException.Message)"
        }

        if ($PackageVersion) {
            #  version regexs can be found in the NuGet.SemanticVersion class
            $Entry = $XmlDoc.feed.entry |
                Where-Object { $_.properties.Version -eq $PackageVersion } |
                Select-Object -First 1
        }
        else {
            $Entry = Find-LatestNugetPackageFromFeed -Feed:$XmlDoc.feed.entry -PreRelease:$PreRelease -PreReleaseTag:$PreReleaseTag
        }

        if ($Entry) {
            $PackageVersion = $Entry.properties.Version
            Write-Verbose "Found NuGet package version '$PackageVersion'"
        }
        else {
            throw ("Cannot find NuGet package '$NuGetPackageId $PackageVersion' [PreRelease='{0}', PreReleaseTag='{1}']" -f $PreRelease, $PreReleaseTag)
        }

        $DownloadUrl = $Entry.content.src
        Write-Verbose "Downloading NuGet package from '$DownloadUrl'"
        $DownloadResult = Invoke-DownloadModuleFromWeb -DownloadUrl:$DownloadUrl -ModuleName:$NugetPackageId
        return $DownloadResult
    }
}

<#
    .SYNOPSIS
        Find the latest release in the provided NuGet feed for the NuGet package id.

    .PARAMETER Feed
        Xml feed node for NuGet package

    .PARAMETER PreRelease
        If no PackageVersion is defined, may PreReleases be used?

    .PARAMETER PreReleaseTag
        If PreReleases may be used, also use prereleases of a special tag?
#>
function Find-LatestNugetPackageFromFeed {
    [CmdletBinding()]
    param
    (
        [Object[]] $Feed,

        [Switch] $PreRelease,

        [String] $PreReleaseTag
    )
    process {
        # From NuGet.SemanticVersion - https://github.com/Haacked/NuGet/blob/master/src/Core/SemanticVersion.cs
        $semVerRegex = "^(?<Version>\d+(\s*\.\s*\d+){0,3})(?<Release>-[a-z][0-9a-z-]*)?$"
        $semVerStrictRegex = "^(?<Version>\d+(\.\d+){2})(?<Release>-[a-z][0-9a-z-]*)?$"

        # find only stable versions
        $stableRegex = "^(\d+(\s*\.\s*\d+){0,3})?$"
        # find stable and prerelease versions
        $preReleaseRegex = "^(\d+(\s*\.\s*\d+){0,3})(-[a-z][0-9a-z-]*)?$"
        # find only a specific prerelease versions
        $specificPreReleaseRegex = "^(\d+(\s*\.\s*\d+){{0,3}}-{0}[0-9a-z-]*)?$" -f $preReleaseTag

        # Set the required search expression
        $searchRegex = $stableRegex
        if ($preRelease) { $searchRegex = $preReleaseRegex }
        if ($preReleaseTag) { $searchRegex = $specificPreReleaseRegex }

        $packages = $feed | Where-Object {

            ($_.properties.Version) -match $searchRegex
        }

        return ($packages | Select -Last 1)
    }
}

#endregion

#region Module Hashing
<#
    .SYNOPSIS
        Calculate a hash for the given file

    .PARAMETER Path
        File path for hasing
#>
function Get-FileHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [String] $Path
    )
    begin {
        $Algorithm = New-Object -TypeName System.Security.Cryptography.SHA256Managed
    }
    process {
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-Error "Cannot find file: $Path"
            return
        }

        $Stream = [System.IO.File]::OpenRead($Path)
        try {
            $HashBytes = $Algorithm.ComputeHash($Stream)
            [BitConverter]::ToString($HashBytes) -replace '-',''
        }
        finally {
            $Stream.Close()
        }
    }
}

<#
    .SYNOPSIS
        Calculate a hash for the given directory.

    .PARAMETER Path
        Path to the folder which should be hashed.
#>
function Get-FolderHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String] $Path
    )
    process {
        if (-not (Test-Path -Path $Path -PathType Container)) {
            throw "Cannot find folder: $Path"
        }

        $Path = $Path + '\' -replace '\\\\$','\\'
        $PathPattern = '^' + [Regex]::Escape($Path)

        $ChildHashes = Get-ChildItem -Path $Path -Recurse -Force |
            Where-Object { -not $_.PSIsContainer } |
            ForEach-Object {
                New-Object -TypeName PSObject -Property @{
                    RelativePath = $_.FullName -replace $PathPattern, ''
                    Hash = Get-FileHash -Path $_.FullName
                }
            }

        $Text = @($ChildHashes |
            Sort-Object -Property RelativePath |
            ForEach-Object {
                '{0} {1}' -f $_.Hash, $_.RelativePath
            }) -join '`r`n'

        Write-Debug "TEXT>$Text<TEXT"

        $Algorithm = New-Object -TypeName System.Security.Cryptography.SHA256Managed
        $HashBytes = $Algorithm.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))
        [BitConverter]::ToString($HashBytes) -replace '-',''
    }
}

#endregion

#endregion

#region TabExpansion
# Back Up TabExpansion if needed
# Idea is stolen from posh-git + ps-get
$tabExpansionBackup = 'PsGet_DefaultTabExpansion'
if ((Test-Path -Path Function:\TabExpansion -ErrorAction SilentlyContinue) -and -not (Test-Path -Path Function:\$tabExpansionBackup -ErrorAction SilentlyContinue)) {
    Rename-Item -Path Function:\TabExpansion $tabExpansionBackup -ErrorAction SilentlyContinue
}

# Revert old tabexpnasion when module is unloaded
# this does not cover all paths, but most of them
# Idea is stolen from PowerTab
$Module = $MyInvocation.MyCommand.ScriptBlock.Module
$Module.OnRemove = {
    Write-Debug 'Revert tab expansion back'
    Remove-Item -Path Function:\TabExpansion -ErrorAction SilentlyContinue
    if (Test-Path -Path Function:\$tabExpansionBackup) {
        Rename-Item -Path Function:\$tabExpansionBackup Function:\TabExpansion
    }
}

function TabExpansion {
    [CmdletBinding()]
    param(
        [String] $line,
        [String] $lastWord
    )
    process {
        if ($line -eq "Install-Module $lastword" -or $line -eq "inmo $lastword" -or $line -eq "ismo $lastword" -or $line -eq "upmo $lastword" -or $line -eq "Update-Module $lastword") {
            Get-PsGetModuleInfo -ModuleName "$lastword*" | % { $_.Id } | sort -Unique
        }
        elseif ( Test-Path -Path Function:\$tabExpansionBackup ) {
            & $teBackup $line $lastWord
        }
    }
}
#endregion

#region Module Interface
Set-Alias -Name inmo -Value Install-Module #Obsolete
Set-Alias -Name ismo -Value Install-Module
Set-Alias -Name upmo -Value Update-Module

Export-ModuleMember Install-Module
Export-ModuleMember Update-Module
Export-ModuleMember Get-PsGetModuleInfo
Export-ModuleMember Get-PsGetModuleHash
Export-ModuleMember TabExpansion
Export-ModuleMember -Alias inmo
Export-ModuleMember -Alias ismo
Export-ModuleMember -Alias upmo
#endregion
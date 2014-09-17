@{  
# These modules will be processed when the module manifest is loaded.  This is only supported in PS 3.0
#RootModule = "PsGet.psm1"

#This is required for PS 2.0
ModuleToProcess = "PsGet.psm1"

# The version of this module.  
ModuleVersion = '1.0'  

# This GUID is used to uniquely identify this module.  
GUID = '638FF397-8108-4B94-981A-D9BDAB4774B2'  

# The author of this module.  
Author = 'Mike Chaliy'  

# The company or vendor for this module.  
CompanyName = ''  

# The copyright statement for this module.  
Copyright = '(c) 2013'  

# Description of the functionality provided by this module  
Description = 'PsGet module for installing PowerShell modules'  

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of the .NET Framework required by this module
DotNetFrameworkVersion = '2.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '2.0'

# Processor architecture (None, X86, Amd64) required by this module
ProcessorArchitecture = 'None'

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module.
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''
}  
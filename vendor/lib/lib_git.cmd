@echo off

call "%~dp0lib_base.cmd"
call "%%~dp0lib_console.cmd"
set lib_git=call "%~dp0lib_git.cmd"

if "%~1" == "/h" (
    %lib_base% help "%~0"
) else if "%1" neq "" (
    call :%*
)

exit /b

:read_version
:::===============================================================================
:::read_version - Get the git.exe verion
:::.
:::include:
:::.
:::  call "lib_git.cmd"
:::.
:::usage:
:::.
:::  %lib_git% read_version "[dir_path]"
:::.
:::required:
:::.
:::  [GIT SCOPE]   <in> USER | VENDORED
:::  [GIT PATH]    <in> Fully qualified path to the Git command root.
:::.
:::output:
:::.
:::  GIT_VERSION_[GIT SCOPE] <out> Env variable containing Git semantic version string
:::-------------------------------------------------------------------------------

    setlocal enabledelayedexpansion
    :: clear the variables
    set GIT_VERSION_%~1=

    :: set the executable path
    set "git_executable=%~2\git.exe"
    %lib_console% debug_output :read_version "Env Var - git_executable=%git_executable%"

    :: check if the executable actually exists
    if not exist "%git_executable%" (
        %lib_console% debug_output :read_version "%git_executable% does not exist."
        exit /b -255
    )

    :: get the git version in the provided directory
    for /F "tokens=1,2,3 usebackq" %%A in (`"%git_executable%" --version 2^>nul`) do (
        if /i "%%A %%B" == "git version" (
            set "GIT_VERSION=%%C"
            %lib_console% debug_output :read_version "Env Var - GIT_VERSION_%~1=!GIT_VERSION!"
        ) else (
            %lib_console% show_error "git --version" returned an inproper version string!
            pause
            exit /b
        )
    )

    endlocal & set "GIT_VERSION_%~1=%GIT_VERSION%"
    exit /b

:parse_version
:::===============================================================================
:::parse_version - Parse semantic version string 'x.x.x.x' and return the pieces
:::.
:::include:
:::.
:::  call "$0"
:::.
:::usage:
:::.
:::  %lib_git% parse_version "[VERSION]"
:::.
:::required:
:::.
:::  [SCOPE]     <in> USER | VENDORED
:::  [VERSION]   <in> Semantic version String. Ex: 1.2.3.4
:::.
:::output:
:::.
:::  [SCOPE]_MAJOR <out> Scoped Major version.
:::  [SCOPE]_MINOR <out> Scoped Minor version.
:::  [SCOPE]_PATCH <out> Scoped Patch version.
:::  [SCOPE]_BUILD <out> Scoped Build version.
:::-------------------------------------------------------------------------------

    :: process a `x.x.x.xxxx.x` formatted string
    set "%~1_MAJOR="
    set "%~1_MINOR="
    set "%~1_PATCH="
    set "%~1_BUILD="
    %lib_console% debug_output :parse_version "ARGV[1]=%~1, ARGV[2]=%~2"
    for /F "tokens=1-3* delims=.,-" %%A in ("%2") do (
        set "%~1_MAJOR=%%A"
        set "%~1_MINOR=%%B"
        set "%~1_PATCH=%%C"
        set "%~1_BUILD=%%D"
    )

    exit /b

:validate_version
:::===============================================================================
:::validate_version - Validate semantic version string 'x.x.x.x'.
:::.
:::include:
:::.
:::  call "$0"
:::.
:::usage:
:::.
:::  %lib_git% validate_version [SCOPE] [VERSION]
:::.
:::required:
:::.
:::  [SCOPE]     <in> Example:  USER | VENDORED
:::  [VERSION]   <in> Semantic version String. Ex: 1.2.3.4
:::-------------------------------------------------------------------------------

    :: now parse the version information into the corresponding variables
    %lib_console% debug_output :validate_version "ARGV[1]=%~1, ARGV[2]=%~2"
    call :parse_version %~1 %~2

    :: ... and maybe display it, for debugging purposes.
    %lib_console% debug_output :validate_version "Found Git Version for %~1: !%~1_MAJOR!.!%~1_MINOR!.!%~1_PATCH!.!%~1_BUILD!"
    exit /b

:compare_versions
:::===============================================================================
:::compare_version - Compare semantic versions return latest version.
:::.
:::include:
:::.
:::  call "$0"
:::.
:::usage:
:::.
:::  %lib_git% validate_version [SCOPE1] [SCOPE2]
:::.
:::required:
:::.
:::  [SCOPE1]    <in> Example: USER
:::  [SCOPE2]    <in> Example: VENDOR
:::-------------------------------------------------------------------------------

    :: checks all major, minor, patch and build variables for the given arguments.
    :: whichever binary that has the most recent version will be used based on the return code.

    %lib_console% debug_output Comparing:
    %lib_console% debug_output %~1: !%~1_MAJOR!.!%~1_MINOR!.!%~1_PATCH!.!%~1_BUILD!
    %lib_console% debug_output %~2: !%~2_MAJOR!.!%~2_MINOR!.!%~2_PATCH!.!%~2_BUILD!

    if !%~1_MAJOR! GTR !%~2_MAJOR! (exit /b  1)
    if !%~1_MAJOR! LSS !%~2_MAJOR! (exit /b -1)

    if !%~1_MINOR! GTR !%~2_MINOR! (exit /b  1)
    if !%~1_MINOR! LSS !%~2_MINOR! (exit /b -1)

    if !%~1_PATCH! GTR !%~2_PATCH! (exit /b  1)
    if !%~1_PATCH! LSS !%~2_PATCH! (exit /b -1)

    if !%~1_BUILD! GTR !%~2_BUILD! (exit /b  1)
    if !%~1_BUILD! LSS !%~2_BUILD! (exit /b -1)

    :: looks like we have the same versions.
    exit /b 0

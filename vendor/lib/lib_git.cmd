@echo off

call "%~dp0lib_base.cmd"
call "%%~dp0lib_console.cmd"
set lib_git=call "%~dp0lib_git.cmd"

if "%~1" == "/h" (
    %lib_base% help "%0"
) else if "%1" neq "" (
    call :%*
)

exit /b

:read_version
::: ==============================================================================
:::enhance_path - Add a directory to the path env variable if required.
::: 
:::include: 
::: 
:::  call "$0"
:::
:::usage: 
::: 
:::  call "%~DP0lib_path" enhance_path "[dir_path]" [append]
::: 
:::required: 
::: 
:::  [dir_path] <in> Fully qualified directory path. Ex: "c:\bin"
::: 
:::dptions: 
::: 
:::  append     <in> Append instead rather than pre-pend "[dir_path]"
::: 
:::output:
::: 
:::  path       <out> Sets the path env variable if required. 
::: ------------------------------------------------------------------------------

    :: clear the variables
    set GIT_VERSION_%~1=

    :: set the executable path
    set "git_executable=%~2\git.exe"
    %lib_console% debug-output :read_version "Env Var - git_executable=%git_executable%"

    :: check if the executable actually exists
    if not exist "%git_executable%" (
        echo "%git_executable%" does not exist!
        exit /b -255
    )

    :: get the git version in the provided directory
    for /F "tokens=1,2,3 usebackq" %%F in (`"%git_executable%" --version 2^>nul`) do (
        if "%%F %%G" == "git version" (
            set "GIT_VERSION_%~1=%%H"
            %lib_console% debug-output :read_version "Env Var - GIT_VERSION_%~1=%%H"
        ) else (
            echo "git --version" returned an inproper version string!
            pause
            exit /b
        )
    )

    :: parse the returned string
    %lib_console% debug-output :read_version "Calling - :validate_version ^"%~1^" !GIT_VERSION_%~1!"
    call :validate_version "%~1" !GIT_VERSION_%~1!
    exit /b

:parse_version
    :: process a `x.x.x.xxxx.x` formatted string
    for /F "tokens=1-3* delims=.,-" %%A in ("%2") do (
        set "%~1_MAJOR=%%A"
        set "%~1_MINOR=%%B"
        set "%~1_PATCH=%%C"
        set "%~1_BUILD=%%D"
    )
    exit /b

:validate_version
    :: now parse the version information into the corresponding variables
    call :parse_version %~1 %~2

    :: ... and maybe display it, for debugging purposes.
    %lib_console% debug-output :validate_version "Found Git Version for %~1: !%~1_MAJOR!.!%~1_MINOR!.!%~1_PATCH!.!%~1_BUILD!"
    exit /b

:compare_versions
    :: checks all major, minor, patch and build variables for the given arguments.
    :: whichever binary that has the most recent version will be used based on the return code.

    :: %lib_console% debug-output Comparing:
    :: %lib_console% debug-output %~1: !%~1_MAJOR!.!%~1_MINOR!.!%~1_PATCH!.!%~1_BUILD!
    :: %lib_console% debug-output %~2: !%~2_MAJOR!.!%~2_MINOR!.!%~2_PATCH!.!%~2_BUILD!

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

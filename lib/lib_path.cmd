@echo off


call "%~dp0lib_base.cmd"
call "%%~dp0lib_console"
set lib_path=call "%~dp0lib_path.cmd"

if "%~1" == "/h" (
    %lib_base% help "%0"
) else if "%1" neq "" (
    call :%*
)

exit /b

:enhance_path
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

    setlocal enabledelayedexpansion
    set "find_query=%~1"
    set "find_query=%find_query:\=\\%"
    set "find_query=%find_query: =\ %"
    set found=0

    %lib_console% debug-output  :enhance_path "Env Var - find_query=%find_query%"
    echo "%PATH%"|findstr >nul /I /R ";%find_query%\"$"
    if "!ERRORLEVEL!" == "0" set found=1

    %lib_console% debug-output  :enhance_path "Env Var 1 - found=!found!"
    if "!found!" == "0" (
        echo "%PATH%"|findstr >nul /i /r ";%find_query%;"
        if "!ERRORLEVEL!" == "0" set found=1
        %lib_console% debug-output  :enhance_path "Env Var 2 - found=!found!"
    )

    if "%found%" == "0" (
        %lib_console% debug-output :enhance_path "BEFORE Env Var - PATH=!path!"
        if /i "%~2" == "append" (
            %lib_console% debug-output :enhance_path "Appending '%~1'"
            set "PATH=%PATH%;%~1"
        ) else (
            %lib_console% debug-output :enhance_path "Prepending '%~1'"
            set "PATH=%~1;%PATH%"
        )

        %lib_console% debug-output  :enhance_path "AFTER Env Var - PATH=!path!"
    )

    endlocal & set "PATH=%PATH%"
    exit /b

:enhance_path_recursive
::: ==============================================================================
:::enhance_path_recursive - Add a directory and subs to the path env variable if
:::                         required.
::: 
:::include: 
::: 
:::  call "$0"
:::
:::usage: 
::: 
:::  call "%~DP0lib_path" enhance_path_recursive "[dir_path]" [append]
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

    call :debug-output  :enhance_path_recursive "Adding parent directory - %1"
    call :enhance_path "%~1" %~2

    for /d %%i in ("%~1%\*") do (
        call :debug-output  :enhance_path_recursive "Found Subdirectory - %%~fi"
        call :enhance_path_recursive "%%~fi" %~2
    )

    exit /b

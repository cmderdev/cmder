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
:::===============================================================================
:::enhance_path - Add a directory to the path env variable if required.
:::
:::include:
:::
:::  call "$0"
:::
:::usage:
:::
:::  %lib_path% enhance_path "[dir_path]" [append]
:::
:::required:
:::
:::  [dir_path] <in> Fully qualified directory path. Ex: "c:\bin"
:::
:::options:
:::
:::  append     <in> Append to the path env variable rather than pre-pend.
:::
:::output:
:::
:::  path       <out> Sets the path env variable if required.
:::-------------------------------------------------------------------------------

    setlocal enabledelayedexpansion
    if "%~1" neq "" (
        set "add_path=%~1"
    ) else (
        %lib_console% show_error "You must specify a directory to add to the path!"
        exit 1
    )

    if "%~2" neq "" if /i "%~2" == "append" (
        set "position=%~2"
    ) else (
        set "position="
    )

    set "find_query=%add_path%"
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
        if /i "%position%" == "append" (
            %lib_console% debug-output :enhance_path "Appending '%add_path%'"
            set "PATH=%PATH%;%add_path%"
        ) else (
            %lib_console% debug-output :enhance_path "Prepending '%add_path%'"
            set "PATH=%add_path%;%PATH%"
        )

        %lib_console% debug-output  :enhance_path "AFTER Env Var - PATH=!path!"
    )

    endlocal & set "PATH=%PATH:;;=;%"
    exit /b

:enhance_path_recursive
:::===============================================================================
:::enhance_path_recursive - Add a directory and subs to the path env variable if
:::                         required.
:::.
:::include:
:::.
:::  call "$0"
:::.
:::usage:
:::.
:::  call "%~DP0lib_path" enhance_path_recursive "[dir_path]" [max_depth] [append]
:::.
:::required:
:::.
:::  [dir_path] <in> Fully qualified directory path. Ex: "c:\bin"
:::.
:::options:
:::.
:::  [max_depth] <in> Max recuse depth.  Default: 1
:::.
:::  append      <in> Append instead to path env variable rather than pre-pend.
:::.
:::output:
:::.
:::  path       <out> Sets the path env variable if required.
:::-------------------------------------------------------------------------------

    setlocal enabledelayedexpansion
    if "%~1" neq "" (
        set "add_path=%~1"
    ) else (
        %lib_console% show_error "You must specify a directory to add to the path!"
        exit 1
    )

    if "%~2" gtr "1" (
        set "max_depth=%~2"
    ) else (
        set "max_depth=1"
    )

    if "%~3" neq "" if /i "%~3" == "append" (
        set "position=%~3"
    ) else (
        set "position="
    )

    if "%depth%" == "" set depth=0

    %lib_console% debug-output  :enhance_path_recursive "Env Var - add_path=%add_path%"
    %lib_console% debug-output  :enhance_path_recursive "Env Var - position=%position%"
    %lib_console% debug-output  :enhance_path_recursive "Env Var - max_depth=%max_depth%"

    if %max_depth% gtr !depth! (
        %lib_console% debug-output :enhance_path_recursive "Adding parent directory - '%add_path%'"
        call :enhance_path "%add_path%" %position%
        set /a "depth=!depth!+1"

        for /d %%i in ("%add_path%\*") do (
            %lib_console% debug-output  :enhance_path_recursive "Env Var BEFORE - depth=!depth!"
            %lib_console% debug-output :enhance_path_recursive "Found Subdirectory - '%%~fi'"
            call :enhance_path_recursive "%%~fi" %max_depth% %position%
            %lib_console% debug-output  :enhance_path_recursive "Env Var AFTER- depth=!depth!"
        )
    )

    endlocal & set "PATH=%PATH%"
    exit /b

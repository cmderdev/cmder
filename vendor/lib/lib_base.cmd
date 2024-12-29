@echo off

set lib_base=call "%~dp0lib_base.cmd"

if "%~1" == "/h" (
    %lib_base% help "%~0"
) else if "%1" neq "" (
    call :%*
)

exit /b

:::===============================================================================
:::help - shows all sub routines in a .bat/.cmd file with documentation
:::.
:::include:
:::.
:::       call "lib_base.cmd"
:::.
:::usage:
:::.
:::       %lib_base% help "file"
:::.
:::options:
:::.
:::       file <in> full path to file containing lib_routines to display
:::-------------------------------------------------------------------------------

:help
    for /f "tokens=* delims=:" %%a in ('%WINDIR%\System32\findstr /i /r "^:::" "%~1"') do (
        if "%%a"=="." (
            echo.
        ) else if /i "%%a" == "usage" (
            echo %%a:
        ) else if /i "%%a" == "options" (
            echo %%a:
        ) else if not "%%a" == "" (
            echo %%a
        )
    )

    pause
    exit /b

:::===============================================================================
:::cmder_shell - Initializes the Cmder shell environment variables
:::.
:::description:
:::.
:::       This routine sets up the Cmder shell environment by detecting the
:::       command shell and initializing related variables.
:::.
:::include:
:::.
:::       call "lib_base.cmd"
:::.
:::usage:
:::.
:::       %lib_base% cmder_shell
:::-------------------------------------------------------------------------------

:cmder_shell
    call :detect_comspec %ComSpec%
    exit /b

:::===============================================================================
:::detect_comspec - Detects the command shell being used:::
:::.
:::description:
:::.
:::       This function sets the CMDER_SHELL variable to the name of the
:::       detected command shell. It also initializes the CMDER_CLINK and
:::       CMDER_ALIASES variables if they are not already defined.
:::.
:::include:
:::.
:::       call "lib_base.cmd"
:::.
:::usage:
:::.
:::       %lib_base% detect_comspec %ComSpec%
:::-------------------------------------------------------------------------------

:detect_comspec
    set CMDER_SHELL=%~n1
    if not defined CMDER_CLINK (
        set CMDER_CLINK=1
    )
    if not defined CMDER_ALIASES (
        set CMDER_ALIASES=1
    )
    exit /b

:::===============================================================================
:::update_legacy_aliases - Updates the legacy alias definitions in the user_aliases file
:::.
:::description:
:::.
:::       This function checks if the user_aliases file contains the marker
:::       ";= Add aliases below here". If the marker is not found, it creates
:::       an initial user_aliases store by copying the default user_aliases file
:::       from the CMDER_ROOT directory. If the CMDER_USER_CONFIG environment
:::       variable is defined, it creates a backup of the existing user_aliases
:::       file before copying the default file.
:::.
:::include:
:::.
:::       call "lib_base.cmd"
:::.
:::usage:
:::.
:::       %lib_base% update_legacy_aliases
:::-------------------------------------------------------------------------------

:update_legacy_aliases
    type "%user_aliases%" | %WINDIR%\System32\findstr /i ";= Add aliases below here" >nul
    if "%errorlevel%" == "1" (
        echo Creating initial user_aliases store in "%user_aliases%"...
        if defined CMDER_USER_CONFIG (
            copy "%user_aliases%" "%user_aliases%.old_format"
            copy "%CMDER_ROOT%\vendor\user_aliases.cmd.default" "%user_aliases%"
        ) else (
            copy "%user_aliases%" "%user_aliases%.old_format"
            copy "%CMDER_ROOT%\vendor\user_aliases.cmd.default" "%user_aliases%"
        )
    )
    exit /b

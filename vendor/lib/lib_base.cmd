@echo off

set lib_base=call "%~dp0lib_base.cmd"

if "%~1" == "/h" (
    %lib_base% help "%~0"
) else if "%1" neq "" (
    call :%*
)

exit /b

:help
:::===============================================================================
:::show_subs - shows all sub routines in a .bat/.cmd file with documentation
:::.
:::include:
:::.
:::       call "lib_base.cmd"
:::.
:::usage:
:::.
:::       %lib_base% show_subs "file"
:::.
:::options:
:::.
:::       file <in> full path to file containing lib_routines to display
:::.
:::-------------------------------------------------------------------------------
    for /f "tokens=* delims=:" %%a in ('type "%~1" ^| %WINDIR%\System32\findstr /i /r "^:::"') do (
        rem echo a="%%a"

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

:cmder_shell
:::===============================================================================
:::show_subs - shows all sub routines in a .bat/.cmd file with documentation
:::.
:::include:
:::.
:::       call "lib_base.cmd"
:::.
:::usage:
:::.
:::       %lib_base% cmder_shell
:::.
:::options:
:::.
:::       file <in> full path to file containing lib_routines to display
:::.
:::-------------------------------------------------------------------------------
    echo %comspec% | %WINDIR%\System32\find /i "\cmd.exe" > nul && set "CMDER_SHELL=cmd"
    echo %comspec% | %WINDIR%\System32\find /i "\tcc.exe" > nul && set "CMDER_SHELL=tcc"
    echo %comspec% | %WINDIR%\System32\find /i "\tccle" > nul && set "CMDER_SHELL=tccle"

    if not defined CMDER_CLINK (
      set CMDER_CLINK=1
      if "%CMDER_SHELL%" equ "tcc" set CMDER_CLINK=0
      if "%CMDER_SHELL%" equ "tccle" set CMDER_CLINK=0
    )


    if not defined CMDER_ALIASES (
      set CMDER_ALIASES=1
      if "%CMDER_SHELL%" equ "tcc" set CMDER_ALIASES=0
      if "%CMDER_SHELL%" equ "tccle" set CMDER_ALIASES=0
    )

    exit /b

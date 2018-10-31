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
    for /f "tokens=* delims=:" %%a in ('type "%~1" ^| findstr /i /r "^:::"') do (
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
    echo %comspec% | find /i "\cmd.exe" > nul && set "CMDER_SHELL=cmd"
    echo %comspec% | find /i "\tcc.exe" > nul && set "CMDER_SHELL=tcc"
    echo %comspec% | find /i "\tccle" > nul && set "CMDER_SHELL=tccle"

    set CMDER_CLINK=1
    if "%CMDER_SHELL%" equ "tcc" set CMDER_CLINK=0
    if "%CMDER_SHELL%" equ "tccle" set CMDER_CLINK=0

    set CMDER_ALIASES=1
    if "%CMDER_SHELL%" equ "tcc" set CMDER_ALIASES=0
    if "%CMDER_SHELL%" equ "tccle" set CMDER_ALIASES=0

    exit /b

:timer
  set start=%~1
  set end=%~2

  echo Start Time:   %start%
  echo End Time:     %end%
  set options="tokens=1-4 delims=:.,"
  for /f %options% %%a in ("%start%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
  for /f %options% %%a in ("%end%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100
  
  set /a hours=%end_h%-%start_h%
  set /a mins=%end_m%-%start_m%
  set /a secs=%end_s%-%start_s%
  set /a ms=%end_ms%-%start_ms%
  if %ms% lss 0 set /a secs = %secs% - 1 & set /a ms = 100%ms%
  if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60%secs%
  if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60%mins%
  if %hours% lss 0 set /a hours = 24%hours%
  if 1%ms% lss 100 set ms=0%ms%
  
  :: Mission accomplished
  set /a totalsecs = %hours%*3600 + %mins%*60 + %secs%
  echo Elapsed Time: %hours%:%mins%:%secs%.%ms% (%totalsecs%.%ms%s total)

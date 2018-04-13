@echo off

rem set args=%*

call "%~dp0lib_base.cmd"
set lib_console=call "%~dp0lib_console.cmd"

if "%~1" == "/h" (
    %lib_base% help "%0"
) else if "%1" neq "" (
    call :%*
)

exit /b

:debug-output
:::===============================================================================
:::debug-output - Output a debug message to the console.
:::.
:::include:
:::.
:::  call "$0"
:::.
:::usage:
:::.
:::  %lib_console% debug-output [caller] [message]
:::.
:::required:
:::.
:::  [caller]  <in> Script/sub routine name calling debug-output
:::.
:::  [message] <in> Message text to display.
:::.
:::-------------------------------------------------------------------------------

    if %debug-output% gtr 0 echo DEBUG(%~1): %~2 & echo.
    exit /b

:verbose-output
:::===============================================================================
:::verbose-output - Output a debug message to the console.
:::.
:::include:
:::.
:::  call "$0"
:::.
:::usage:
:::.
:::  %lib_console% verbose-output "[message]"
:::.
:::required:
:::.
:::  [message] <in> Message text to display.
:::.
:::-------------------------------------------------------------------------------

    if %verbose-output% gtr 0 echo %~1
    exit /b

:show_error
:::===============================================================================
:::show_error - Output an error message to the console.
:::.
:::include:
:::.
:::  call "$0"
:::.
:::usage:
:::.
:::  %lib_console% show_error "[message]"
:::.
:::required:
:::.
:::  [message] <in> Message text to display.
:::.
:::-------------------------------------------------------------------------------

    echo ERROR: %~1
    exit /b

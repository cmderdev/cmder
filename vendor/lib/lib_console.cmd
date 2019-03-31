@echo off

if "%fast_init%" == "1" exit /b

call "%~dp0lib_base.cmd"
set lib_console=call "%~dp0lib_console.cmd"

if "%~1" == "/h" (
    %lib_base% help "%~0"
) else if "%1" neq "" (
    call :%*
)

exit /b

:debug_output
:::===============================================================================
:::debug_output - Output a debug message to the console.
:::.
:::include:
:::.
:::  call "lib_console.cmd"
:::.
:::usage:
:::.
:::  %lib_console% debug_output [caller] [message]
:::.
:::required:
:::.
:::  [caller]  <in> Script/sub routine name calling debug_output
:::.
:::  [message] <in> Message text to display.
:::.
:::-------------------------------------------------------------------------------

    if %debug_output% gtr 0 echo DEBUG(%~1): %~2 & echo.
    exit /b

:verbose_output
:::===============================================================================
:::verbose_output - Output a debug message to the console.
:::.
:::include:
:::.
:::  call "$0"
:::.
:::usage:
:::.
:::  %lib_console% verbose_output "[message]"
:::.
:::required:
:::.
:::  [message] <in> Message text to display.
:::.
:::-------------------------------------------------------------------------------

    if %verbose_output% gtr 0 echo %~1
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

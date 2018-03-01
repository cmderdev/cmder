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
::: ==============================================================================
:::debug-output - Output a debug message to the console.
::: 
:::include: 
::: 
:::  call "$0"
:::
:::usage: 
::: 
:::  %lib_console% "debug-output"
::: 
:::required: 
::: 
:::  [message] <in> Message text to display.
::: 
::: ------------------------------------------------------------------------------

    if %debug-output% gtr 0 echo DEBUG(%~1): %~2 & echo.
    exit /b

:verbose-output
::: ==============================================================================
:::verbose-output - Output a debug message to the console.
::: 
:::include: 
::: 
:::  call "$0"
:::
:::usage: 
::: 
:::  %lib_console% "verbose-output"
::: 
:::required: 
::: 
:::  [message] <in> Message text to display.
::: 
::: ------------------------------------------------------------------------------

    if %debug-output% gtr 0 (
      %lib_console% debug-output :verbose-output "%*"
    ) else if %verbose-output% gtr 0 (
      echo %~1
    )
    exit /b

:show_error
::: ==============================================================================
:::show_error - Output an error message to the console.
::: 
:::include: 
::: 
:::  call "$0"
:::
:::usage: 
::: 
:::  %lib_console% "show_error"
::: 
:::required: 
::: 
:::  [message] <in> Message text to display.
::: 
::: ------------------------------------------------------------------------------

    echo ERROR: %*
    echo CMDER Shell Initialization has Failed!
    exit /b



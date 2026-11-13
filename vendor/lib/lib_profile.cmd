@echo off

call "%~dp0lib_base.cmd"
call "%~dp0lib_console.cmd"
set lib_profile=call "%~dp0lib_profile.cmd"

if "%~1" == "/h" (
    %lib_base% help "%~0"
) else if "%~1" neq "" (
    call :%*
)

exit /b

:::===============================================================================
:::run_profile_d - Run all scripts in the passed directory path
:::.
:::include:
:::.
:::  call "lib_profile.cmd"
:::.
:::usage:
:::.
:::  %lib_profile% "[dir_path]"
:::.
:::required:
:::.
:::  [dir_path] <in> Fully qualified directory path containing init *.cmd|*.bat.
:::                  Example: "c:\bin"
:::.
:::  path       <out> Sets the path env variable if required.
:::-------------------------------------------------------------------------------

:run_profile_d
    if not exist "%~1" (
        "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%CMDER_ROOT%\vendor\bin\first-run.ps1" -Action ProfileDirectory -Target "%~1"
        if errorlevel 1 exit /b 1
    )

    pushd "%~1" || exit /b 1
    for /f "usebackq" %%x in ( `dir /b *.bat *.cmd 2^>nul` ) do (
        %print_verbose% "Calling '%~1\%%x'..."
        call "%~1\%%x"
    )
    popd
    exit /b 0

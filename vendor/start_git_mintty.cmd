@echo off

if not defined CMDER_ROOT (
    if defined ConEmuDir (
        for /f "delims=" %%i in ("%ConEmuDir%\..\..") do (
            set "CMDER_ROOT=%%~fi"
        )
    ) else (
        for /f "delims=" %%i in ("%~dp0\..") do (
            set "CMDER_ROOT=%%~fi"
        )
    )
)

if exist "%CMDER_ROOT%\vendor\git-for-windows" (
  set "PATH=%CMDER_ROOT%\vendor\git-for-windows\usr\bin;%PATH%"
  set "gitCmd=%CMDER_ROOT%\vendor\git-for-windows\usr\bin\mintty.exe"
) else if exist "%ProgramFiles%\git" (
  set "PATH=%ProgramFiles%\git\usr\bin;%PATH%"
  set "gitCmd=%ProgramFiles%\git\usr\bin\mintty.exe"
  if not exist "%ProgramFiles%\git\etc\profile.d\cmder_exinit.sh" (
    echo Run 'mklink "%ProgramFiles%\git\etc\profile.d\cmder_exinit.sh" "%CMDER_ROOT%\vendor\cmder_exinit"' in 'cmd::Cmder as Admin' to use Cmder with external Git Bash
    echo.
    echo or
    echo.
    echo Run 'echo "" ^> "%ProgramFiles%\git\etc\profile.d\cmder_exinit.sh"' in 'cmd::Cmder as Admin' to disable this message.
  )
) else if exist "%ProgramFiles(x86)%\git" (
  set "PATH=%ProgramFiles(x86)%\git\usr\bin;%PATH%"
  set "gitCmd=%ProgramFiles(x86)%\git\usr\bin\mintty.exe"
  if not exist "%ProgramFiles(x86)%\git\etc\profile.d\cmder_exinit.sh" (
    echo Run 'mklink "%ProgramFiles^(x86^)%\git\etc\profile.d\cmder_exinit.sh" "%CMDER_ROOT%\vendor\cmder_exinit"' in 'cmd::Cmder as Admin' to use Cmder with external Git Bash
    echo.
    echo or
    echo.
    echo Run 'echo "" ^> "%ProgramFiles^(x86^)%\git\etc\profile.d\cmder_exinit.sh"' in 'cmd::Cmder as Admin' to disable this message.
  )
)

"%gitCmd%" /bin/bash -l

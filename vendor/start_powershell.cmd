@echo off
setlocal DisableDelayedExpansion

:: Prefer the stable PowerShell 7 installation, including native 64-bit from WoW64.
set "cmder_powershell="
if defined ProgramFiles(x86) if exist "%ProgramFiles(x86)%\PowerShell\7\pwsh.exe" if not exist "%ProgramFiles(x86)%\PowerShell\7\pwsh.exe\" set "cmder_powershell=%ProgramFiles(x86)%\PowerShell\7\pwsh.exe"
if defined ProgramFiles if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" if not exist "%ProgramFiles%\PowerShell\7\pwsh.exe\" set "cmder_powershell=%ProgramFiles%\PowerShell\7\pwsh.exe"
if defined ProgramW6432 if exist "%ProgramW6432%\PowerShell\7\pwsh.exe" if not exist "%ProgramW6432%\PowerShell\7\pwsh.exe\" set "cmder_powershell=%ProgramW6432%\PowerShell\7\pwsh.exe"
if defined cmder_powershell goto launch

:: Support portable installs and Store execution aliases on PATH. Skip PowerShell 6.
:: Search PATH explicitly so an unrelated pwsh.exe in the current directory is ignored.
for /f "delims=" %%P in ('""%SystemRoot%\System32\where.exe" "$PATH:pwsh.exe"" 2^>nul') do (
    "%%P" -NoLogo -NoProfile -NonInteractive -Command "if ($PSVersionTable.PSVersion.Major -ge 7) { exit 0 } else { exit 1 }" >nul 2>nul
    if errorlevel 0 if not errorlevel 1 (
        set "cmder_powershell=%%P"
        goto launch
    )
)

set "cmder_powershell=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if defined PROCESSOR_ARCHITEW6432 if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "cmder_powershell=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

:launch
:: Explicit arguments keep the native pwsh CLI behavior, including -File/-Command/-Version.
if not "%~1" == "" goto arguments
for %%R in ("%~dp0..") do set "CMDER_ROOT=%%~fR"
set "CMDER_PS_PROFILE=%~dp0profile.ps1"
"%cmder_powershell%" -ExecutionPolicy Bypass -NoLogo -NoProfile -NoExit -Command ". $env:CMDER_PS_PROFILE"
exit /b %errorlevel%

:arguments
"%cmder_powershell%" %*
exit /b %errorlevel%

@echo off
setlocal
set "helper=%ConEmuBaseDir%\ConEmuC.exe"
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "helper=%ConEmuBaseDir%\ConEmuC64.exe"
if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" set "helper=%ConEmuBaseDir%\ConEmuC64.exe"

rem ConPTY requires Windows 10 1809. Use the classic shell if unavailable.
for /f "tokens=2 delims=[]" %%V in ('ver') do for /f "tokens=3 delims=." %%B in ("%%V") do (
    if %%B LSS 17763 goto classic
)
if not exist "%helper%" goto classic

"%helper%" /PTY cmd.exe /d /k "%CMDER_ROOT%\vendor\init.cmd"
exit /b %errorlevel%

:classic
cmd.exe /d /k ""%CMDER_ROOT%\vendor\init.cmd""
exit /b %errorlevel%

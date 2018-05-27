@echo off
set "flag_exists=%~dp0flag_exists"
setlocal

if "%~1" equ "" goto :wrongSyntax

if not defined CMDER_USER_FLAGS (
  set "CMDER_USER_FLAGS= "
)

set "feNOT=false"
goto :parseArgument

:doShift
  shift

:parseArgument
set "currenTarg=%~1"
if /i "%currenTarg%" == "/?" (
  goto :help
) else if /i "%currenTarg%" equ "/help" (
  goto :help
) else if /i "%currenTarg%" equ "/h" (
  goto :help
) else if /i "%currenTarg%" equ "NOT" (
  set "feNOT=true"
  goto :doShift
) else (
  if "%~1" equ "" goto :wrongSyntax
  if "%~2" equ "" goto :wrongSyntax
  set "feArgName=%~1"
  set "feCommand=%~2"
  goto :detect
)

:detect
:: to avoid erroneous deteciton like "/do" "/doNOT", both have a "/do"
:: but if it works like "/do " "/doNOT ", "/do " won't match "/doN"
set "CMDER_USER_FLAGS=%CMDER_USER_FLAGS% "
set "feArgName=%feArgName% "
:: echo.
:: echo %CMDER_USER_FLAGS%
:: echo %feNOT%
:: echo %feArgName%
:: echo %feCommand%
:: echo.
echo %CMDER_USER_FLAGS% | find /i "%feArgName%">nul
if "%ERRORLEVEL%" == "0" (
  if "%feNOT%" == "false" (
    call "%feCommand%"
  )
) else (
  if "%feNOT%" == "true" (
    call "%feCommand%"
  )
)
exit /b

:wrongSyntax
echo The syntax of the command is incorrect.
echo.
echo use /? for help
echo.
exit /b

:help
echo.
echo %%flag_exists%%
echo.
echo Handles with custom arguments for cmder's init.bat.
echo   written by xiazeyu, inspired DRSDavidSoft.
echo.
echo Usage:
echo.
echo %%flag_exists%% [NOT] argName command
echo.
echo   NOT      Specifies that %%flag_exists%% should carry out
echo            the command only if the condition is false.
echo.
echo   argName  Specifies which argument name is to detect.
echo.
echo   command  Specifies the command to carry out if the
echo            argument name is detected. It's recommand to
echo            use a pair of double quotation marks to
echo            wrap your command to avoid exceed expectation.
echo.
echo Examples:
echo.
echo   these examples are expected to be writted in /config/user-profile.cmd
echo   it will use the environment varible "CMDER_USER_FLAGS"
echo.
echo   Case 1:
echo.
echo   The following command in user-profile.cmd would execute "notepad.exe"
echo.
echo     call %%flag_exists%% "/startNotepad" "cmd /c start notepad.exe"
echo.
echo   if you pass parameter to init.bat like:
echo.
echo     init.bat /startNotepad
echo.
echo   Case 2:
echo.
echo   The following command in user-profile.cmd would execute "notepad.exe"
echo.
echo     call %%flag_exists%% NOT "/dontStartNotepad" "cmd /c start notepad.exe"
echo.
echo   UNLESS you pass parameter to init.bat like:
echo.
echo     init.bat /dontStartNotepad
echo.
exit /b

@echo off
if ["%1"] == ["/?"] goto:p_help
if ["%1"] == [""] echo Insufficient parameters. & goto:p_help

setlocal

:: Check if alias exists
doskey /macros | findstr /b %1= >NUL || goto :p_not_found

:: Remove alias from current shell
doskey %1=

:: Remove alias from aliases file
copy /y "%CMDER_ROOT%\config\aliases" "%TEMP%\aliases.prev" >NUL
type "%TEMP%\aliases.prev" | findstr /b /v %1= > "%CMDER_ROOT%\config\aliases"
echo Alias removed

endlocal
goto:eof

:p_not_found
echo Alias not defined.
goto:eof

:p_help
echo.Usage:
echo.	unalias name
echo.	For more information, read DOSKEY/?

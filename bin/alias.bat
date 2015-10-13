@echo off

set ALIASES=%CMDER_ROOT%\config\aliases
setlocal
:: handle quotes within command definition, e.g. quoted long file names
set _x="%*"
set _x=%_x:"=%

:: check command usage
if ["%_x%"] == [""] echo Use /? for help & echo. & goto :p_show
if ["%1"] == ["/?"] goto:p_help
if ["%1"] == ["/reload"] goto:p_reload
:: /d flag for delete existing alias
if ["%1"] == ["/d"] goto:p_del %*
:: if arg is an existing alias, display it
if ["%2"] == [""] (
  doskey /macros | findstr /b %1= && goto:eof
  echo Insufficient parameters. & goto:p_help
)

:: validate alias
for /f "delims== tokens=1" %%G in ("%_x%") do set alias=%%G
set _temp=%alias: =%

if not ["%_temp%"] == ["%alias%"] (
	echo Your alias name can not contain a space
	endlocal
	goto:eof
)

:: replace already defined alias
findstr /b /v /i "%alias%=" "%ALIASES%" >> "%ALIASES%.tmp"
echo %* >> "%ALIASES%.tmp" && type "%ALIASES%.tmp" > "%ALIASES%" & @del /f /q "%ALIASES%.tmp"
doskey /macrofile="%ALIASES%"
endlocal
goto:eof

:p_del
findstr /b /v /i "%2=" "%ALIASES%" >> "%ALIASES%.tmp"
type "%ALIASES%".tmp > "%ALIASES%" & @del /f /q "%ALIASES%.tmp"
doskey /macrofile=%ALIASES%
goto:eof

:p_reload
doskey /macrofile="%ALIASES%"
echo Aliases reloaded
goto:eof

:p_show
type "%ALIASES%" || echo No aliases found at "%ALIASES%"
goto :eof

:p_help
echo.Usage:
echo.	alias [/reload] [/d] [name=full command]
echo.     /reload  Reload the aliases file
echo.     /d       Delete an alias (must be followed by the alias name)
echo.
echo.	If alias is called with any parameters, it will display the list of existing aliases.
echo.	In the command, you can use the following notations:
echo.	$* allows the alias to assume all the parameters of the supplied command.
echo.	$1-$9 Allows you to seperate parameter by number, much like %%1 in batch.
echo.	$T is the command seperator, allowing you to string several commands together into one alias.
echo.	For more information, read DOSKEY/?

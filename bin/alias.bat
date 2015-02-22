@echo off
if ["%1"] == ["/?"] goto:p_help
if ["%2"] == [""] echo Insufficient parameters. & goto:p_help

setlocal
::handle quotes within command definition, e.g. quoted long file names
set _x="%*"
set _x=%_x:"=%

::validate alias
for /f "delims== tokens=1" %%G in ("%_x%") do set alias=%%G
set _temp=%alias: =%
if not ["%_temp%"] == ["%alias%"] (
	echo Your alias name can not contain a space
	endlocal
	goto:eof
)

echo %* >> "%CMDER_ROOT%\config\aliases"
doskey /macrofile="%CMDER_ROOT%\config\aliases"
echo Alias created
endlocal
goto:eof

:p_help
echo.Usage:
echo.	alias name=full command
echo.	$* allows the alias to assume all the parameters of the supplied command.
echo.	$1-$9 Allows you to seperate parameter by number, much like %%1 in batch.
echo.	$T is the command seperator, allowing you to string several commands together into one alias.
echo.	For more information, read DOSKEY/?

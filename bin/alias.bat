@echo off
if ["%1"] == ["/?"] goto:p_help
if ["%2"] == [""] echo Insufficient parameters. & goto:p_help
::validate alias
setlocal
for /f "delims== tokens=1" %%G in ("%*") do set _temp2=%%G

	set _temp=%_temp2: =%

if not ["%_temp%"] == ["%_temp2%"] (
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

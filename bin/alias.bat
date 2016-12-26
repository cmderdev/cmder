@echo off


if "%aliases%" == "" (
  set ALIASES=%CMDER_ROOT%\config\user-aliases.cmd
)

setlocal enabledelayedexpansion

if "%~1" == "" echo Use /? for help & echo. & goto :p_show

:: check command usage

rem #region parseargument
goto parseargument

:do_shift
  shift

:parseargument
  set currentarg=%~1

  if /i "%currentarg%" equ "/f" (
    set aliases=%~2
    shift
    goto :do_shift
  ) else if /i "%currentarg%" == "/reload" (
    goto :p_reload
  ) else if "%currentarg%" equ "/?" (
    goto :p_help
  ) else if /i "%currentarg%" equ "/d" (
    if "%~2" neq "" (
      if "%~3" equ "" (
        :: /d flag for delete existing alias
        call :p_del %~2
        shift
        goto :eof
      )
    )
  ) else if "%currentarg%" neq "" (
    if "%~2" equ "" (
      :: Show the specified alias
      doskey /macros | findstr /b %currentarg%= && exit /b
      echo insufficient parameters.
      goto :p_help
    ) else (
      :: handle quotes within command definition, e.g. quoted long file names
      set _x=%*
    )
  )
rem #endregion parseargument

if "%aliases%" neq "%CMDER_ROOT%\config\user-aliases.cmd" (
  set _x=!_x:/f %aliases% =!

  if not exist "%aliases%" (
    echo ;= @echo off>"%aliases%"
    echo ;= rem Call DOSKEY and use this file as the macrofile>>"%aliases%"
    echo ;= %%SystemRoot%%\system32\doskey /listsize=1000 /macrofile=%%0%%>>"%aliases%"
    echo ;= rem In batch mode, jump to the end of the file>>"%aliases%"
    echo ;= goto:eof>>"%aliases%"
    echo ;= Add aliases below here>>"%aliases%"
  )
)

:: validate alias
for /f "delims== tokens=1,2 usebackq" %%G in (`echo "%_x%"`) do (
  set alias_name=%%G
  set alias_value=%%H
)

:: leading quotes added while validating
set alias_name=%alias_name:~1%

:: trailing quotes added while validating
set alias_value=%alias_value:~0,-1%

::remove spaces
set _temp=%alias_name: =%

if not ["%_temp%"] == ["%alias_name%"] (
	echo Your alias name can not contain a space
	endlocal
	exit /b
)

:: replace already defined alias
findstr /b /v /i "%alias_name%=" "%ALIASES%" >> "%ALIASES%.tmp"
echo %alias_name%=%alias_value% >> "%ALIASES%.tmp" && type "%ALIASES%.tmp" > "%ALIASES%" & @del /f /q "%ALIASES%.tmp"
doskey /macrofile="%ALIASES%"
endlocal
exit /b

:p_del
set del_alias=%~1
findstr /b /v /i "%del_alias%=" "%ALIASES%" >> "%ALIASES%.tmp"
type "%ALIASES%".tmp > "%ALIASES%" & @del /f /q "%ALIASES%.tmp"
doskey %del_alias%=
doskey /macrofile=%ALIASES%
goto:eof

:p_reload
doskey /macrofile="%ALIASES%"
echo Aliases reloaded
exit /b

:p_show
doskey /macros|findstr /v /r "^;=" | sort
exit /b

:p_help
echo.Usage:
echo. 
echo.	alias [options] [alias=full command]
echo. 
echo.Options:
echo. 
echo.     /d [alias]     Delete an [alias].
echo.     /f [macrofile] Path to the [macrofile] you want to store the new alias in.
echo.                    Default: %cmder_root%\config\user-aliases.cmd
echo.     /reload        Reload the aliases file.  Can be used with /f argument.
echo.                    Default: %cmder_root%\config\user-aliases.cmd
echo.
echo.	If alias is called with no parameters, it will display the list of existing aliases.
echo.
echo.	In the command, you can use the following notations:
echo.	$* allows the alias to assume all the parameters of the supplied command.
echo.	$1-$9 Allows you to seperate parameter by number, much like %%1 in batch.
echo.	$T is the command seperator, allowing you to string several commands together into one alias.
echo.	For more information, read DOSKEY/?
exit /b

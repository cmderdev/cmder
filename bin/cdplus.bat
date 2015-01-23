@echo off

set _cdplus_old_path=%CD%

:: sanity check - remove /d parameter
if "%~1" == "/d" shift

if "%~1" == "" goto :p_home
if "%~1" == "-" goto :p_previous
if "%~1" == "/h" goto :p_history
if "%~1" == "/p" goto :p_popHistory
if "%~1" == "/clean" goto :p_clean
if "%~1" == "/?" goto :p_help
echo %1| findstr /r "^[0-9]$">nul 2>&1
if %errorLevel% == 0 (
    if not exist "%CD%\%~1" goto :p_number
)

:: normal case
chdir /d "%~1"
goto :p_storePath

:: "cd" => go to %HOME%
:p_home
if defined HOME (
    chdir /d %HOME%
) else (
    chdir /d %USERPROFILE%
)
goto :p_storePath

:: "cd -" => go to previous path if exist
:p_previous
call :goToPreviousPath
goto :p_storePath

:: "cd /h" => show the last history lines
:p_history
if "%~2" == "" (
    call :showHistory 10
) else (
    call :showHistory "%~2"
)
goto:eof

:: "cd /p" => pop the last history line
:p_popHistory
call :popPrevious
call :showHistory 2
goto :p_storePrevious

:: "cd /clean" => cleanup txt files
:p_clean
call :cleanup
goto:eof

:: "cd x" (where x=[0-9]) => go to history line x
:p_number
call :goToNumber %1
goto :p_storePath

:: "cd /?" => show help
:p_help
call :showHelp
goto:eof

:: ---------------
:: Post processing
:: ---------------
:p_storePath
if "%_cdplus_old_path%"=="%CD%" goto:eof
call :storePath "%_cdplus_old_path%"

:p_storePrevious
call :setPreviousPath "%_cdplus_old_path%"

:: END
goto:eof

:: ---------
:: Functions
:: ---------
:showHelp
echo.Changes the current directory
echo.
echo.CD [drive:][path]
echo.CD [..]
echo.  Changes the current directory to the one paassed in parameter.
echo.  .. means the parent directory
echo.  If no directories are passed then goes to the %%HOME%% or %%USERPROFILE%%.
echo.  When navigating, the history is kept (50 lines maximum).
echo.
echo.CD -
echo.  Goes to previous directory.
echo.  The current directory is added to the history.
echo.
echo.CD /p
echo.  Goes to the previous directory.
echo.  The previous directory is removed from the history (pop), and the current one not saved.
echo.
echo.CD [0-9]
echo.  If a number between 0-9 is passed, and it's not an exist directory, then goes to the corrseponding line in the history.
echo.
echo.CD /h [x]
echo.   Shows the history.
echo.   By default, shows 10 lines, except if a number is passed in parameter.
echo.
echo.CD /clean
echo.   Removes all the history.
goto:eof

:cleanup
    set file=%TEMP%\%ConEmuServerPID%.cdplus.txt
    set filep=%TEMP%\%ConEmuServerPID%.cdplus-previous.txt
    if exist "%file%" (
        ren "%file%"
        ren "%filep%"
    )
goto:eof

:goToNumber
    set file=%TEMP%\%ConEmuServerPID%.cdplus.txt
    if exist "%file%" (
        if %1==0 (
            call :goToPreviousPath
        ) else (
            for /f "skip=%1 delims=" %%x in (%file%) do (
                chdir /d "%%x"
                goto:eof
            )
        )
    )
goto:eof

:popPrevious
    set file=%TEMP%\%ConEmuServerPID%.cdplus.txt
    if exist "%file%" (
        ren "%file%" "%ConEmuServerPID%.cdplus.txt.old"
        for /f "delims=" %%x in (%file%.old) do (
            chdir /d "%%x"
            goto :endPopPrevious
        )
        :endPopPrevious
        for /f "skip=1 delims=" %%x in (%file%.old) do (
            echo %%x>>"%file%"
        )
        del "%file%.old"
    )
goto:eof

:showHistory
    setlocal EnableDelayedExpansion
    set file=%TEMP%\%ConEmuServerPID%.cdplus.txt
    if exist "%file%" (
        set /a count=0
        for /f "delims=" %%x in (%file%) do (
            echo !count! - %%x
            set /a count+=1
            if !count!==%~1 goto :endShowHistory
        )
    )
    :endShowHistory
    endlocal
goto:eof

:storePath
    set file=%TEMP%\%ConEmuServerPID%.cdplus.txt
    if exist "%file%" (
        ren "%file%" "%ConEmuServerPID%.cdplus.txt.old"
    )
    echo %~1>"%file%"
    setlocal EnableDelayedExpansion
    set /a count=0
    if exist "%file%.old" (
        for /f "delims=" %%x in (%file%.old) do (
            echo %%x>>"%file%"
            set /a count+=1
            if !count!==50 goto :endStorePath
        )
        :endStorePath
        del "%file%.old"
    )
    endlocal
goto:eof

:setPreviousPath
    set file=%TEMP%\%ConEmuServerPID%.cdplus-previous.txt
    echo %~1>"%file%"
goto:eof

:goToPreviousPath
    set file=%TEMP%\%ConEmuServerPID%.cdplus-previous.txt
    if exist "%file%" (
        for /f "delims=" %%x in (%file%) do (
            chdir /d "%%x"
            goto:eof
        )
    )
goto:eof

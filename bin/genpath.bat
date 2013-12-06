@echo off
setlocal EnableDelayedExpansion

set NEWPATH=
for %%a in ("%path:;=";"%") do (
    echo %%~a | findstr /I /C:"%CMDER_ROOT%\bin" 1>nul
    if errorlevel 1 (
        if not "%%~a"=="" set NEWPATH=!NEWPATH!;%%~a
    )
)

set NEWPATH=!NEWPATH!;%CMDER_ROOT%\bin

pushd %~dp0
for /f "delims=" %%f in ('dir /b /ad') do (
    pushd %%f
    if exist cmder_path (
        for /f "delims=" %%i in (cmder_path) do set NEWPATH=!NEWPATH!;!CD!\%%i
    ) else (
        set NEWPATH=!NEWPATH!;!CD!
    )
    popd
)
popd

endlocal && set PATH=%NEWPATH%
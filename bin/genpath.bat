:: This script checks for folders in \bin that contain executables
:: and adds them to PATH. It also adds all folders that match \bin\*\bin

@echo off
setlocal EnableDelayedExpansion

pushd %CD%
cd /d "%CMDER_ROOT%\bin"

for /d %%D in (*) do (
    :: Check for existence of folders in bin
    set PATH=!PATH!;%CD%\%%D
    :: Find all \bin\*\bin and also add them
    if exist "%%D\bin" (
        set PATH=!PATH!;%CD%\%%D\bin
    )
)

popd
endlocal & ( PATH = %PATH%;%CMDER_ROOT%\bin )



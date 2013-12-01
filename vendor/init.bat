:: Init Script for cmd.exe
:: Sets some nice defaults
:: Created as part of cmder project


:: Setting prompt style
@for /f "tokens=2 delims=:." %%x in ('chcp') do @set cp=%%x
:: The slow part
:: World without Unicode is a sad world
@chcp 65001>nul
:: It has to be lambda, I already made a logo
@prompt $E[1;32;40m$P$S{git}$S$_$E[1;30;40mλ$S$E[0m
@chcp %cp%>nul


:: Pick right version of clink
@if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set architecture=86
) else (
    set architecture=64
)
:: Run clink
@%CMDER_ROOT%\vendor\clink\clink_x%architecture%.exe inject --quiet --profile %CMDER_ROOT%\config

:: Prepare for msysgit

:: I do not even know, copypasted from their .bat
@set PLINK_PROTOCOL=ssh
@if not defined TERM set TERM=msys

:: Enhance Path
@set git_install_root=%CMDER_ROOT%\vendor\msysgit
@set PATH=%PATH%;%CMDER_ROOT%\bin;%git_install_root%\bin;%git_install_root%\mingw\bin;%git_install_root%\cmd;%git_install_root%\share\vim\vim73;

@call %CMDER_ROOT%\bin\genpath.bat

:: Add aliases
@doskey /macrofile="%CMDER_ROOT%\config\aliases"

:: Set home path
@set HOME=%USERPROFILE%
@echo Welcome to cmder!
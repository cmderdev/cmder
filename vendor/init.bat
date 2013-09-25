:: Set prompt style
@for /f "tokens=2 delims=:." %%x in ('chcp') do @set cp=%%x

:: The slow part
:: World without Unicode is a sad world
@chcp 65001>nul
:: It has to be lambda, I already made a logo
@prompt $E[1;32;40m$P $_$E[1;30;40mλ $E[0m
@chcp %cp%>nul

:: Pick right version of clink
@if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set architecture=86
) else (
    set architecture=64
)

:: Run clink
@vendor\clink\clink_x%architecture%.exe inject --quiet --profile config

:: Prepare for msysgit
@if not exist "%HOME%" @set HOME=%HOMEDRIVE%%HOMEPATH%
@if not exist "%HOME%" @set HOME=%USERPROFILE%
@set PLINK_PROTOCOL=ssh
@if not defined TERM set TERM=msys

:: Enhance Path
@set rootDir=%CD%
@set git_install_root=%CD%\vendor\PortableGit
@set PATH=%PATH%;%rootDir%\bin;%git_install_root%\bin;%git_install_root%\mingw\bin;%git_install_root%\cmd;

:: Add aliases
@doskey /macrofile=%rootDir%\config\aliases

:: cd into users homedir
@cd /d "%userprofile%"

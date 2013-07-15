@echo off

:: Set prompt style
prompt $E[1;32;40m$P $_$E[1;30;40m$$ $E[0m

:: Pick right version of clink
if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set architecture=86
) else (
    set architecture=64
)

:: Run clink
vendor\clink\clink_x%architecture%.exe inject --quiet --profile config

:: Enhance Path
PATH=%PATH%;%CD%\bin

:: cd into users homedir
cd /d "%userprofile%"
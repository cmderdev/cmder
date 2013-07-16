@echo off
echo %* >> %~dp0..\config\aliases
doskey /macrofile=%~dp0..\config\aliases
echo Alias created

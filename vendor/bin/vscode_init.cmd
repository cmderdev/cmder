@echo off
IF [%1] == [] (
    REM -- manually opened console (Ctrl + Shift + `) --
    CALL "%~dp0..\init.bat"
) ELSE (
    REM -- task --
    CALL cmd %*
    exit
)

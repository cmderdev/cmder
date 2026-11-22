@echo off
call "%~dp0lib\lib_git_shell.cmd" initialize bash start_git_bash

%print_debug% start_git_bash "Launching shell."
if defined shellCmd if defined ConEmuDir "%gitCmd%" --no-cd %gitCommand% "%shellCmd%" --login -i
if defined shellCmd if not defined ConEmuDir "%shellCmd%" --login -i

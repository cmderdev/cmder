@echo off
call "%~dp0lib\lib_git_shell.cmd" initialize mintty start_git_mintty

%print_debug% start_git_mintty "Launching Mintty."
if defined shellCmd "%shellCmd%" /bin/bash -l -i

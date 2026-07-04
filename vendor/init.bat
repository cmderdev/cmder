@echo off
rem Cmder init.cmd compatibility shim, do not delete this file it is a part of the Cmder package and will be recreated on update of Cmder.
echo Cmder's cmd startup script has moved from "%~f0" to "%~dp0init.cmd".
echo Please update your Cmder task or shell configuration to call "%~dp0init.cmd" directly.

call "%~dp0init.cmd" %*

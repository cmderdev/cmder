@echo off
set excd=%*
set excd=%excd:"=%
set excd_param=/d
if /i "%excd:~0,2%"=="/d" set "excd=%excd:~2%"
if "%excd:~0,1%"=="~" (set excd=%userprofile%\%excd:~1%)
if "%excd:~0,1%"=="/" (set excd_param=)
cd %excd_param% %excd%

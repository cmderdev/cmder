::http://support.microsoft.com/kb/2570538
::http://robrelyea.wordpress.com/2007/07/13/may-be-helpful-ngen-exe-executequeueditems/

if "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto 64BIT

%windir%\microsoft.net\framework\v4.0.30319\ngen.exe update /force /queue > NUL
%windir%\microsoft.net\framework\v4.0.30319\ngen.exe executequeueditems > NUL

exit 0

:64BIT
%windir%\microsoft.net\framework\v4.0.30319\ngen.exe update /force /queue > NUL
%windir%\microsoft.net\framework64\v4.0.30319\ngen.exe update /force /queue > NUL
%windir%\microsoft.net\framework\v4.0.30319\ngen.exe executequeueditems > NUL
%windir%\microsoft.net\framework64\v4.0.30319\ngen.exe executequeueditems > NUL

exit 0

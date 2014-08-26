:: Init Script for cmd.exe
:: Sets some nice defaults
:: Created as part of cmder project

:: Find root dir
@if not defined CMDER_ROOT (
    for /f %%i in ("%ConEmuDir%\..\..") do @set CMDER_ROOT=%%~fi
)

:: Change the prompt style
:: Mmm tasty lamb
@prompt $E[1;32;40m$P$S{git}$S$_$E[1;30;40m{lamb}$S$E[0m

:: Pick right version of clink
@if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set architecture=86
) else (
    set architecture=64
)

:: Run clink
@"%CMDER_ROOT%\vendor\clink\clink_x%architecture%.exe" inject --quiet --profile "%CMDER_ROOT%\config"

:: Add Cmder to the path
@set PATH=%CMDER_ROOT%;%PATH%

:: Prepare for msysgit

:: I do not even know, copypasted from their .bat
@set PLINK_PROTOCOL=ssh
@if not defined TERM set TERM=cygwin

:: Check if msysgit is installed
@if exist "%ProgramFiles%\Git" (
	set "git_install_root=%ProgramFiles%\Git"
) else if exist "%ProgramFiles(x86)%\Git" (
    set "git_install_root=%ProgramFiles(x86)%\Git"
) else if exist "%CMDER_ROOT%\vendor" (
    set "git_install_root=%VENDOR_ROOT%\git"
)

:: Add msysgit to the path
@if defined git_install_root (
    set "PATH=%git_install_root%\bin;%git_install_root%\cmd;%git_install_root%\share\vim\vim74;%PATH%"
    if not defined SVN_SSH set "SVN_SSH=%GIT_ROOT:\=\\%\\bin\\ssh.exe"
)

:: Finish by adding the bin directory to the path
@set PATH=%CMDER_ROOT%\bin;%PATH%

:: Add aliases
@doskey /macrofile="%CMDER_ROOT%\config\aliases"

:: Set home path
@if not defined HOME set HOME=%USERPROFILE%

@if defined CMDER_START (
    @cd /d "%CMDER_START%"
) else (
    @if "%CD%\" == "%CMDER_ROOT%" (
        @cd /d "%HOME%"
    )
)

:: Init Script for cmd.exe
:: Sets some nice defaults
:: Created as part of cmder project

:: !!! THIS FILE IS OVERWRITTEN WHEN CMDER IS UPDATED
:: !!! Use "%CMDER_ROOT%\config\user-startup.cmd" to add your own startup commands

:: Find root dir
@if not defined CMDER_ROOT (
    for /f "delims=" %%i in ("%ConEmuDir%\..\..") do @set CMDER_ROOT=%%~fi
)

:: Change the prompt style
:: Mmm tasty lamb
@prompt $E[1;32;40m$P$S{git}{hg}$S$_$E[1;30;40m{lamb}$S$E[0m

:: Pick right version of clink
@if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set architecture=86
) else (
    set architecture=64
)

:: Run clink
@"%CMDER_ROOT%\vendor\clink\clink_x%architecture%.exe" inject --quiet --profile "%CMDER_ROOT%\config"

:: Prepare for git-for-windows

:: I do not even know, copypasted from their .bat
@set PLINK_PROTOCOL=ssh
@if not defined TERM set TERM=cygwin

:: Check if msysgit is installed
@if exist "%ProgramFiles%\Git" (
    set "GIT_INSTALL_ROOT=%ProgramFiles%\Git"
) else if exist "%ProgramFiles(x86)%\Git" (
    set "GIT_INSTALL_ROOT=%ProgramFiles(x86)%\Git"
) else if exist "%CMDER_ROOT%\vendor" (
    set "GIT_INSTALL_ROOT=%CMDER_ROOT%\vendor\git-for-windows"
)

:: Add git to the path
@if defined GIT_INSTALL_ROOT (
    set "PATH=%GIT_INSTALL_ROOT%\bin;%GIT_INSTALL_ROOT%\usr\bin;%GIT_INSTALL_ROOT%\share\vim\vim74;%PATH%"
    :: define SVN_SSH so we can use git svn with ssh svn repositories
    if not defined SVN_SSH set "SVN_SSH=%GIT_INSTALL_ROOT:\=\\%\\bin\\ssh.exe"
)

:: Enhance Path
@set PATH=%CMDER_ROOT%\bin;%PATH%;%CMDER_ROOT%

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

@if exist "%CMDER_ROOT%\config\user-startup.cmd" (
    @rem create this file and place your own command in there
    call "%CMDER_ROOT%\config\user-startup.cmd"
) else (
    @echo Creating user startup file: "%CMDER_ROOT%\config\user-startup.cmd"
    (
    @echo :: use this file to run your own startup commands 
    @echo :: use @ in front of the command to prevent printing the command
    @echo. 
    @echo :: @call "%GIT_INSTALL_ROOT%/cmd/start-ssh-agent.cmd
    @echo :: @set PATH=%%CMDER_ROOT%%\vendor\whatever;%%PATH%%
    @echo. 
    ) > "%CMDER_ROOT%\config\user-startup.cmd"
)

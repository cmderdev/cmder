@echo off

:: Init Script for cmd.exe
:: Created as part of cmder project

:: !!! THIS FILE IS OVERWRITTEN WHEN CMDER IS UPDATED
:: !!! Use "%CMDER_ROOT%\config\user-profile.cmd" to add your own startup commands

:: Find root dir
if not defined CMDER_ROOT (
    for /f "delims=" %%i in ("%ConEmuDir%\..\..") do set "CMDER_ROOT=%%~fi"
)

:: Remove trailing '\'
if "%CMDER_ROOT:~-1%" == "\" SET "CMDER_ROOT=%CMDER_ROOT:~0,-1%"

:: Change the prompt style
:: Mmm tasty lamb
prompt $E[1;32;40m$P$S{git}{hg}$S$_$E[1;30;40m{lamb}$S$E[0m

:: Pick right version of clink
if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set architecture=86
) else (
    set architecture=64
)

:: Tell the user about the clink config files...
if not exist "%CMDER_ROOT%\config\settings" (
    echo Generating clink initial settings in "%CMDER_ROOT%\config\settings"
    echo Additional *.lua files in "%CMDER_ROOT%\config" are loaded on startup.
)

:: Run clink
"%CMDER_ROOT%\vendor\clink\clink_x%architecture%.exe" inject --quiet --profile "%CMDER_ROOT%\config" --scripts "%CMDER_ROOT%\vendor"

:: Prepare for git-for-windows

:: I do not even know, copypasted from their .bat
set PLINK_PROTOCOL=ssh
if not defined TERM set TERM=cygwin

:: The idea:
:: * if the users points as to a specific git, use that
:: * test if a git is in path and if yes, use that
:: * last, use our vendored git
:: also check that we have a recent enough version of git (e.g. test for GIT\cmd\git.exe)
if defined GIT_INSTALL_ROOT (
    if exist "%GIT_INSTALL_ROOT%\cmd\git.exe" (goto :FOUND_GIT)
)

:: check if git is in path...
setlocal enabledelayedexpansion
for /F "delims=" %%F in ('where git.exe') do @(
    pushd %%~dpF
    cd ..
    set "test_dir=!CD!"
    popd
    if exist "!test_dir!\cmd\git.exe" (
        set "GIT_INSTALL_ROOT=!test_dir!"
        set test_dir=
        goto :FOUND_GIT
    ) else (
        echo Found old git version in "!test_dir!", but not using...
        set test_dir=
    )
)

:: our last hope: our own git...
:VENDORED_GIT
if exist "%CMDER_ROOT%\vendor\git-for-windows" (
    set "GIT_INSTALL_ROOT=%CMDER_ROOT%\vendor\git-for-windows"
    rem add the minimal git commands to the front of the path
    set "PATH=%GIT_INSTALL_ROOT%\cmd;%PATH%"
) else (
    goto :NO_GIT
)

:FOUND_GIT
:: Add git to the path
if defined GIT_INSTALL_ROOT (
    rem add the unix commands at the end to not shadow windows commands like more
    echo Enhancing PATH with unix commands from git in "%GIT_INSTALL_ROOT%\usr\bin"
    set "PATH=%PATH%;%GIT_INSTALL_ROOT%\usr\bin;%GIT_INSTALL_ROOT%\usr\share\vim\vim74"
    :: define SVN_SSH so we can use git svn with ssh svn repositories
    if not defined SVN_SSH set "SVN_SSH=%GIT_INSTALL_ROOT:\=\\%\\bin\\ssh.exe"
)

:NO_GIT
endlocal & set "PATH=%PATH%" & set "SVN_SSH=%SVN_SSH%" & set "GIT_INSTALL_ROOT=%GIT_INSTALL_ROOT%"

:: Enhance Path
set "PATH=%CMDER_ROOT%\bin;%PATH%;%CMDER_ROOT%\"

:: Drop *.bat and *.cmd files into "%CMDER_ROOT%\config\profile.d"
:: to run them at startup.
if not exist "%CMDER_ROOT%\config\profile.d" (
  mkdir "%CMDER_ROOT%\config\profile.d"
)

pushd "%CMDER_ROOT%\config\profile.d"
for /f "usebackq" %%x in ( `dir /b *.bat *.cmd 2^>nul` ) do (
  REM echo Calling "%CMDER_ROOT%\config\profile.d\%%x"...
  call "%CMDER_ROOT%\config\profile.d\%%x"
)
popd

:: Allows user to override default aliases store using profile.d
:: scripts run above.  Note: If overriding default aliases file
:: in profile.d the aliases must also be loaded in profile.d.
set "user-aliases=%CMDER_ROOT%\config\user-aliases.cmd"
if not defined aliases (
  set "aliases=%user-aliases%"
)

:: make sure we have an example file
if not exist "%user-aliases%" (
   echo Creating intial user-aliases store in "%user-aliases%"...
   copy "%CMDER_ROOT%\vendor\user-aliases.cmd.example" "%user-aliases%"
)

:: Update old 'user-aliases' to new self executing 'user-aliases.cmd'
if exist "%CMDER_ROOT%\config\aliases" (
  echo Updating old "%CMDER_ROOT%\config\aliases" to new format...
  type "%CMDER_ROOT%\config\aliases" >> "%user-aliases%" && del "%CMDER_ROOT%\config\aliases"
)

:: Add aliases to the environment
call "%user-aliases%"

:: See vendor\git-for-windows\README.portable for why we do this
:: Basically we need to execute this post-install.bat because we are
:: manually extracting the archive rather than executing the 7z sfx
if exist "%CMDER_ROOT%\vendor\git-for-windows\post-install.bat" (
    echo Running Git for Windows one time Post Install....
    cd /d "%CMDER_ROOT%\vendor\git-for-windows\"
    "%CMDER_ROOT%\vendor\git-for-windows\git-bash.exe" --no-needs-console --hide --no-cd --command=post-install.bat
    cd /d %USERPROFILE%
)

:: Set home path
if not defined HOME set "HOME=%USERPROFILE%"

:: This is either a env variable set by the user or the result of
:: cmder.exe setting this variable due to a commandline argument or a "cmder here"
if defined CMDER_START (
    cd /d "%CMDER_START%"
)


if exist "%CMDER_ROOT%\config\user-profile.cmd" (
    rem create this file and place your own command in there
    call "%CMDER_ROOT%\config\user-profile.cmd"
) else (
    echo Creating user startup file: "%CMDER_ROOT%\config\user-profile.cmd"
    (
    echo :: use this file to run your own startup commands
    echo :: use  in front of the command to prevent printing the command
    echo.
    echo :: call "%%GIT_INSTALL_ROOT%%/cmd/start-ssh-agent.cmd"
    echo :: set "PATH=%%CMDER_ROOT%%\vendor\whatever;%%PATH%%"
    echo.
    ) > "%CMDER_ROOT%\config\user-profile.cmd"
)

@echo off

:: Init Script for cmd.exe
:: Created as part of cmder project

:: !!! THIS FILE IS OVERWRITTEN WHEN CMDER IS UPDATED
:: !!! Use "%CMDER_ROOT%\config\user-profile.cmd" to add your own startup commands

:: Set to > 0 for verbose output to aid in debugging.
if not defined verbose-output ( set verbose-output=0 )

:: Find root dir
if not defined CMDER_ROOT (
    if defined ConEmuDir (
        for /f "delims=" %%i in ("%ConEmuDir%\..\..") do set "CMDER_ROOT=%%~fi"
    ) else (
        for /f "delims=" %%i in ("%~dp0\..") do set "CMDER_ROOT=%%~fi"
    )
)

:: Remove trailing '\'
if "%CMDER_ROOT:~-1%" == "\" SET "CMDER_ROOT=%CMDER_ROOT:~0,-1%"

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
:: also check that we have a recent enough version of git by examining the version string
if defined GIT_INSTALL_ROOT (
    if exist "%GIT_INSTALL_ROOT%\cmd\git.exe" (goto :FOUND_GIT)
)

:: get the version information for vendored git binary
setlocal enabledelayedexpansion
call :read_version VENDORED "%CMDER_ROOT%\vendor\git-for-windows\cmd"

:: check if git is in path...
setlocal enabledelayedexpansion
for /F "delims=" %%F in ('where git.exe 2^>nul') do @(

    :: get the absolute path to the user provided git binary
    pushd %%~dpF
    set "test_dir=!CD!"
    popd

    :: get the version information for the user provided git binary
    setlocal enabledelayedexpansion
    call :read_version USER !test_dir!

    if !errorlevel! geq 0 (

        :: compare the user git version against the vendored version
        setlocal enabledelayedexpansion
        call :compare_versions USER VENDORED

        :: use the user provided git if its version is greater than, or equal to the vendored git
        if !errorlevel! geq 0 (
            set "GIT_INSTALL_ROOT=!test_dir!"
            set test_dir=
            goto :FOUND_GIT
        ) else (
            echo Found old !GIT_VERSION_USER! in "!test_dir!", but not using...
            set test_dir=
        )

    ) else (

        :: if the user provided git executable is not found
        if !errorlevel! equ -255 (
            echo No git at "!git_executable!" found.
            set test_dir=
        )

    )

)

:: our last hope: our own git...
:VENDORED_GIT
if exist "%CMDER_ROOT%\vendor\git-for-windows" (
    set "GIT_INSTALL_ROOT=%CMDER_ROOT%\vendor\git-for-windows"
    call :verbose-output Add the minimal git commands to the front of the path
    set "PATH=!GIT_INSTALL_ROOT!\cmd;%PATH%"
) else (
    goto :NO_GIT
)

:FOUND_GIT
:: Add git to the path
if defined GIT_INSTALL_ROOT (
    call :git-path 64 || call :git-path 32
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
  call :verbose-output Calling "%CMDER_ROOT%\config\profile.d\%%x"...
  call "%CMDER_ROOT%\config\profile.d\%%x"
)
popd

:: Allows user to override default aliases store using profile.d
:: scripts run above by setting the 'aliases' env variable.
::
:: Note: If overriding default aliases store file the aliases
:: must also be self executing, see '.\user-aliases.cmd.example',
:: and be in profile.d folder.
set "user-aliases=%CMDER_ROOT%\config\user-aliases.cmd"

:: The aliases environment variable is used by alias.bat to id
:: the default file to store new aliases in.
if not defined aliases (
  set "aliases=%user-aliases%"
)

:: Make sure we have a self-extracting user-aliases.cmd file
setlocal enabledelayedexpansion
if not exist "%user-aliases%" (
    echo Creating initial user-aliases store in "%user-aliases%"...
    copy "%CMDER_ROOT%\vendor\user-aliases.cmd.example" "%user-aliases%"
) else (
    type "%user-aliases%" | findstr /i ";= Add aliases below here" >nul
    if "!errorlevel!" == "1" (
        echo Creating initial user-aliases store in "%user-aliases%"...
        copy "%CMDER_ROOT%\%user-aliases%" "%user-aliases%.old_format"
        copy "%CMDER_ROOT%\vendor\user-aliases.cmd.example" "%user-aliases%"
    )
)

:: Update old 'user-aliases' to new self executing 'user-aliases.cmd'
if exist "%CMDER_ROOT%\config\aliases" (
  echo Updating old "%CMDER_ROOT%\config\aliases" to new format...
  type "%CMDER_ROOT%\config\aliases" >> "%user-aliases%" && del "%CMDER_ROOT%\config\aliases"
) else if exist "%user-aliases%.old_format" (
  echo Updating old "%user-aliases%" to new format...
  type "%user-aliases%.old_format" >> "%user-aliases%" && del "%user-aliases%.old_format"
)
endlocal
:: Add aliases to the environment
call "%user-aliases%"

:: See vendor\git-for-windows\README.portable for why we do this
:: Basically we need to execute this post-install.bat because we are
:: manually extracting the archive rather than executing the 7z sfx
if exist "%CMDER_ROOT%\vendor\git-for-windows\post-install.bat" (
    call :verbose-output Running Git for Windows one time Post Install....
    pushd "%CMDER_ROOT%\vendor\git-for-windows\"
    "%CMDER_ROOT%\vendor\git-for-windows\git-bash.exe" --no-needs-console --hide --no-cd --command=post-install.bat
    popd
)

:: Set home path
if not defined HOME set "HOME=%USERPROFILE%"

if exist "%CMDER_ROOT%\config\user-profile.cmd" (
    REM Create this file and place your own command in there
    call "%CMDER_ROOT%\config\user-profile.cmd"
) else (
    echo Creating user startup file: "%CMDER_ROOT%\config\user-profile.cmd"
    (
    echo :: use this file to run your own startup commands
    echo :: use  in front of the command to prevent printing the command
    echo.
    echo :: uncomment this to have the ssh agent load when cmder starts
    echo :: call "%%GIT_INSTALL_ROOT%%/cmd/start-ssh-agent.cmd"
    echo.
    echo :: uncomment this next two lines to use pageant as the ssh authentication agent
    echo :: SET SSH_AUTH_SOCK=/tmp/.ssh-pageant-auth-sock
    echo :: call "%%GIT_INSTALL_ROOT%%/cmd/start-ssh-pageant.cmd"
    echo.
    echo :: you can add your plugins to the cmder path like so
    echo :: set "PATH=%%CMDER_ROOT%%\vendor\whatever;%%PATH%%"
    echo.
    ) > "%CMDER_ROOT%\config\user-profile.cmd"
)

exit /b

::
:: sub-routines below here
::
:verbose-output
    if %verbose-output% gtr 0 echo %*
    exit /b

goto :eof

::
:: Enhancing PATH with unix commands from git
::
:git-path

    if exist "%GIT_INSTALL_ROOT%\mingw%1\bin" (
        call :verbose-output Enhancing PATH with unix commands from git in "%GIT_INSTALL_ROOT%\mingw%1\bin", "%GIT_INSTALL_ROOT%\usr\bin"
        set "PATH=%PATH%;%GIT_INSTALL_ROOT%\mingw%1\bin;%GIT_INSTALL_ROOT%\usr\bin;%GIT_INSTALL_ROOT%\usr\share\vim\vim74"
        exit /b 0
    ) else (
        exit /b 1
    )

goto :eof

::
:: specific to git version comparing
::
:read_version

    :: clear the variables
    set GIT_VERSION_%~1=

    :: set the executable path
    set "git_executable=%~2\git.exe"

    :: check if the executable actually exists
    if not exist "%git_executable%" (
        :: return a negative error code if the executable doesn't exist
        exit /b -255
    )

    :: get the git version in the provided directory
    for /F "delims=" %%F in ('%git_executable% --version 2^>nul') do @(
        set "GIT_VERSION_%~1=%%F"
    )

    :: parse the returned string
    call :validate_version "%~1" !GIT_VERSION_%~1!

goto :eof

:parse_version

    :: process a `git version x.x.x.xxxx.x` formatted string
    for /F "tokens=1-3* delims=.,-" %%A in ("%2") do (
        set "%~1_MAJOR=%%A"
        set "%~1_MINOR=%%B"
        set "%~1_PATCH=%%C"
        set "%~1_BUILD=%%D"
    )

goto :eof

:validate_version

    :: check if we have a valid version string
    if /I "%~2 %~3"=="GIT VERSION" (

        :: now parse the version information into the corresponding variables
        call :parse_version %~1 %~4

        :: ... and maybe display it, for debugging purposes.
        call :verbose-output Found Git Version for %~1: !%~1_MAJOR!.!%~1_MINOR!.!%~1_PATCH!.!%~1_BUILD!

    ) else (
        :: invalid format returned, use the vendored git instead
        echo Invalid git version at "%git_executable%" detected!
        call :verbose-output Returned version: %~2 %~3 %~4

        rem or directly call the VENDORED_GIT
        set test_dir=
        exit /b -127
    )

goto :eof

:compare_versions

    :: checks all major, minor, patch and build variables for the given arguments.
    :: whichever binary that has the most recent version will be used based on the return code.

    :: call :verbose-output Comparing:
    :: call :verbose-output %~1: !%~1_MAJOR!.!%~1_MINOR!.!%~1_PATCH!.!%~1_BUILD!
    :: call :verbose-output %~2: !%~2_MAJOR!.!%~2_MINOR!.!%~2_PATCH!.!%~2_BUILD!

    if !%~1_MAJOR! GTR !%~2_MAJOR! (exit /b  1)
    if !%~1_MAJOR! LSS !%~2_MAJOR! (exit /b -1)

    if !%~1_MINOR! GTR !%~2_MINOR! (exit /b  1)
    if !%~1_MINOR! LSS !%~2_MINOR! (exit /b -1)

    if !%~1_PATCH! GTR !%~2_PATCH! (exit /b  1)
    if !%~1_PATCH! LSS !%~2_PATCH! (exit /b -1)

    if !%~1_BUILD! GTR !%~2_BUILD! (exit /b  1)
    if !%~1_BUILD! LSS !%~2_BUILD! (exit /b -1)

    :: looks like we have the same versions.
    exit /b 0

goto :eof

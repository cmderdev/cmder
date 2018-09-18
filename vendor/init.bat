@echo off

:: Init Script for cmd.exe
:: Created as part of cmder project

:: !!! THIS FILE IS OVERWRITTEN WHEN CMDER IS UPDATED
:: !!! Use "%CMDER_ROOT%\config\user_profile.cmd" to add your own startup commands

:: Use /v command line arg or set to > 0 for verbose output to aid in debugging.
set verbose_output=0
set debug_output=0
set max_depth=1

:: Find root dir
if not defined CMDER_ROOT (
    if defined ConEmuDir (
        for /f "delims=" %%i in ("%ConEmuDir%\..\..") do (
            set "CMDER_ROOT=%%~fi"
        )
    ) else (
        for /f "delims=" %%i in ("%~dp0\..") do (
            set "CMDER_ROOT=%%~fi"
        )
    )
)

:: Remove trailing '\' from %CMDER_ROOT%
if "%CMDER_ROOT:~-1%" == "\" SET "CMDER_ROOT=%CMDER_ROOT:~0,-1%"

call "%cmder_root%\vendor\lib\lib_base"
call "%cmder_root%\vendor\lib\lib_path"
call "%cmder_root%\vendor\lib\lib_console"
call "%cmder_root%\vendor\lib\lib_git"
call "%cmder_root%\vendor\lib\lib_profile"

:var_loop
    if "%~1" == "" (
        goto :start
    ) else if /i "%1"=="/v" (
        set verbose_output=1
    ) else if /i "%1"=="/d" (
        set debug_output=1
    ) else if /i "%1" == "/max_depth" (
        if "%~2" geq "1" if "%~2" leq "5" (
            set "max_depth=%~2"
            shift
        ) else (
            %lib_console% show_error "'/max_depth' requires a number between 1 and 5!"
            exit /b
        )
    ) else if /i "%1" == "/c" (
        if exist "%~2" (
            if not exist "%~2\bin" mkdir "%~2\bin"
            set "cmder_user_bin=%~2\bin"
            if not exist "%~2\config\profile.d" mkdir "%~2\config\profile.d"
            set "cmder_user_config=%~2\config"
            shift
        )
    ) else if /i "%1" == "/user_aliases" (
        if exist "%~2" (
            set "user_aliases=%~2"
            shift
        )
    ) else if /i "%1" == "/git_install_root" (
        if exist "%~2" (
            set "GIT_INSTALL_ROOT=%~2"
            shift
        ) else (
            %lib_console% show_error "The Git install root folder "%~2", you specified does not exist!"
            exit /b
        )
    ) else if /i "%1" == "/home" (
        if exist "%~2" (
            set "HOME=%~2"
            shift
        ) else (
            %lib_console% show_error The home folder "%2", you specified does not exist!
            exit /b
        )
    ) else if /i "%1" == "/svn_ssh" (
        set SVN_SSH=%2
        shift
    )
    shift
goto var_loop

:start
:: Sets CMDER_SHELL, CMDER_CLINK, CMDER_ALIASES
%lib_base% cmder_shell
%lib_console% debug_output init.bat "Env Var - CMDER_ROOT=%CMDER_ROOT%"
%lib_console% debug_output init.bat "Env Var - debug_output=%debug_output%"

if defined CMDER_USER_CONFIG (
    %lib_console% debug_output init.bat "CMDER IS ALSO USING INDIVIDUAL USER CONFIG FROM '%CMDER_USER_CONFIG%'!"
)

:: Pick right version of clink
if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set architecture=86
    set architecture_bits=32
) else (
    set architecture=64
    set architecture_bits=64
)

if "%CMDER_CLINK%" == "1" (
  %lib_console% verbose_output "Injecting Clink!"

  :: Run clink
  if defined CMDER_USER_CONFIG (
    if not exist "%CMDER_USER_CONFIG%\settings" (
      echo Generating clink initial settings in "%CMDER_USER_CONFIG%\settings"
      echo Additional *.lua files in "%CMDER_USER_CONFIG%" are loaded on startup.\
    )
    "%CMDER_ROOT%\vendor\clink\clink_x%architecture%.exe" inject --quiet --profile "%CMDER_USER_CONFIG%" --scripts "%CMDER_ROOT%\vendor"
  ) else (
    if not exist "%CMDER_ROOT%\config\settings" (
      echo Generating clink initial settings in "%CMDER_ROOT%\config\settings"
      echo Additional *.lua files in "%CMDER_ROOT%\config" are loaded on startup.
    )
    "%CMDER_ROOT%\vendor\clink\clink_x%architecture%.exe" inject --quiet --profile "%CMDER_ROOT%\config" --scripts "%CMDER_ROOT%\vendor"
  )
) else (
  %lib_console% verbose_output "WARNING: Incompatible 'ComSpec/Shell' Detetected Skipping Clink Injection!"
)

:: Prepare for git-for-windows

:: I do not even know, copypasted from their .bat
set PLINK_PROTOCOL=ssh
if not defined TERM set TERM=cygwin

:: The idea:
:: * if the users points as to a specific git, use that
:: * test if a git is in path and if yes, use that
:: * last, use our vendored git
:: also check that we have a recent enough version of git by examining the version string
setlocal enabledelayedexpansion
if defined GIT_INSTALL_ROOT (
    if exist "%GIT_INSTALL_ROOT%\cmd\git.exe" goto :SPECIFIED_GIT
)

%lib_console% debug_output init.bat "Looking for Git install root..."

:: get the version information for vendored git binary
%lib_git% read_version VENDORED "%CMDER_ROOT%\vendor\git-for-windows\cmd"
%lib_git% validate_version VENDORED %GIT_VERSION_VENDORED%

:: check if git is in path...
for /F "delims=" %%F in ('where git.exe 2^>nul') do (
    :: get the absolute path to the user provided git binary
    pushd %%~dpF
    set "test_dir=!CD!"
    popd

    :: get the version information for the user provided git binary
    %lib_git% read_version USER "!test_dir!"
    %lib_git% validate_version USER !GIT_VERSION_USER!

    if !errorlevel! geq 0 (
        :: compare the user git version against the vendored version
        %lib_git% compare_versions USER VENDORED

        :: use the user provided git if its version is greater than, or equal to the vendored git
        if !errorlevel! geq 0 if exist "!test_dir:~0,-4!\cmd\git.exe" (
            set "GIT_INSTALL_ROOT=!test_dir:~0,-4!"
            set test_dir=
            goto :FOUND_GIT
        ) else if !errorlevel! geq 0 (
            set "GIT_INSTALL_ROOT=!test_dir!"
            set test_dir=
            goto :FOUND_GIT
        ) else (
            call :verbose_output Found old !GIT_VERSION_USER! in "!test_dir!", but not using...
            set test_dir=
        )
    ) else (

        :: if the user provided git executable is not found
        if !errorlevel! equ -255 (
            call :verbose_output No git at "!git_executable!" found.
            set test_dir=
        )

    )
)

:: our last hope: our own git...
:VENDORED_GIT
if exist "%CMDER_ROOT%\vendor\git-for-windows" (
    set "GIT_INSTALL_ROOT=%CMDER_ROOT%\vendor\git-for-windows"
    %lib_console% debug_output "Using vendored Git from '!GIT_INSTALL_ROOT!..."
    %lib_path% enhance_path "!GIT_INSTALL_ROOT!\cmd"
    goto :CONFIGURE_GIT
) else (
    goto :NO_GIT
)

:SPECIFIED_GIT
%lib_console% debug_output "Using /GIT_INSTALL_ROOT from '%GIT_INSTALL_ROOT%..."
goto :CONFIGURE_GIT

:FOUND_GIT
%lib_console% debug_output "Using found Git from '%GIT_INSTALL_ROOT%..."
goto :CONFIGURE_GIT

:CONFIGURE_GIT
:: Add git to the path
if defined GIT_INSTALL_ROOT (
    rem add the unix commands at the end to not shadow windows commands like more
    if exist "!GIT_INSTALL_ROOT!\cmd\git.exe" %lib_path% enhance_path "!GIT_INSTALL_ROOT!\cmd" append
    if exist "!GIT_INSTALL_ROOT!\mingw32" (
        %lib_path% enhance_path "!GIT_INSTALL_ROOT!\mingw32" append
    ) else if exist "!GIT_INSTALL_ROOT!\mingw64" (
        %lib_path% enhance_path "!GIT_INSTALL_ROOT!\mingw64" append
    )
    %lib_path% enhance_path "!GIT_INSTALL_ROOT!\usr\bin" append

    :: define SVN_SSH so we can use git svn with ssh svn repositories
    if not defined SVN_SSH set "SVN_SSH=%GIT_INSTALL_ROOT:\=\\%\\bin\\ssh.exe"

    for /F "delims=" %%F in ('env /usr/bin/locale -uU 2') do (
        set "LANG=%%F"
    )
)

endlocal & set "PATH=%PATH%" & set "LANG=%LANG%" & set "SVN_SSH=%SVN_SSH%" & set "GIT_INSTALL_ROOT=%GIT_INSTALL_ROOT%"
%lib_console% debug_output init.bat "Env Var - GIT_INSTALL_ROOT=%GIT_INSTALL_ROOT%"
%lib_console% debug_output init.bat "Found Git in: '%GIT_INSTALL_ROOT%'"
goto :PATH_ENHANCE

:NO_GIT
:: Skip this if GIT WAS FOUND else we did 'endlocal' above!
endlocal

:PATH_ENHANCE
%lib_path% enhance_path "%CMDER_ROOT%\vendor\bin"
%lib_path% enhance_path_recursive "%CMDER_ROOT%\bin" %max_depth%
if defined CMDER_USER_BIN (
  %lib_path% enhance_path_recursive "%CMDER_USER_BIN%" %max_depth%
)
%lib_path% enhance_path "%CMDER_ROOT%" append

:: Drop *.bat and *.cmd files into "%CMDER_ROOT%\config\profile.d"
:: to run them at startup.
%lib_profile% run_profile_d "%CMDER_ROOT%\config\profile.d"
if defined CMDER_USER_CONFIG (
  %lib_profile% run_profile_d "%CMDER_USER_CONFIG%\profile.d"
)

:: Allows user to override default aliases store using profile.d
:: scripts run above by setting the 'aliases' env variable.
::
:: Note: If overriding default aliases store file the aliases
:: must also be self executing, see '.\user_aliases.cmd.example',
:: and be in profile.d folder.
if not defined user_aliases (
  if defined CMDER_USER_CONFIG (
     set "user_aliases=%CMDER_USER_CONFIG%\user_aliases.cmd"
  ) else (
     set "user_aliases=%CMDER_ROOT%\config\user_aliases.cmd"
  )
)

if "%CMDER_ALIASES%" == "1" (
  REM The aliases environment variable is used by alias.bat to id
  REM the default file to store new aliases in.
  if not defined aliases (
    set "aliases=%user_aliases%"
  )

  REM Make sure we have a self-extracting user_aliases.cmd file
  setlocal enabledelayedexpansion
  if not exist "%user_aliases%" (
      echo Creating initial user_aliases store in "%user_aliases%"...
      copy "%CMDER_ROOT%\vendor\user_aliases.cmd.example" "%user_aliases%"
  ) else (
      type "%user_aliases%" | findstr /i ";= Add aliases below here" >nul
      if "!errorlevel!" == "1" (
          echo Creating initial user_aliases store in "%user_aliases%"...
          if defined CMDER_USER_CONFIG (
              copy "%user_aliases%" "%user_aliases%.old_format"
              copy "%CMDER_ROOT%\vendor\user_aliases.cmd.example" "%user_aliases%"
          ) else (
              copy "%user_aliases%" "%user_aliases%.old_format"
              copy "%CMDER_ROOT%\vendor\user_aliases.cmd.example" "%user_aliases%"
          )
      )
  )

  :: Update old 'user_aliases' to new self executing 'user_aliases.cmd'
  if exist "%CMDER_ROOT%\config\aliases" (
    echo Updating old "%CMDER_ROOT%\config\aliases" to new format...
    type "%CMDER_ROOT%\config\aliases" >> "%user_aliases%"
    del "%CMDER_ROOT%\config\aliases"
  ) else if exist "%user_aliases%.old_format" (
    echo Updating old "%user_aliases%" to new format...
    type "%user_aliases%.old_format" >> "%user_aliases%"
    del "%user_aliases%.old_format"
  )
  endlocal
)

:: Add aliases to the environment
call "%user_aliases%"

:: See vendor\git-for-windows\README.portable for why we do this
:: Basically we need to execute this post-install.bat because we are
:: manually extracting the archive rather than executing the 7z sfx
if exist "%GIT_INSTALL_ROOT%\post-install.bat" (
    %lib_console% verbose_output "Running Git for Windows one time Post Install...."
    pushd "%GIT_INSTALL_ROOT%\"
    "%GIT_INSTALL_ROOT%\git-bash.exe" --no-needs-console --hide --no-cd --command=post-install.bat
    popd
)

:: Set home path
if not defined HOME set "HOME=%USERPROFILE%"
%lib_console% debug_output init.bat "Env Var - HOME=%HOME%"

set "initialConfig=%CMDER_ROOT%\config\user_profile.cmd"
if exist "%CMDER_ROOT%\config\user_profile.cmd" (
    REM Create this file and place your own command in there
    call "%CMDER_ROOT%\config\user_profile.cmd"
)

if defined CMDER_USER_CONFIG (
  set "initialConfig=%CMDER_USER_CONFIG%\user_profile.cmd"
  if exist "%CMDER_USER_CONFIG%\user_profile.cmd" (
      REM Create this file and place your own command in there
      call "%CMDER_USER_CONFIG%\user_profile.cmd"
  )
)

if not exist "%initialConfig%" (
    echo Creating user startup file: "%initialConfig%"
    (
echo :: use this file to run your own startup commands
echo :: use in front of the command to prevent printing the command
echo.
echo :: uncomment this to have the ssh agent load when cmder starts
echo :: call "%%GIT_INSTALL_ROOT%%/cmd/start-ssh-agent.cmd"
echo.
echo :: uncomment the next two lines to use pageant as the ssh authentication agent
echo :: SET SSH_AUTH_SOCK=/tmp/.ssh-pageant-auth-sock
echo :: call "%%GIT_INSTALL_ROOT%%/cmd/start-ssh-pageant.cmd"
echo.
echo :: you can add your plugins to the cmder path like so
echo :: set "PATH=%%CMDER_ROOT%%\vendor\whatever;%%PATH%%"
echo.
echo @echo off
) >"%initialConfig%"
)

if "%CMDER_ALIASES%" == "1" if exist "%CMDER_ROOT%\bin\alias.bat" if exist "%CMDER_ROOT%\vendor\bin\alias.cmd" (
  echo Cmder's 'alias' command has been moved into '%CMDER_ROOT%\vendor\bin\alias.cmd'
  echo to get rid of this message either:
  echo.
  echo Delete the file '%CMDER_ROOT%\bin\alias.bat'
  echo.
  echo or
  echo.
  echo If you have customized it and want to continue using it instead of the included version
  echo   * Rename '%CMDER_ROOT%\bin\alias.bat' to '%CMDER_ROOT%\bin\alias.cmd'.
  echo   * Search for 'user-aliases' and replace it with 'user_aliases'.
)

set initialConfig=
set CMDER_CONFIGURED=1

exit /b

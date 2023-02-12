@echo off

:: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
:: WARNING: THIS IS UNSUPORTED CODE USE IT IF YOU WANT. SEE BELOW FOR DETAILS!
:: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
::
:: If you use this file you will be using an unsupported option you assume all
:: and responsibility for troubleshooting any issues!
::
:: ## What is this?
::
:: This file initializes the Cmder `cmd.exe` shell with hard coded settings so it is much
:: faster at loading the session config since it does not have to auto discover anything.
::
:: If you want complete control and responsibility of your Cmder setup copy this file to
:: `%CMDER_ROOT%\config\user_init.cmd` and edit to customize your setup your way.
::
:: ## Shared Cmder Installs
::
:: If using in a shared Cmder install copy to `%CMDER_ROOT%\config\user_init.cmd` or
:: `%CMDER_USER_ROOT%\config\user_init.cmd` whichever acieves the goal of the shared
:: install.
::

if "%CMDER_CLINK%" == "1" (
  goto :INJECT_CLINK
) else if "%CMDER_CLINK%" == "2" (
  goto :CLINK_FINISH
)

goto :SKIP_CLINK

:INJECT_CLINK
  %print_verbose% "Injecting Clink!"

  :: Check if Clink is not present
  if not exist "%CMDER_ROOT%\vendor\clink\clink_%clink_architecture%.exe" (
      goto :SKIP_CLINK
  )

  :: Run Clink
  if not exist "%CMDER_CONFIG_DIR%\settings" if not exist "%CMDER_CONFIG_DIR%\clink_settings" (
      echo Generating Clink initial settings in "%CMDER_CONFIG_DIR%\clink_settings"
      copy "%CMDER_ROOT%\vendor\clink_settings.default" "%CMDER_CONFIG_DIR%\clink_settings"
      echo Additional *.lua files in "%CMDER_CONFIG_DIR%" are loaded on startup.
  )

  if not exist "%CMDER_CONFIG_DIR%\cmder_prompt_config.lua" (
      echo Creating Cmder prompt config file: "%CMDER_CONFIG_DIR%\cmder_prompt_config.lua"
      copy "%CMDER_ROOT%\vendor\cmder_prompt_config.lua.default" "%CMDER_CONFIG_DIR%\cmder_prompt_config.lua"
  )

  "%CMDER_ROOT%\vendor\clink\clink_%clink_architecture%.exe" inject --quiet --profile "%CMDER_CONFIG_DIR%" --scripts "%CMDER_ROOT%\vendor"

  if errorlevel 1 (
      %print_error% "Clink initialization has failed with error code: %errorlevel%"
      goto :CLINK_FINISH
  )

  set CMDER_CLINK=2
  goto :CLINK_FINISH

:SKIP_CLINK
  %print_warning% "Skipping Clink Injection!"

  for /f "tokens=2 delims=:." %%x in ('chcp') do set cp=%%x
  chcp 65001>nul

  :: Revert back to plain cmd.exe prompt without clink
  prompt $E[1;32;49m$P$S$_$E[1;30;49mλ$S$E[0m

  chcp %cp%>nul
:CLINK_FINISH

if not defined GIT_INSTALL_ROOT set "GIT_INSTALL_ROOT=%CMDER_ROOT%\vendor\git-for-windows"
if not defined SVN_SSH          set "SVN_SSH=%GIT_INSTALL_ROOT:\=\\%\\bin\\ssh.exe"
if not defined git_locale       set git_locale="%GIT_INSTALL_ROOT%\usr\bin\locale.exe"
if not defined LANG             set LANG=en_US.UTF-8
if not defined user_aliases     set "user_aliases=%CMDER_ROOT%\config\user_aliases.cmd"
if not defined aliases          set "aliases=%user_aliases%"
if not defined HOME             set "HOME=%USERPROFILE%"

set PLINK_PROTOCOL=ssh

set "path=%GIT_INSTALL_ROOT%\cmd;%path%"

set path_position=append
if %nix_tools% equ 1 (
    set "path_position=append"
) else (
    set "path_position="
)

if %nix_tools% geq 1 (
    if exist "%GIT_INSTALL_ROOT%\mingw32" (
        if "%path_position%" == "append" (
          set "path=%path%;%GIT_INSTALL_ROOT%\mingw32\bin"
        ) else (
          set "path=%GIT_INSTALL_ROOT%\mingw32\bin;%path%"
        )
    ) else if exist "%GIT_INSTALL_ROOT%\mingw64" (
        if "%path_position%" == "append" (
          set "path=%path%;%GIT_INSTALL_ROOT%\mingw64\bin"
        ) else (
          set "path=%GIT_INSTALL_ROOT%\mingw64\bin;%path%"
        )
    )
    if exist "%GIT_INSTALL_ROOT%\usr\bin" (
        if "%path_position%" == "append" (
          set "path=%path%;%GIT_INSTALL_ROOT%\usr\bin"
        ) else (
          set "path=%GIT_INSTALL_ROOT%\usr\bin;%path%"
        )
    )
)

set "path=%CMDER_ROOT%\vendor\bin;%path%"

:USER_CONFIG_START
if %max_depth% gtr 1 (
  %lib_path% enhance_path_recursive "%CMDER_ROOT%\bin" 0 %max_depth%
) else (
  set "path=%CMDER_ROOT%\bin;%path%"
)

setlocal enabledelayedexpansion
if defined CMDER_USER_BIN (
  if %max_depth% gtr 1 (
    %lib_path% enhance_path_recursive "%CMDER_USER_BIN%" 0 %max_depth%
  ) else (
    set "path=%CMDER_USER_ROOT%\bin;%path%"
  )
)
endlocal && set "path=%path%"
 
set "path=%path%;%CMDER_ROOT%"

call "%user_aliases%"

%lib_profile% run_profile_d "%CMDER_ROOT%\config\profile.d"
if defined CMDER_USER_CONFIG (
  %lib_profile% run_profile_d "%CMDER_USER_CONFIG%\profile.d"
)

call "%CMDER_ROOT%\config\user_profile.cmd"
if defined CMDER_USER_CONFIG (
  if exist "%CMDER_USER_CONFIG%\user_profile.cmd" (
    call "%CMDER_USER_CONFIG%\user_profile.cmd"
  )
)

set "path=%path:;;=;%

:CMDER_CONFIGURED
if not defined CMDER_CONFIGURED set CMDER_CONFIGURED=1

set CMDER_INIT_END=%time%

"%cmder_root%\vendor\bin\timer.cmd" "%CMDER_INIT_START%" "%CMDER_INIT_END%"
exit /b

@echo off

SET CMDER_ROOT=%~dp0

set CMDER_TERMINAL=conemu
if exist "%CMDER_ROOT%\vendor\windows-terminal\windowsterminal.exe" (
  SET CMDER_TERMINAL=windows-terminal
)

if NOT "%~1" == "" (
  SET CMDER_TERMINAL=%~1
  shift
)

:: Remove Trailing '\'
if "%CMDER_ROOT:~-1%" == "\" SET CMDER_ROOT=%CMDER_ROOT:~0,-1%

if not exist "%CMDER_ROOT%\config" md "%CMDER_ROOT%\config" 2>nul

call :%CMDER_TERMINAL%
exit /b

:conemu
  if not exist "%CMDER_ROOT%\config\user_ConEmu.xml" (
      copy "%CMDER_ROOT%\vendor\ConEmu.xml.default" "%CMDER_ROOT%\config\user_ConEmu.xml" 1>nul
      if %errorlevel% neq 0 (
          echo ERROR: CMDER Initialization has Failed
          exit /b 1
      )
  )

  if exist "%~1" (
      start %cmder_root%\vendor\conemu-maximus5\ConEmu.exe /Icon "%CMDER_ROOT%\icons\cmder.ico" /Title Cmder /LoadCfgFile "%~1"
  ) else (
      start %cmder_root%\vendor\conemu-maximus5\ConEmu.exe /Icon "%CMDER_ROOT%\icons\cmder.ico" /Title Cmder /LoadCfgFile "%CMDER_ROOT%\config\user_ConEmu.xml"
  )
  exit /b

:windows-terminal
  if not exist "%CMDER_ROOT%\vendor\windows-terminal\settings" md "%CMDER_ROOT%\vendor\windows-terminal\settings" 2>nul
  if not exist "%CMDER_ROOT%\vendor\windows-terminal\.portable" echo "This makes this installation of Windows Terminal portable" >"%CMDER_ROOT%\vendor\windows-terminal\.portable" 2>nul

  if exist "%CMDER_ROOT%\config\user_windows_terminal_settings.json" (
      if not exist "%CMDER_ROOT%\vendor\windows-terminal\settings\settings.json" (
          echo "Copying user Windows Terminal settings to '%CMDER_ROOT%\vendor\windows-terminal\settings\settings.json'..."
          copy "%CMDER_ROOT%\config\user_windows_terminal_settings.json" "%CMDER_ROOT%\vendor\windows-terminal\settings\settings.json" 1>nul
      )
  ) else if not exist "%CMDER_ROOT%\config\user_windows_terminal_settings.json" (
    	if not exist "%CMDER_ROOT%\config" mkdir "%CMDER_ROOT%\config" 2>nul
    	echo "Copying default Windows Terminal settings to '%CMDER_ROOT%\config'..."
    	copy "%CMDER_ROOT%\vendor\windows_terminal_default_settings.json" "%CMDER_ROOT%\config\user_windows_terminal_settings.json" 1>nul
    	echo "Copying default Windows Terminal settings to '%CMDER_ROOT%\vendor\windows-terminal\settings\settings.json'..."
    	copy "%CMDER_ROOT%\vendor\windows_terminal_default_settings.json" "%CMDER_ROOT%\vendor\windows-terminal\settings\settings.json" 1>nul

      if %errorlevel% neq 0 (
          echo ERROR: CMDER Initialization has Failed
          exit /b 1
      )
  ) else if exist "%cmder_root%\vendor\windows-terminal\settings\settings.json" (
      copy "%cmder_root%\vendor\windows-terminal\settings\settings.json" "%CMDER_ROOT%\config\user_windows_terminal_settings.json"
  )

  start %cmder_root%\vendor\windows-terminal\windowsterminal.exe
  exit /b



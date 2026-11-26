@echo off

if /i "%~1"=="initialize" goto initialize
exit /b

:initialize
set "git_shell_type=%~2"
set "git_shell_label=%~3"
if not defined git_shell_label set "git_shell_label=start_git_shell"

if not defined fast_init set "fast_init=0"
if not defined verbose_output set "verbose_output=0"
if not defined debug_output set "debug_output=0"
call "%~dp0lib_console.cmd"

if not defined CMDER_ROOT (
    if defined ConEmuDir (
        for /f "delims=" %%i in ("%ConEmuDir%\..\..") do set "CMDER_ROOT=%%~fi"
    ) else (
        for /f "delims=" %%i in ("%~dp0\..\..") do set "CMDER_ROOT=%%~fi"
    )
)
%print_debug% %git_shell_label% "Cmder root: '%CMDER_ROOT%'"

set "gitCommand="
if /i "%git_shell_type%"=="bash" if defined ConEmuDir (
    set "gitCommand=--command=%ConEmuBaseDirShort%\conemu-msys2-64.exe"
)
if defined gitCommand %print_debug% %git_shell_label% "ConEmu command: '%gitCommand%'"

set "cmderExternalGitRoot="
set "gitCmd="
set "shellCmd="

if exist "%CMDER_ROOT%\vendor\git-for-windows\usr\bin\%git_shell_type%.exe" goto bundled
if exist "%ProgramFiles%\git\usr\bin\%git_shell_type%.exe" goto external_program_files
if exist "%ProgramFiles(x86)%\git\usr\bin\%git_shell_type%.exe" goto external_program_files_x86
goto set_msystem

:bundled
set "PATH=%CMDER_ROOT%\vendor\git-for-windows\usr\bin;%PATH%"
set "gitCmd=%CMDER_ROOT%\vendor\git-for-windows\git-cmd.exe"
set "shellCmd=%CMDER_ROOT%\vendor\git-for-windows\usr\bin\%git_shell_type%.exe"
%print_debug% %git_shell_label% "Using bundled Git for Windows."
for %%i in ("%CMDER_ROOT%\vendor\git-for-windows\etc\profile.d") do (
    if exist "%%~i\zz-cmder.sh" if not exist "%%~i\zz-cmder.sh\" (
        if exist "%%~i\cmder.sh" if not exist "%%~i\cmder.sh\" (
            %print_debug% %git_shell_label% "Removing legacy Bash hook: '%%~i\cmder.sh'"
            del /q "%%~i\cmder.sh"
        )
    )
)
goto set_msystem

:external_program_files
set "PATH=%ProgramFiles%\git\usr\bin;%PATH%"
set "gitCmd=%ProgramFiles%\git\git-cmd.exe"
set "shellCmd=%ProgramFiles%\git\usr\bin\%git_shell_type%.exe"
set "cmderExternalGitRoot=%ProgramFiles%\git"
%print_debug% %git_shell_label% "Using Git for Windows under Program Files."
goto setup_external

:external_program_files_x86
set "PATH=%ProgramFiles(x86)%\git\usr\bin;%PATH%"
set "gitCmd=%ProgramFiles(x86)%\git\git-cmd.exe"
set "shellCmd=%ProgramFiles(x86)%\git\usr\bin\%git_shell_type%.exe"
set "cmderExternalGitRoot=%ProgramFiles(x86)%\git"
%print_debug% %git_shell_label% "Using Git for Windows under Program Files x86."

:setup_external
if not defined cmderExternalGitRoot goto set_msystem
if exist "%cmderExternalGitRoot%\etc\profile.d\zz-cmder_exinit.sh" goto existing_external_hook
goto install_external_hook

:existing_external_hook
if not exist "%cmderExternalGitRoot%\etc\profile.d\cmder_exinit.sh" goto set_msystem

:install_external_hook
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -File "%~dp0..\setup_external_git_bash.ps1" -GitRoot "%cmderExternalGitRoot%"
if errorlevel 1 echo [%git_shell_label%] External Git setup did not complete. Continuing to %git_shell_type%. 1>&2

:set_msystem
%print_debug% %git_shell_label% "Git command: '%gitCmd%'"
%print_debug% %git_shell_label% "Shell executable: '%shellCmd%'"
if not defined shellCmd %print_debug% %git_shell_label% "%git_shell_type%.exe was not found."
if not defined shellCmd goto cleanup
if defined MSYSTEM goto cleanup

for %%i in ("%gitCmd%") do (
    if exist "%%~dpiucrt64\bin\git.exe" set "MSYSTEM=UCRT64"
)
for %%i in ("%gitCmd%") do if not defined MSYSTEM if exist "%%~dpimingw64\bin\git.exe" set "MSYSTEM=MINGW64"
for %%i in ("%gitCmd%") do if not defined MSYSTEM if exist "%%~dpiclangarm64\bin\git.exe" set "MSYSTEM=CLANGARM64"
for %%i in ("%gitCmd%") do if not defined MSYSTEM if exist "%%~dpimingw32\bin\git.exe" set "MSYSTEM=MINGW32"

:cleanup
set "cmderExternalGitRoot="
set "git_shell_type="
set "git_shell_label="
exit /b

@echo off

:: Find root dir

if not defined CMDER_ROOT (
    for /f "delims=" %%i in ("%~dp0\..\..") do (
        set "cmder_root=%%~fi"
    )
)

if defined cmder_user_bin (
    if exist "%cmder_user_bin%\vscode_init_args.cmd" (
        set CMDER_VSCODE_INIT_ARGS=%cmder_user_bin%\vscode_init_args.cmd
    ) else (
        echo Creating  initial "%CMDER_ROOT%\bin\vscode_init_args.cmd"...
        copy "%CMDER_ROOT%\bin\vscode_init_args.cmd.default" "%cmder_user_bin%\vscode_init_args.cmd"
    )
) else if exist "%CMDER_ROOT%\bin\vscode_init_args.cmd" (
    set CMDER_VSCODE_INIT_ARGS=%CMDER_ROOT%\bin\vscode_init_args.cmd
) else (
    echo Creating  initial "%CMDER_ROOT%\bin\vscode_init_args.cmd"...
    copy "%CMDER_ROOT%\bin\vscode_init_args.cmd.default" "%CMDER_ROOT%\bin\vscode_init_args.cmd"
)

if defined CMDER_VSCODE_INIT_ARGS (
    call "%CMDER_VSCODE_INIT_ARGS%"
)

IF [%1] == [] (
    REM -- manually opened console (Ctrl + Shift + `) --
    CALL "%~dp0..\init.bat"
) ELSE (
    REM -- task --
    CALL cmd %*
    exit
)

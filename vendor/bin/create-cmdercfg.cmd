@echo off

powershell -executionpolicy bypass -f "%cmder_root%\vendor\bin\create-cmdercfg.ps1" -shell cmd -outfile "%CMDER_CONFIG_DIR%\user_init.cmd"

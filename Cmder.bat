@echo off
SET CMDER_ROOT=%~dp0
start "%CMDER_ROOT%vendor\conemu-maximus5\ConEmu.exe" /Icon "%CMDER_ROOT%icons\cmder.ico" /Title Cmder /LoadCfgFile "%CMDER_ROOT%config\ConEmu.xml"

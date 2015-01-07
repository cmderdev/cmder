@echo off

SET CMDER_ROOT=%~dp0
if not defined CMDER_CONFIG set CMDER_CONFIG=%~dp0\config

start %~dp0/vendor/conemu-maximus5/ConEmu.exe /Icon "%CMDER_ROOT%\icons\cmder.ico" /Title Cmder /LoadCfgFile "%CMDER_CONFIG%\ConEmu.xml"

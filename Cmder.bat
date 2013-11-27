@echo off
@set rootDir=%~dp0
start %rootDir%vendor/conemu-maximus5/ConEmu.exe /Title Cmder /LoadCfgFile %rootDir%config/ConEmu.xml

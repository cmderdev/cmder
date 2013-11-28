@echo off
pushd
cd /d %~dp0
start vendor/conemu-maximus5/ConEmu.exe /Title Cmder /LoadCfgFile ../../config/ConEmu.xml
popd

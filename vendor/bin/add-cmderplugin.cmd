@echo off
pushd "%cmder_root%"
powershell -executionpolicy bypass -command "& {.\vendor\bin\add-cmderplugin.ps1 %*}"
popd

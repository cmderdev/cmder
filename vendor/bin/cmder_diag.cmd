@echo off

echo ------------------------------------
echo dir "%cmder_root%"
echo ------------------------------------
dir "%cmder_root%"

echo.
echo ------------------------------------
echo dir "%cmder_root%\vendor"
echo ------------------------------------
dir "%cmder_root%\vendor"

echo.
echo ------------------------------------
echo dir /s "%cmder_root%\bin"
echo ------------------------------------
dir /s "%cmder_root%\bin"

echo.
echo ------------------------------------
echo dir /s "%cmder_root%\config"
echo ------------------------------------
dir /s "%cmder_root%\config"

echo.
echo ------------------------------------
echo set
echo ------------------------------------
set

echo.
echo ------------------------------------
echo where git
echo ------------------------------------
where git

echo.
echo ------------------------------------
echo Make sure you sanitize this output of private data prior to posting it online for review by the CMDER Team!
echo ------------------------------------

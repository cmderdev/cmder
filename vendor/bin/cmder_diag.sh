echo ------------------------------------
echo ls -la "$CMDER_ROOT"
echo ------------------------------------
ls -la "$CMDER_ROOT"

echo ''
echo ------------------------------------
echo ls -la "$CMDER_ROOT/vendor"
echo ------------------------------------
ls -la "$CMDER_ROOT/vendor"

echo ''
echo ------------------------------------
echo ls -la /s "$CMDER_ROOT/bin"
echo ------------------------------------
ls -laR /s "$CMDER_ROOT/bin"

echo ''
echo ------------------------------------
echo ls -la /s "$CMDER_ROOT/config"
echo ------------------------------------
ls -laR /s "$CMDER_ROOT/config"

echo ''
echo ------------------------------------
echo env
echo ------------------------------------
env

echo ''
echo ------------------------------------
echo which git
echo ------------------------------------
which git

echo ''
echo ------------------------------------
echo Make sure you sanitize this output of private data prior to posting it online for review by the CMDER Team!
echo ------------------------------------

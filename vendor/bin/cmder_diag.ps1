write-host ------------------------------------
write-host get-childitem "$env:CMDER_ROOT"
write-host ------------------------------------
get-childitem "$env:CMDER_ROOT"

write-host ''
write-host ------------------------------------
write-host get-childitem "$env:CMDER_ROOT/vendor"
write-host ------------------------------------
get-childitem "$env:CMDER_ROOT/vendor"

write-host ''
write-host ------------------------------------
write-host get-childitem -s "$env:CMDER_ROOT/bin"
write-host ------------------------------------
get-childitem -s "$env:CMDER_ROOT/bin"

write-host ''
write-host ------------------------------------
write-host get-childitem -s "$env:CMDER_ROOT/config"
write-host ------------------------------------
get-childitem -s "$env:CMDER_ROOT/config"

write-host ''
write-host ------------------------------------
write-host get-childitem env:
write-host ------------------------------------
get-childitem env: |ft -autosize -wrap

write-host ''
write-host ------------------------------------
write-host get-command git
write-host ------------------------------------
get-command git

write-host ''
write-host ------------------------------------
write-host Make sure you sanitize this output of private data prior to posting it online for review by the CMDER Team!
write-host ------------------------------------

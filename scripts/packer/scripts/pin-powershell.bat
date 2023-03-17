rem https://connect.microsoft.com/PowerShell/feedback/details/1609288/pin-to-taskbar-no-longer-working-in-windows-10

set ps_link=A:\WindowsPowerShell.lnk
if exist e:\WindowsPowerShell.lnk (
  set ps_link=e:\WindowsPowerShell.lnk
)

set pin_to_10=A:\PinTo10.exe
if exist e:\PinTo10.exe (
  set pin_to_10=e:\PinTo10.exe
)


copy "%ps_link%" "%TEMP%\Windows PowerShell.lnk"
%pin_to_10% /PTFOL01:'%TEMP%' /PTFILE01:'Windows PowerShell.lnk'
exit /b 0

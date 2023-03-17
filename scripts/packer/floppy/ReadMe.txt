: Release v1.2 - Stuart Pearson 16th Nov 2015
:
: Command line tool to pin and unpin exe / lnk files to the Windows 10 taskbar and start menu.
:
: PinTo10 is a command line tool to pin and unpin .exe or .lnk files to or from the Windows 10 taskbar and start menu.
: With it you can pin or unpin up to 10 different shortcuts to either the taskbar or start menu in one run of the command.
: It replaces functionality that Microsoft have removed from their Windows 10 scripting interface.
:
: The exe needs to be run with at least one pair of switches specified for each function to Pin / Unpin to Taskbar / Start Menu...
:
: To pin an application or shortcut to the taskbar (replace XX with 01-10)...
: /PTFOLXX: Followed by the folder containing the file you want to pin.
: /PTFILEXX: Followed by the name of the file you want to pin.
:
: To unpin an application or shortcut to the taskbar (replace XX with 01-10)...
: /UTFOLXX: Followed by the folder containing the file you want to unpin.
: /UTFILEXX: Followed by the name of the file you want to unpin.

: To pin an application or shortcut to the start menu (replace XX with 01-10)...
: /PSFOLXX: Followed by the folder containing the file you want to pin.
: /PSFILEXX: Followed by the name of the file you want to pin.

: To unpin an application or shortcut to the start menu (replace XX with 01-10)...
: /USFOLXX: Followed by the folder containing the file you want to unpin.
: /USFILEXX: Followed by the name of the file you want to unpin.


: Example for pinning two shortcuts to the taskbar...
PinTo10.exe /PTFOL01:'%USERPROFILE:%\Desktop' /PTFILE01:'Word 2016.lnk' /PTFOL02:'%USERPROFILE:%\Desktop' /PTFILE02:'Excel 2016.lnk'

: Example for unpinning a file to the taskbar...
PinTo10.exe /UTFOL01:'C\Windows' /UTFILE01:'notepad.exe'

: Example for pinning a file to the start menu...
PinTo10.exe /PSFOL01:'C\Windows' /PSFILE01:'notepad.exe'

: Example for unpinning a file from the start menu...
PinTo10.exe /USFOL01:'%USERPROFILE:%\Desktop' /USFILE01:'Word 2016.lnk'
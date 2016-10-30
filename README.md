# Cmder

[![Join the chat at https://gitter.im/cmderdev/cmder](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/cmderdev/cmder?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Build Status](https://ci.appveyor.com/api/projects/status/32r7s2skrgm9ubva/branch/master?svg=true)](https://ci.appveyor.com/project/MartiUK/cmder)

Cmder is a **software package** created out of pure frustration over absence of usable console emulator on Windows. It is based on [ConEmu](https://conemu.github.io/) with *major* config overhaul, comes with a Monokai color scheme, amazing [clink](https://github.com/mridgers/clink) (further enhanced by [clink-completions](https://github.com/vladimir-kotikov/clink-completions)) and a custom prompt layout.

![Cmder Screenshot](http://i.imgur.com/g1nNf0I.png)

## Why use it

The main advantage of Cmder is portability. It is designed to be totally self-contained with no external dependencies, which makes it great for **USB Sticks** or **cloud storage**. So you can carry your console, aliases and binaries (like wget, curl and git) with you anywhere.

## Installation

1. Download the [latest release](https://github.com/cmderdev/cmder/releases/)
2. Extract the archive
3. (optional) Place your own executable files into the `bin` folder to be injected into your PATH
4. Run Cmder.exe

## Integration

So you've experimented with Cmder a little and want to give it a shot in a more permanent home;

### Shortcut to open Cmder in a chosen folder

1. Open a terminal as an Administrator
2. Navigate to the directory you have placed Cmder
3. Execute `.\cmder.exe /REGISTER ALL`
   _If you get a message "Access Denied" ensure you are executing the command in an **Administrator** prompt._

In a file explorer window right click in or on a directory to see "Cmder Here" in the context menu.

## Keyboard shortcuts

### Tab manipulation

* <kbd>Ctrl</kbd> + <kbd>T</kbd> : New tab dialog (maybe you want to open cmd as admin?)
* <kbd>Ctrl</kbd> + <kbd>W</kbd> : Close tab
* <kbd>Ctrl</kbd> + <kbd>D</kbd> : Close tab (if pressed on empty command)
* <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>#Number</kbd> : Fast new tab: <kbd>1</kbd> - CMD, <kbd>2</kbd> - PowerShell
* <kbd>Alt</kbd> + <kbd>Enter</kbd>: Fullscreen

### Shell

* <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>U</kbd> : Traverse up in directory structure (lovely feature!)
* <kbd>End</kbd>, <kbd>Home</kbd>, <kbd>Ctrl</kbd> : Traversing text with as usual on Windows
* <kbd>Ctrl</kbd> + <kbd>R</kbd> : History search
* <kbd>Shift</kbd> + Mouse : Select and copy text from buffer

(Some shortcuts are not yet documented, though they exist - please document them here)

## Features

### Access to multiple shells in one window using tabs
You can open multiple tabs each containing one of the following shells:

|Task|Shell|Description|
|----|-----|-----------|
|Cmder|cmd.exe|Windows 'cmd.exe' shell enhanced with Git, Git aware prompt, Clink(GNU Readline), and Aliases.|
|Cmder as Admin|cmd.exe|Administrative Windows 'cmd.exe' Cmder shell.|
|PowerShell|powershell.exe|Windows PowerShell enhanced with Git and Git aware prompt .|
|PowerShell as Admin|powershell.exe|Administrative Windows 'powershell.exe' Cmder shell.|
|Bash|bash.exe|Unix/Linux like bash shell running on Windows.|
|Bash as Admin|bash.exe|Administrative Unix/Linux like bash shell running on Windows.|
|Mintty|bash.exe|Unix/Linux like bash shell running on Windows. See below for Mintty configuration differences|
|Mintty as Admin|bash.exe|Administrative Unix/Linux like bash shell running on Windows. See below for Mintty configuration differences|

Cmder, PowerShell, and Bash tabs all run on top of the Windows Console API and work as you might expect in Cmder with access to use ConEmu's color schemes, key bindings and other settings defined in the ConEmu Settings dialog.

Mintty tabs use a program called 'mintty' as the terminal that is not based on the Windows Console API so some differences in functionality are normal, as a result mintty specific config is done via the '[%USERPROFILE%|$HOME]/.minttyrc' file.

Mintty differs from the other tabs in that it supports xterm/xterm-256color TERM types, and does not work with ConEmu settings like color schemes and key bindings. For more on Mintty and its config click [here](https://github.com/mintty/mintty).

An example of setting Cmder portable terminal colors for mintty:

From a bash/mintty shell:

```
cd $CMDER_ROOT/vendor
git clone https://github.com/karlin/mintty-colors-solarized.git
cd mintty-colors-solarized/
echo source \$CMDER_ROOT/vendor/mintty-colors-solarized/mintty-solarized-dark.sh>>$CMDER_ROOT/config/user-profile.sh
```

### Cmder Portable Shell User Config
User specific configuration is possible using the cmder specific shell config files.  Edit the below files to add your own configuration:

|Shell|Cmder Portable User Config|
| ------------- |:-------------:|
|Cmder|%CMDER_ROOT%\config\user-profile.cmd|
|PowerShell|$ENV:CMDER_ROOT\config\user-profile.ps1|
|Bash/Mintty|$CMDER_ROOT/config/user-profile.sh|

Note: Bash and Mintty sessions will also source the '$HOME/.bashrc' file if it exists after it sources '$CMDER_ROOT/config/user-profile.sh'.

### Linux like 'profile.d' support for all supported shell types.
You can write *.cmd|*.bat, *.ps1, and *.sh scripts and just drop them in the %CMDER_ROOT%\config\profile.d folder to add startup config to Cmder.

|Shell|Cmder 'Profile.d' Scripts|
| ------------- |:-------------:|
|Cmder|%CMDER_ROOT%\config\profile.d\\*.bat and *.cmd|
|PowerShell|$ENV:CMDER_ROOT\config\profile.d\\*.ps1|
|Bash/Mintty|$CMDER_ROOT/config/profile.d/*.sh|


### Aliases
#### Cmder(Cmd.exe) Aliases
You can define simple aliases for `cmd.exe` sessions with a command like `alias name=command`.  Cmd.exe aliases support optional parameters through the `$1-9` or the `$*` special characters so the alias `vi=vim.exe $*` typed as `vi [filename]` will open `[filename]` in `vim.exe`.

Cmd.exe aliases can also be more complex. See: [DOSKEY.EXE documentation](http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/doskey.mspx?mfr=true) for additional details on complex aliases/macros for 'cmd.exe'

Aliases defined using the `alias.bat` command will automatically be saved in the `%CMDER_ROOT%\config\aliases` file

#### Bash.exe|Mintty.exe Aliases
Bash shells support simple and complex aliases with optional parameters natively so they work a little different.  Typing `alias name=command` will create an alias only for the current running session.  To make an alias permanent add it to either your `$CMDER_ROOT/config/user-profile.sh` or your `$HOME/.bashrc`.

If you add bash aliases to `$CMDER_ROOT/config/user-profile.sh` they will be portable and follow your Cmder folder if you copy it to another machine.  `$HOME/.bashrc` defined aliases are not portable.

#### PowerShell.exe Aliases
PowerShell has native simple alias support, for example `[new-alias | set-alias] alias command`, so complex aliases with optional parameters are not supported in PowerShell sessions.  Type `get-help [new-alias|set-alias] -full` for help on PowerShell aliases.

### SSH Agent

To start SSH agent simply call `start-ssh-agent`, which is in the `vendor/git-for-windows/cmd` folder.

If you want to run SSH agent on startup, include the line `@call "%GIT_INSTALL_ROOT%/cmd/start-ssh-agent.cmd"` in `%CMDER_ROOT%/config/user-profile.cmd` (usually just uncomment it).

### Using external Cygwin/Babun, MSys2, or Git for Windows SDK with Cmder.

1. Setup a new task by pressing '<kbd>Win</kbd> +<kbd>Alt</kbd> + <kbd>T</kbd>'.
1. Click the '+' button to add a task.
1. Name the new task in the top text box.
1. Provide task parameters, this is optional.
1. Add ```cmd /c "[path_to_external_env]\bin\bash --login -i" -new_console:d:%USERPROFILE%``` to the `Commands` text box.

Recommended Optional Steps:

Copy the 'vendor/cmder_exinit' file to the Cygwin/Babun, MSys2, or Git for Windows SDK environments ```/etc/profile.d/``` folder to use portable settings in the $CMDER_ROOT/config folder.

Note: MinGW could work if the init scripts include profile.d but this has not been tested.

The destination file extension depends on the shell you use in that environment.  For example:

* bash - Copy to /etc/profile.d/cmder_exinit.sh
* zsh  - Copy to /etc/profile.d/cmder_exinit.zsh

Uncomment and edit the below line in the script to use Cmder config even when launched from outside Cmder.

```
# CMDER_ROOT=${USERPROFILE}/cmder  # This is not required if launched from Cmder.
```

## Current development branch

You can download builds of the current development branch by going to AppVeyor via the following link:

[![AppVeyor](https://ci.appveyor.com/api/projects/status/github/cmderdev/cmder?svg=True)](https://ci.appveyor.com/project/MartiUK/cmder/branch/development/artifacts)

## License

All software included is bundled with own license

The MIT License (MIT)

Copyright (c) 2016 Samuel Vasko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

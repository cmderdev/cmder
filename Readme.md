# Cmder

Latest release is **[v1.1.4.1](https://github.com/bliker/cmder/releases/tag/v1.1.4.1)**

Cmder is a **software package** created out of pure frustration over absence of usable console emulator on Windows. It is based on [ConEmu](https://code.google.com/p/conemu-maximus5/) with *major* config overhaul. Monokai color scheme, amazing [clink](https://github.com/mridgers/clink) and custom prompt layout.

![Cmder Screenshot](http://i.imgur.com/g1nNf0I.png)

## Why use it

The main advantage of Cmder is portability. It is designed to be totally self-contained with no external dependencies, that is makes it great for **USB Sticks** or **Dropbox**. So you can carry your console, aliases and binaries (like wget, curl and git) with you anywhere.

## Installation

1. Download the latest release
1. Extract
1. (optional) Place files into `bin` folder, it will be injected into your PATH.
1. Run cmder

*(There will be a version with installer)*

## Integration

So you've experimented with cmder a little and want to give it a shot in a more permanent home;

### Shortcut to open Cmder in a chosen folder

1. Open a terminal as an Administrator
1. Navigate to the directory you have placed Cmder
1. Execute `.\cmder.exe /REGISTER ALL`*

In a file explorer window right click in or on a directory to see "Cmder Here" in the context menu.

*If you get a message "Access Denied" ensure you are executing the command in an Administrator prompt.

## Keyboard shortcuts

### Tab manipulation

* `Ctrl + t` : new tab dialog (maybe you want to open cmd as admin?)
* `Ctrl + w` : close tab
* `Ctrl + d` : close tab (if pressed on empty command)
* `Shift + alt + number` : fast new tab: `1` - CMD, `2` - Powershell `*` - More to come
* `Alt + enter`: Fullscreen

### Shell

* `Shift + Up` : Traverse up in directory structure (lovely feature!)
* `End, Home, Ctrl` : Traversing text with as usual on Windows
* `Ctrl + r` : History search
* `Shift + mouse` : Select and copy text from buffer

(Some shortcuts are not yet documented, thought they exist, please add them here)

## Features

### Aliases
You can define simple aliases with command `alias name=command`.

For example there is one defined for you `alias e.=explorer .`

All aliases will be saved in `/config/aliases` file

## Todo

1. Complete PowerShell compatibility.
2. Workaround git.exe overload after msysgit download (Granted this is an upstream issue).
3. Redo Build/Pack scripts or remove them altogether.
4. Git Bash
5. Check for clink and git before injecting them

## License

All software included is bundled with own license

The MIT License (MIT)

Copyright (c) 2013 Samuel Vasko

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

# Cmder

[![Join the chat at https://gitter.im/cmderdev/cmder](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/cmderdev/cmder?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) [![Build Status](https://ci.appveyor.com/api/projects/status/github/cmderdev/cmder?branch=master&svg=true)](https://ci.appveyor.com/project/cmderdev/cmder) [![Build Status](https://github.com/cmderdev/cmder/actions/workflows/build.yml/badge.svg)](https://github.com/cmderdev/cmder/actions/workflows/build.yml)

Cmder is a **software package** created out of pure frustration over absence of usable console emulator on Windows. It is based on [ConEmu](https://conemu.github.io/) with *major* config overhaul, comes with a Monokai color scheme, amazing [clink](https://chrisant996.github.io/clink/) (further enhanced by [clink-completions](https://github.com/vladimir-kotikov/clink-completions)) and a custom prompt layout.

![Cmder Screenshot](http://i.imgur.com/g1nNf0I.png)

## Why use it

The main advantage of Cmder is portability. It is designed to be totally self-contained with no external dependencies, which makes it great for **USB Sticks** or **cloud storage**. So you can carry your console, aliases and binaries (like `wget`, `curl` and `git`) with you anywhere.

The Cmder's user interface is also designed to be more eye pleasing, and you can compare the main differences between Cmder and ConEmu [here](https://conemu.github.io/en/cmder.html).

## Installation
### Single User Portable Config

1. Download the [latest release](https://github.com/cmderdev/cmder/releases/)
2. Extract the archive. *Note: This path should not be `C:\Program Files` or anywhere else that would require Administrator access for modifying configuration files*
3. (optional) Place your own executable files into the `%cmder_root%\bin` folder to be injected into your PATH.
4. Run `Cmder.exe`

### Shared Cmder install with Non-Portable Individual User Config
1. Download the [latest release](https://github.com/cmderdev/cmder/releases/)
2. Extract the archive to a shared location.
3. (optional) Place your own executable files and custom app folders into the `%cmder_root%\bin`. See: [bin/README.md](./bin/Readme.md)
   - This folder to be injected into your PATH by default.
   - See `/max_depth [1-5]` in 'Command Line Arguments for `init.bat`' table to add subdirectories recursively.
4. (optional) Place your own custom app folders into the `%cmder_root%\opt`. See: [opt/README.md](./opt/Readme.md)
   - This folder will NOT be injected into your PATH so you have total control of what gets added.
5. Run `Cmder.exe` with `/C` command line argument. Example: `cmder.exe /C %userprofile%\cmder_config`
   * This will create the following directory structure if it is missing.

     ```
     c:\users\[username]\cmder_config
     ├───bin
     ├───config
     │   └───profile.d
     └───opt
     ```

  - (optional) Place your own executable files and custom app folders into `%userprofile%\cmder_config\bin`.
    - This folder to be injected into your PATH by default.
    - See `/max_depth [1-5]` in 'Command Line Arguments for `init.bat`' table to add subdirectories recursively.
  - (optional) Place your own custom app folders into the `%user_profile%\cmder_config\opt`.
    - This folder will NOT be injected into your PATH so you have total control of what gets added.


* Both the shared install and the individual user config locations can contain a full set of init and profile.d scripts enabling shared config with user overrides.  See below.

## Cmder.exe Command Line Arguments


| Argument                  | Description                                                                              |
| ------------------------- | -----------------------------------------------------------------------                  |
| `/C [user_root_path]`     | Individual user Cmder root folder.  Example: `%userprofile%\cmder_config`                |
| `/M`                      | Use `conemu-%computername%.xml` for ConEmu settings storage instead of `user_conemu.xml` |
| `/REGISTER [ALL, USER]`   | Register a Windows Shell Menu shortcut.                                                  |
| `/UNREGISTER [ALL, USER]` | Un-register a Windows Shell Menu shortcut.                                               |
| `/SINGLE`                 | Start Cmder in single mode.                                                              |
| `/START [start_path]`     | Folder path to start in.                                                                 |
| `/TASK [task_name]`       | Task to start after launch.                                                              |
| `/X [ConEmu extras pars]` | Forwards parameters to ConEmu                                                            |

## Context Menu Integration

So you've experimented with Cmder a little and want to give it a shot in a more permanent home;

### Shortcut to open Cmder in a chosen folder

1. Open a terminal as an Administrator
2. Navigate to the directory you have placed Cmder
3. Execute `.\cmder.exe /REGISTER ALL`
   _If you get an "Access Denied" message, make sure you are executing the command in an **Administrator** prompt._

In a file explorer window right click in or on a directory to see "Cmder Here" in the context menu.

## Keyboard shortcuts

### Tab manipulation

* <kbd>Ctrl</kbd> + <kbd>T</kbd> : New tab dialog (maybe you want to open cmd as admin?)
* <kbd>Ctrl</kbd> + <kbd>W</kbd> : Close tab
* <kbd>Ctrl</kbd> + <kbd>D</kbd> : Close tab (if pressed on empty command)
* <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>#Number</kbd> : Fast new tab: <kbd>1</kbd> - CMD, <kbd>2</kbd> - PowerShell
* <kbd>Ctrl</kbd> + <kbd>Tab</kbd> : Switch to next tab
* <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> : Switch to previous tab
* <kbd>Ctrl</kbd> + <kbd>#Number</kbd> : Switch to tab #Number
* <kbd>Alt</kbd> + <kbd>Enter</kbd>: Fullscreen

### Shell

* <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>U</kbd> : Traverse up in directory structure (lovely feature!)
* <kbd>End</kbd>, <kbd>Home</kbd>, <kbd>Ctrl</kbd> : Traversing text with as usual on Windows
* <kbd>Ctrl</kbd> + <kbd>R</kbd> : History search
* <kbd>Shift</kbd> + Mouse : Select and copy text from buffer

_(Some shortcuts are not yet documented, though they exist - please document them here)_

## Features

### Access to multiple shells in one window using tabs
You can open multiple tabs each containing one of the following shells:

| Task                | Shell            | Description                                                                                                  |
| ----                | -----            | -----------                                                                                                  |
| Cmder               | `cmd.exe`        | Windows `cmd.exe` shell enhanced with Git, Git aware prompt, Clink (GNU Readline), and Aliases.              |
| Cmder as Admin      | `cmd.exe`        | Administrative Windows `cmd.exe` Cmder shell.                                                                |
| PowerShell          | `powershell.exe` | Windows PowerShell enhanced with Git and Git aware prompt .                                                  |
| PowerShell as Admin | `powershell.exe` | Administrative Windows `powershell.exe` Cmder shell.                                                         |
| Bash                | `bash.exe`       | Unix/Linux like bash shell running on Windows.                                                               |
| Bash as Admin       | `bash.exe`       | Administrative Unix/Linux like bash shell running on Windows.                                                |
| Mintty              | `bash.exe`       | Unix/Linux like bash shell running on Windows. See below for Mintty configuration differences                |
| Mintty as Admin     | `bash.exe`       | Administrative Unix/Linux like bash shell running on Windows. See below for Mintty configuration differences |

Cmder, PowerShell, and Bash tabs all run on top of the Windows Console API and work as you might expect in Cmder with access to use ConEmu's color schemes, key bindings and other settings defined in the ConEmu Settings dialog.

⚠ *Note:* Only the full edition of Cmder comes with a pre-installed bash, using a vendored [git-for-windows](https://gitforwindows.org/) installation. The pre-configured Bash tabs may not work on Cmder mini edition without additional configuration.

You may however, choose to use an external installation of bash, such as Microsoft's [Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10) (called WSL) or the [Cygwin](https://cygwin.com/) project which provides POSIX support on windows.

⚠ *Note:* Mintty tabs use a program called 'mintty' as the terminal emulator that is not based on the Windows Console API, rather it's rendered graphically by ConEmu. Mintty differs from the other tabs in that it supports xterm/xterm-256color TERM types, and does not work with ConEmu settings like color schemes and key bindings.  As such, some differences in functionality are to be expected, such as Cmder not being able to apply a system-wide configuration to it.

As a result mintty specific config is done via the `[%USERPROFILE%|$HOME]/.minttyrc` file.  You may read more about Mintty and its config file [here](https://github.com/mintty/mintty).

An example of setting Cmder portable terminal colors for mintty:

From a bash/mintty shell:

```
cd $CMDER_ROOT/vendor
git clone https://github.com/karlin/mintty-colors-solarized.git
cd mintty-colors-solarized/
echo source \$CMDER_ROOT/vendor/mintty-colors-solarized/mintty-solarized-dark.sh>>$CMDER_ROOT/config/user_profile.sh
```

You may find some Monokai color schemes for mintty to match Cmder [here](https://github.com/oumu/mintty-color-schemes/blob/master/base16-monokai-mod.minttyrc).

### Changing Cmder Default `cmd.exe` Prompt Config File

The default Cmder shell `cmd::Cmder` prompt is customized using `Clink` and is configured by editing a config file that exists in one of two locations:

- Single User Portable Config `%CMDER_ROOT%\config\cmder_prompt_config.lua`
- Shared Cmder install with Non-Portable Individual User Config `%CMDER_USER_CONFIG%\cmder_prompt_config.lua`

If your Cmder setup does not have this file create it from `%CMDER_ROOT%\vendor\cmder_prompt_config.lua.default`

Customizations include:

- Colors.
- Single/Multi-line.
- Full path/Folder only.
- `[user]@[host]` to the beginning of the prompt.
- `~` for home directory.
- `λ` symbol

Documentation is in the file for each setting.

### Changing Cmder Default `cmd.exe` Shell Startup Behaviour Using Task Arguments

1. Press <kbd>Win</kbd> + <kbd>Alt</kbd> + <kbd>T</kbd>
1. Click either:
  * `1. {cmd::Cmder as Admin}`
  * `2. {cmd::Cmder}`
1. Add command line arguments where specified below:

  *Note: Pay attention to the quotes!*

  ```
  cmd /s /k ""%ConEmuDir%\..\init.bat" [ADD ARGS HERE]"
  ```

##### Command Line Arguments for `init.bat`

| Argument                        | Description                                                                                                                                        | Default                                |
| -----------------------------   | ----------------------------------------------------------------------------------------------                                                     | -------------------------------------  |
| `/c [user cmder root]`          | Enables user bin and config folders for 'Cmder as admin' sessions due to non-shared environment.                                                   | not set                                |
| `/d`                            | Enables debug output.                                                                                                                              | not set                                |
| `/f`                            | Enables Cmder Fast Init Mode. This disables some features, see pull request [#1492](https://github.com/cmderdev/cmder/pull/1942) for more details. | not set                                |
| `/t`                            | Enables Cmder Timed Init Mode. This displays the time taken run init scripts                                                                       | not set                                |
| `/git_install_root [file path]` | User specified Git installation root path.                                                                                                         | `%CMDER_ROOT%\vendor\Git-for-Windows`  |
| `/home [home folder]`           | User specified folder path to set `%HOME%` environment variable.                                                                                   | `%userprofile%`                        |
| `/max_depth [1-5]`              | Define max recurse depth when adding to the path for `%cmder_root%\bin` and `%cmder_user_bin%`                                                     | 1                                      |
| `/nix_tools [0-2]`              | Define how `*nix` tools are added to the path.  Prefer Windows Tools: 1, Prefer *nix Tools: 2, No `/usr/bin` in `%PATH%`: 0                        | 1                                      |
| `/svn_ssh [path to ssh.exe]`    | Define `%SVN_SSH%` so we can use git svn with ssh svn repositories.                                                                                | `%GIT_INSTALL_ROOT%\bin\ssh.exe`       |
| `/user_aliases [file path]`     | File path pointing to user aliases.                                                                                                                | `%CMDER_ROOT%\config\user_aliases.cmd` |
| `/v`                            | Enables verbose output.                                                                                                                            | not set                                |
| (custom arguments)              | User defined arguments processed by `cexec`. Type `cexec /?` for more usage.                                                                      | not set                                |

### Cmder Shell User Config
Single user portable configuration is possible using the Cmder specific shell config files.  Edit the below files to add your own configuration:

| Shell         | Cmder Portable User Config                |
| ------------- | ----------------------------------------- |
| Cmder         | `%CMDER_ROOT%\config\user_profile.cmd`    |
| PowerShell    | `$ENV:CMDER_ROOT\config\user_profile.ps1` |
| Bash/Mintty   | `$CMDER_ROOT/config/user_profile.sh`      |

**Note:** Bash and Mintty sessions will also source the `$HOME/.bashrc` file if it exists after it sources `$CMDER_ROOT/config/user_profile.sh`.

You can write `*.cmd|*.bat`, `*.ps1`, and `*.sh` scripts and just drop them in the `%CMDER_ROOT%\config\profile.d` folder to add startup config to Cmder.

| Shell         | Cmder `Profile.d` Scripts                          |
| ------------- | -------------------------------------------------- |
| Cmder         | `%CMDER_ROOT%\config\profile.d\*.bat and *.cmd`    |
| PowerShell    | `$ENV:CMDER_ROOT\config\profile.d\*.ps1`           |
| Bash/Mintty   | `$CMDER_ROOT/config/profile.d/*.sh`                |

#### Git Status Opt-Out

 To disable Cmder prompt git status globally add the following to `~/.gitconfig` or locally for a single repo `[repo]/.git/config` and start a new session.

 *Note: This configuration is not portable*

 ```
 [cmder]
   status = false      # Opt out of Git status for 'ALL' Cmder supported shells.
   cmdstatus = false   # Opt out of Git status for 'Cmd.exe' shells.
   psstatus = false    # Opt out of Git status for 'Powershell.exe and 'Pwsh.exe' shells.
   shstatus = false    # Opt out of Git status for 'bash.exe' shells.
 ```

### Aliases
#### Cmder(`Cmd.exe`) Aliases
You can define simple aliases for `cmd.exe` sessions with a command like `alias name=command`.  Cmd.exe aliases support optional parameters through the `$1-9` or the `$*` special characters so the alias `vi=vim.exe $*` typed as `vi [filename]` will open `[filename]` in `vim.exe`.

Cmd.exe aliases can also be more complex. See: [DOSKEY.EXE documentation](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/doskey) for additional details on complex aliases/macros for `cmd.exe`

Aliases defined using the `alias.bat` command will automatically be saved in the `%CMDER_ROOT%\config\user_aliases.cmd` file

To make an alias and/or any other profile settings permanent add it to one of the following:

Note: These are loaded in this order by `$CMDER_ROOT/vendor/init.bat`.  Anything stored in `%CMDER_ROOT%` will be a portable setting and will follow Cmder to another machine.

* `%CMDER_ROOT%\config\profile.d\*.cmd` and `\*.bat`
* `%CMDER_ROOT%\config\user_aliases.cmd`
* `%CMDER_ROOT%\config\user_profile.cmd`

#### Bash.exe|Mintty.exe Aliases
Bash shells support simple and complex aliases with optional parameters natively so they work a little different.  Typing `alias name=command` will create an alias only for the current running session.

To make an alias and/or any other profile settings permanent add it to one of the following:

Note: These are loaded in this order by `$CMDER_ROOT/vendor/git-for-windows/etc/profile.d/cmder.sh`.  Anything stored in `$CMDER_ROOT` will be a portable setting and will follow Cmder to another machine.

* `$CMDER_ROOT/config/profile.d/*.sh`
* `$CMDER_ROOT/config/user_profile.sh`
* `$HOME/.bashrc`

If you add bash aliases to `$CMDER_ROOT/config/user_profile.sh` they will be portable and follow your Cmder folder if you copy it to another machine.  `$HOME/.bashrc` defined aliases are not portable.

#### PowerShell.exe Aliases
PowerShell has native simple alias support, for example `[new-alias | set-alias] alias command`, so complex aliases with optional parameters are not supported in PowerShell sessions.  Type `get-help [new-alias|set-alias] -full` for help on PowerShell aliases.

To make an alias and/or any other profile settings permanent add it to one of the following:

Note: These are loaded in this order by `$ENV:CMDER_ROOT\vendor\user_profile.ps1`.  Anything stored in `$ENV:CMDER_ROOT` will be a portable setting and will follow Cmder to another machine.

* `$ENV:CMDER_ROOT\config\profile.d\*.ps1`
* `$ENV:CMDER_ROOT\config\user_profile.ps1`

### SSH Agent

To start the vendored SSH agent simply call `start-ssh-agent`, which is in the `vendor/git-for-windows/cmd` folder.

If you want to run SSH agent on startup, include the line `@call "%GIT_INSTALL_ROOT%/cmd/start-ssh-agent.cmd"` in `%CMDER_ROOT%/config/user_profile.cmd` (usually just uncomment it).

### Vendored Git

Cmder is by default shipped with a vendored Git installation.  On each instance of launching Cmder, an attempt is made to locate any other user provided Git binaries. Upon finding a `git.exe` binary, Cmder further compares its version against the vendored one _by executing_ it. The vendored `git.exe` binary is _only_ used when it is more recent than the user-installed one.

You may use your favorite version of Git by including its path in the `%PATH%` environment variable.  Moreover, the **Mini** edition of Cmder (found on the [downloads page](https://github.com/cmderdev/cmder/releases)) excludes any vendored Git binaries.

### Using external Cygwin/Babun, MSys2, WSL, or Git for Windows SDK with Cmder.

You may run bash (the default shell used on Linux, macOS and GNU/Hurd) externally on Cmder, using the following instructions:

1. Setup a new task by pressing <kbd>Win</kbd> +<kbd>Alt</kbd> + <kbd>T</kbd>.
1. Click the `+` button to add a task.
1. Name the new task in the top text box.
1. Provide task parameters, this is optional.
1. Add `cmd /c "[path_to_external_env]\bin\bash --login -i" -new_console` to the `Commands` text box.

**Recommended Optional Steps:**

Copy the `vendor/cmder_exinit` file to the Cygwin/Babun, MSys2, or Git for Windows SDK environments `/etc/profile.d/` folder to use portable settings in the `$CMDER_ROOT/config` folder.

Note: MinGW could work if the init scripts include `profile.d` but this has not been tested.

The destination file extension depends on the shell you use in that environment.  For example:

* bash - Copy to `/etc/profile.d/cmder_exinit.sh`
* zsh  - Copy to `/etc/profile.d/cmder_exinit.zsh`

Uncomment and edit the line below in the script to use Cmder config even when launched from outside Cmder.

```
# CMDER_ROOT=${USERPROFILE}/cmder  # This is not required if launched from Cmder.
```

### Customizing user sessions using `init.bat` custom arguments.

You can pass custom arguments to `init.bat` and use `cexec.cmd` in your `user_profile.cmd` to evaluate these
arguments then execute commands based on a particular flag being detected or not.

`init.bat` creates two shortcuts for using `cexec.cmd` in your profile scripts.

#### `%ccall%` - Evaluates flags, runs commands if found,  and returns to the calling script and continues.

```
ccall=call C:\Users\user\cmderdev\vendor\bin\cexec.cmd
```

Example: `%ccall% /startnotepad start notepad.exe`

#### `%cexec%` - Evaluates flags, runs commands if found, and does not return to the calling script.

```
cexec=C:\Users\user\cmderdev\vendor\bin\cexec.cmd
```

Example: `%cexec% /startnotepad start notepad.exe`

It is useful when you have multiple tasks to execute `cmder` and need it to initialize
the session differently depending on the task chosen.

To conditionally start `notepad.exe` when you start a specific `cmder` task:

* Press <kbd>win</kbd>+<kbd>alt</kbd>+<kbd>t</kbd>
* Click `+` to add a new task.
* Add the below to the `Commands` block:

  ```batch

  cmd.exe /k ""%ConEmuDir%\..\init.bat" /startnotepad"

  ```

* Add the below to your `%cmder_root%\config\user_profile.cmd`

  ```batch

  %ccall% "/startNotepad" "start" "notepad.exe"`

  ```

To see detailed usage of `cexec`, type `cexec /?` in Cmder.

### Integrating Cmder with [Windows Terminal](https://github.com/cmderdev/cmder/wiki/Seamless-Windows-Terminal-Integration), [VS Code](https://github.com/cmderdev/cmder/wiki/Seamless-VS-Code-Integration), and your favorite IDEs

Cmder by default comes with a vendored ConEmu installation as the underlying terminal emulator, as stated [here](https://conemu.github.io/en/cmder.html).

However, Cmder can in fact run in a variety of other terminal emulators, and even integrated IDEs. Assuming you have the latest version of Cmder, follow the following instructions to get Cmder working with your own terminal emulator.

For instructions on how to integrate Cmder with your IDE, please read our [Wiki section](https://github.com/cmderdev/cmder/wiki#cmder-integration).

## Upgrading

The process of upgrading Cmder depends on the version/build you are currently running.

If you have a `[cmder_root]/config/user[-|_]conemu.xml`, you are running a newer version of Cmder, follow the below process:

1. Exit all Cmder sessions and relaunch `[cmder_root]/cmder.exe`, this backs up your existing `[cmder_root]/vendor/conemu-maximus5/conemu.xml` to `[cmder_root]/config/user[-|_]conemu.xml`.

   * The `[cmder_root]/config/user[-|_]conemu.xml` contains any custom settings you have made using the 'Setup Tasks' settings dialog.

2. Exit all Cmder sessions and backup any files you have manually edited under `[cmder_root]/vendor`.

   * Editing files under `[cmder_root]/vendor` is not recommended since you will need to re-apply these changes after any upgrade.  All user customizations should go in `[cmder_root]/config` folder.

3.  Delete the `[cmder_root]/vendor` folder.
4.  Extract the new `cmder.zip` or `cmder_mini.zip` into `[cmder_root]/` overwriting all files when prompted.

If you do not have a `[cmder_root]/config/user[-|_]conemu.xml`, you are running an older version of cmder, follow the below process:

1. Exit all Cmder sessions and backup `[cmder_root]/vendor/conemu-maximus5/conemu.xml` to `[cmder_root]/config/user[-|_]conemu.xml`.

2. Backup any files you have manually edited under `[cmder_root]/vendor`.

   * Editing files under `[cmder_root]/vendor` is not recommended since you will need to re-apply these changes after any upgrade.  All user customizations should go in `[cmder_root]/config` folder.

3.  Delete the `[cmder_root]/vendor` folder.
4.  Extract the new `cmder.zip` or `cmder_mini.zip` into `[cmder_root]/` overwriting all files when prompted.

## Current development builds

You can download builds of the current development branch by going to AppVeyor via the following link:

[![AppVeyor](https://ci.appveyor.com/api/projects/status/github/cmderdev/cmder?svg=True)](https://ci.appveyor.com/project/cmderdev/cmder/branch/master/artifacts)

The latest download builds by GitHub Actions can be downloaded from the link below:

[![Build Status](https://github.com/cmderdev/cmder/actions/workflows/build.yml/badge.svg)](https://github.com/cmderdev/cmder/actions/workflows/build.yml)

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

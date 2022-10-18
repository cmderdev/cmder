# Change Log

## [1.3.20](https://github.com/cmderdev/cmder/tree/v1.3.20) (2022-03-18)

### Changes

- Update Git for Windows to 2.38.0.windows.1
- Update Clink to 1.3.47
- Update ConEmu to 22.08.07

### Fixes

- Fix #2740
- Fix find and use latest Git install always using vendored Git.
- Fix using Git from vendored Git and other Git for Windows tools from other Git in path.
- Remove setting `term=cygwin` in `init.bat` to fix random `ABCD` characters when using arrow keys in `vim`.
  - See: [Sometimes pressing on arrow keys prints symbols #1691](https://github.com/Maximus5/ConEmu/issues/169)
- Fix #2654: blank space added between {cwd} and version_control variable by @geekrumper in https://github.com/cmderdev/cmder/pull/2661
- Fix #2659: Use get_hg_branch() to get Mercurial branch information. by @vsajip in https://github.com/cmderdev/cmder/pull/2660
- Fix Git prompt branch when using Git worktree by @daxgames in https://github.com/cmderdev/cmder/pull/2680
- Add optional clink async prompt update for svn status by @Mikaz-fr in https://github.com/cmderdev/cmder/pull/2703
- Better bat by @daxgames in https://github.com/cmderdev/cmder/pull/2742
- Related to #2654: Move space from "{git}{hg}{svn}" to individual parts by @DRSDavidSoft in https://github.com/cmderdev/cmder/pull/2738
- Use TaskDialog instead of MessageBox (Fixes Builds) by @DRSDavidSoft in https://github.com/cmderdev/cmder/pull/2746
- Add bin\cmder_shell.cmd by @DRSDavidSoft in https://github.com/cmderdev/cmder/pull/2747
- Fix build system scripts (closes #2723) by @DRSDavidSoft in https://github.com/cmderdev/cmder/pull/2748
- Custom option for launcher title by @DRSDavidSoft in https://github.com/cmderdev/cmder/pull/2752
- Use Github Actions to build and release by @MartiUK in https://github.com/cmderdev/cmder/pull/2725
- Re-factor the build script to distinguish each step by @DRSDavidSoft in https://github.com/cmderdev/cmder/pull/2758

## [1.3.19](https://github.com/cmderdev/cmder/tree/v1.3.19) (2022-01-15)

### Changes

- Update Git for Windows to 2.34.0
- Update to Clink 1.2.46
- Update to stable ConEmu 210912
- Do not rely on having a `%cmder_root%\config\cmder_prompt_config.lua`

### Adds

- PowerShell Git version Discovery - See #2373 for the full proposal.
  - Find user installed Git on Path
    - If found
      - if newer than Cmder embedded Git
        - Use its existing Path config and completely ignore embedded Git.
      - Else if Cmder embedded Git exists and is newer
        - Match User installed Git path config using Cmder embedded Git folders.
    - Else if Cmder embedded Git exists
      - Add Cmder embedded Git folders to the path.
        - `$env:cmder_root\vendor\git-for-windows\cmd;$env:path`
        - `$env:path;$env:cmder_root\vendor\git-for-windows\usr\bin`
        - `$env:path;$env:cmder_root\vendor\git-for-windows\mingw64\bin`
- Configurable prompt for `cmd.exe` sessions.  See `%cmder_root%\config\cmder_prompt_config.lua`
  - Configurable colors
  - Option to change `λ` to another character.
  - Option to add `[user]@[host]` to the prompt
  - Option to use of `~` to represent `$HOME` folder.
  - Option to use folder name vs. full working directory path in prompt.
  - Option to use single line prompt.

### Fixes

- Git prompt opt-out works better with additional changes to `clink-completions`

## [1.3.18](https://github.com/cmderdev/cmder/tree/v1.3.18) (2021-3-26)

### Changes

- Update to Clink 1.1.45 to fix #2451, #2465,  and #2473
- Update to ConEmu v21.03.04
- `init.bat` auto migrates the history alias to use `clink history` if required.
- Remove Tilde match from clink.lua in favor of builtin Clink capability.

## [1.3.17](https://github.com/cmderdev/cmder/tree/v1.3.17) (2020-12-23)
### Fixes

- [bug] Running `alias ..=cd ..` removes other aliases #2394
- Switch to @chrisant996 [Clink](https://github.com/chrisant996/clink/) v1.1.10 to fix Clink newer Windows 10 releases.
- Fix `\Git\cmd\git.exe found. was unexpected at this time.`
- Documentation fixes.

### Changes

- Update Git to 2.29.0
- Improve `init.bat` Speed
- Add `systeminfo.exe` output to iag scripts.

## [1.3.16](https://github.com/cmderdev/cmder/tree/v1.3.16) (2020-07-29)

### Fixes

* Merge pull request #2357 from FloSchwalm/fix-git-version-comparison  [Dax T Games]
* Merge pull request #2339 from daxgames/fix_global_vars_vscode_err  [Dax T Games]

### Changes

* Merge pull request #2358 from FloSchwalm/update-to-git-2.28  [Dax T Games]

## [1.3.15](https://github.com/cmderdev/cmder/tree/v1.3.15) (2020-06-26)

* Fixes #2247, fixes #2254 [#2265](https://github.com/cmderdev/cmder/pull/2265)
* Clink path get broken if clink-completions content is created in a different order #2278Clink path get broken if clink-completions content is created in a different order [#2278](https://github.com/cmderdev/cmder/pull/2278)
* Move Git functions to `lib/git.bat` [#2293](https://github.com/cmderdev/cmder/pull/2293)
* Fix Cmder issue #2290 [#2294](https://github.com/cmderdev/cmder/pull/2294)
* Update git for windows to 2.26.2 [#2308](https://github.com/cmderdev/cmder/pull/2308)
* Update README.md #2323Update README.md [#2323](https://github.com/cmderdev/cmder/pull/2323)
* Added support for setting custom icons for Cmder window [#2335](https://github.com/cmderdev/cmder/pull/2335)
* Fix and enhance enhance_path_recursive [#2311](https://github.com/cmderdev/cmder/pull/2311)

## [1.3.14](https://github.com/cmderdev/cmder/tree/v1.3.14) (2020-01-08)

### Fixes

* Pull Request: [#2222](https://github.com/cmderdev/cmder/pull/2222)
  * Cmder v1.3.13 init script fails. [#2218](https://github.com/cmderdev/cmder/issues/2218)
  * Git & env related error messages. [#2220](https://github.com/cmderdev/cmder/issues/2220)
  * Latest addition of "--nolog" clink breaks cmd prompts. [#2166](https://github.com/cmderdev/cmder/issues/2166)
  * `/nix_tools 0` should prevent adding `%GIT_INSTALL_ROOT%\mingw64\bin` to PATH. [#2214](https://github.com/cmderdev/cmder/issues/2214)

### Changes

* Update Git for Windows to 2.24.1.windows.2
  * Pull Request: [#2237](https://github.com/cmderdev/cmder/pull/2237)
* Update clink-completions to 0.3.5
  * Pull Request: [#2223](https://github.com/cmderdev/cmder/pull/2223)

## [1.3.13](https://github.com/cmderdev/cmder/tree/v1.3.13) (2019-11-03)

### Changes

* Update to ConEmu 19.10.12

### Adds

* #2197, #1364, #447 Add ability to disable git status either globally or for individual repos.
  * To disable git status globally add the following to `~/.gitconfig` or locally for a single repo `[repo]/.git/config`:

    ```
    [cmder]
      status = false
    ```

* #2174 `--` Syntax to pass command line options to ConEmu.
* Disable Clink Logging
* Add `~` tab completion.


### Fixes

* Fix #2191: profile.ps1: CheckGit does not export $gitLoaded
* Fix #2192: Set default prompt hooks before loading user profile
* Fix #2097, #1899: PowerShell foreground color changing to green
* Fix #1979: Update Clink Completions to 0.3.4
* Fix #1678: Cmder corrupting path with `!` in Cmder folder path.


## [1.3.12](https://github.com/cmderdev/cmder/tree/v1.3.12) (2019-08-19)

### Fixes

* Pull Request: [#2113](https://github.com/cmderdev/cmder/pull/2113)
  * Add `vendor\bin\vscode_init.cmd` for use with Visual Studio Code
  * Fixes [#2118](https://github.com/cmderdev/cmder/issues/2118)
  * Fixes [#1985](https://github.com/cmderdev/cmder/issues/1985)
* Pull Request: [#2106](https://github.com/cmderdev/cmder/pull/2106)
  * Portable Git requires running `post-install.bat` which deletes itself when done.  This was not happening.
  * Resolves [#2105](https://github.com/cmderdev/cmder/issues/2105)
* Pull Request: [#2002](https://github.com/cmderdev/cmder/pull/2002)
  * Updated the HG prompt code to use the '-ib' option to 'hg id' so the branch name is always available, regardless of the state of the working copy

### Changes

* Pull Request: [#2055](https://github.com/cmderdev/cmder/pull/2055)
  * Upgrade git to 2.21.0
  * Provide default settings for Clink that updates the history file in real time
    * Turn this on in existing Cmder using `clink set history_io 1`
  * Allow clink disable by setting CMDER_CLINK=0 before starting task
* Pull Request: [#2068](https://github.com/cmderdev/cmder/pull/2068)
  * Print Index in History Command Output.
  * Sets default `history_expand_mode = 3` in initial Clink Settings.

### Adds

* Pull Request  : [#2096](https://github.com/cmderdev/cmder/pull/2096)
  * Question issue: [#2094](https://github.com/cmderdev/cmder/issues/2094)
  * New argument created to ConEmu forwarding arguments.
    * Syntax: `/x [ConEmu extras arguments]`
    *   e.g.: `Cmder.exe /x "-min -tsa"`

* Pull Request: [#2072](https://github.com/cmderdev/cmder/pull/2072)
  * New alias create [alias] [alias command] syntax
    * Based on [#1750](https://github.com/cmderdev/cmder/pull/1750)
    * Syntax: `alias create [alias] [alias command]`

## [1.3.11](https://github.com/cmderdev/cmder/tree/v1.3.11) (2018-12-22)

### Fixes

* Fix uncommenting `call ssh-agent` in `user_profile.cmd` breaks Cmder prompt. [#1990](https://github.com/cmderdev/cmder/issues/1990), [#1807](https://github.com/cmderdev/cmder/issues/1807), [#1785](https://github.com/cmderdev/cmder/issues/1785), [#1885](https://github.com/cmderdev/cmder/issues/1885)
  * Pull Request: [#1999](https://github.com/cmderdev/cmder/issues/1999) fix ssh-agent call in user_profile.cmd.default
* Unable to use '%' character in git branch names [#1779](https://github.com/cmderdev/cmder/issues/1779)
  * Pull Request: [#1991](https://github.com/cmderdev/cmder/issues/1991) add percent escaping for string.gsub
* sort command, unix vs windows (/usr/bin/sort vs sort.exe) [#1931](https://github.com/cmderdev/cmder/issues/1931)
  * Pull Request: [#1988](https://github.com/cmderdev/cmder/issues/1988) Prefer /nix_tools option

### Adds

* [#1988](https://github.com/cmderdev/cmder/issues/1988) Prefer /nix_tools option
* [#1982](https://github.com/cmderdev/cmder/issues/1982) make /register work with /single
* [#1975](https://github.com/cmderdev/cmder/issues/1975) Add `/nix_tools 0` option to init.bat to prevent adding !GIT_INSTALL_ROOT!\usr\bin to PATH


### Changes

* [#1987](https://github.com/cmderdev/cmder/issues/1987) Use default files for default user profiles

## [1.3.10](https://github.com/cmderdev/cmder/tree/v1.3.10) (2018-11-30)

### Fixes

* Replaces Cmder Release v1.3.9 which has been removed.
* /c now completely separates user config including ConEmu configuration. This enables true multi-user Cmder with no configuration collisions. See PR #1949.
* Fix #1959 Start cmder "find" errors. See PR #1961.
* Fix #1956 Git detection should use env from git install root. See PR #1969

### Adds

* /m initially creates %cmder_root%/config/ConEmu-%computername%.xml for users that want per computer ConEmu configuration with shared init scripts. See PR #1949.
* /register now recognizes /c [path] and creates an appropriate Cmder Here shell context menu. See PR #1949.

## [1.3.8](https://github.com/cmderdev/cmder/tree/v1.3.8) (2018-11-10)

### Fixes

* Fix \vendor\bin\timer.cmd was unexpected at this time. on session start.

## [1.3.7](https://github.com/cmderdev/cmder/tree/v1.3.7) (2018-11-10)
## Updated components

* ConEmu to 180626
* Update Git to 2.19.0

## Fixes:

* Cmder now opens in the in the current working dir

## Commits
### Aaron Arney (1):

* Update README

### Arion Roberto Krause (1):

* Fixed typo

### Benjamin Staneck (8):

* Revert "replace user-aliases with user_aliases"
* replace user-aliases with user_aliases
* better fix for #1265
* Revert "sanitize dir before assigning to prompt"
* sanitize dir before assigning to prompt
* Update CHANGELOG.md

### Bob Hood (1):

* Refactored the Mercurial prompt code to be more efficient.

### David Refoua (1):

* fix some spelling issues

### Dax T Games (30):

* Revert "Ignore %cmder_root%\config (#1945)"
* Ignore %cmder_root%\config (#1945)
* Add /f for fast init. (#1942)
* add diag helper scripts and adds to the path (#1918)
* Fix #1806 #1675 (#1870)
* Profile.ps1 (#1796)
* Fix lib base (#1794)
* Little Changes
* Fixed move of default ConEmu.xml to the vendor folder
* ignore all of config folder
* move default comemu.xml to vendor folder
* fixes
* more headers
* init.bat update for cexec
* git prompt yellow
* fix user lua and git detection
* allow conditionally setting environment variables
* added exit codes
* flag_exists.cmd to flag_exec.cmd, also to lib as an option
* fixed
* handle start dir args with trailing "
* cleanup
* '.gitignore'
* verbose output
* cmder_shell settings
* add cmder_shell method
* replace - with \_ in debug-output and verbose-output
* Trying to get tcc working
* move user-aliases.cmd to user_aliases.cmd
* move bin\alias.bat to vendor\bin\alias.cmd
* fix /unregister

### Dmitri S. Guskov (2):

* PowerShell 5.1 compatibility
* Update profile.ps1

### Gregory Lucas (1):

* Initialize time_init to fix init error message

### Josef Pihrt (2):

* Fix typos, remove escaping inside inline code, replace single quote with backtick
* Fix typo and broken link

### Merlin (1):

* Remove duplicate Install-Module detection

### Nicolas Arnaud-Cormos (1):

* Ensure the right git path is found in case of shim.

### Thorsten Sommer (1):

* Fixed spelling

### gaoslin (1):

* Update init.bat

### leochien0102 (1):

* fix the 'was unexpected at this time.'

### xiazeyu (4):

* chore: unite slash
* docs: update to latest usage
* refactor: reduce global variable usage, fixed quote issue, added parameters support
* doc: fix typo

### xiazeyu_2011 (8):

* docs: migrated instructions to the wiki pages
* rename /bin/have.bat to /vendor/lib/flag_exists.cmd
* fix: bug when no argument is passed in
* docs: update doc for have.bat
* feat: add have.bat as a wrapper
* Optimize comments of using arguments in user-profile.cmd
* fix conflict with init.bat build-in command parser, update user-profile.cmd
* Pass arguments to user-profile.cmd

刘祺 (1):

* add LANG support

## [1.3.6](https://github.com/cmderdev/cmder/tree/v1.3.6) (2018-05-30)
**Updated components:**

* Git updated to v2.17.1.windows.2
* ConEmu updated to 180528

**Updates:**

* Cmder now opens in the in the current working dir
* TBD

## [1.3.6-pre2](https://github.com/cmderdev/cmder/tree/v1.3.6-pre2) (2018-03-01)

**Updated components:**

* Git updated to v2.16.3.windows.1
* ConEmu updated to 180318

**Updates:**

* Removed all sub routines from `init.bat` and made them into importable libraries that can be used in any `*.bat|cmd` file.
  * Libraries are in `%cmder_root%\vendor\lib`.
  * Import libraries into any `*.bat|cmd` file using `call "%cmder_root%\vendor\lib\[library file name]"`.
  * Call library methods by typing `"%lib_path% enhance_path "c:\bin"`.
  * Get help on library method usage by typing `"%cmder_root%\vendor\lib\[library file name]" /h`.

## [1.3.6-pre1](https://github.com/cmderdev/cmder/tree/v1.3.6-pre1) (2018-03-01)

**Fixed bugs:**

* Fixed Git version check recently added to master.

**Updates:**

* Modified Cmder tasks in default ConEmu.xml to allow easily adding command line args for init.bat by adding some quotes. This resulted in a ton of misc changes to this file. See Adds below.
* Reworked `cmder.exe` command line argument handling to make it more flexible and easily added to.
* Reworked README.md tables to make them more readable in editors.

**Implemented enhancements:**

* Added `cmder.exe` command line args documentation to `README.md`.
* Added `:enhance_path` method to vendor\init.bat that modifies the path only if required.
  * To prepend: `call :enhance_path "%cmder_root%"`
  * to append: `call :enhance_path "%cmder_root%" append`
* Added `:enhance_path_recursive` method to vendor\init.bat that adds a path and all its sub directories to the path if required.
  * Max recurse depth default is '1' configurable using `init.bat /max_depth [1-5]`. 6+ results in error.
  * To prepend and go 3 levels deep: `call :enhance_path "%cmder_root%" 3`
  * To append and go 2 levels deep: `call :enhance_path "%cmder_root%" 2 append`
* Added ability to init.bat to accept command line args and documented them in README.md. Allows users to change the behaviour of init.bat without editing the file.

| Argument                      | Description                                                                                      | Default                                |
| ----------------------------- | ------------------------------------------------------------------------------------------------ | -------------------------------------- |
| /c [user cmder root]          | Enables user bin and config folders for 'Cmder as admin' sessions due to non-shared environment. | not set                                |
| /d                            | Enables debug output.                                                                            | not set                                |
| /git_install_root [file path] | User specified Git installation root path.                                                       | '%CMDER_ROOT%\vendor\Git-for-Windows'  |
| /home [home folder]           | User specified folder path to set `%HOME%` environment variable.                                 | '%userprofile%'                        |
| /max_depth [1-5]              | Define max recurse depth when adding to the path for `%cmder_root%\bin` and `%cmder_user_bin%`   | 1                                      |
| /svn_ssh [path to ssh.exe]    | Define %SVN_SSH% so we can use git svn with ssh svn repositories.                                | '%GIT_INSTALL_ROOT%\bin\ssh.exe'       |
| /user_aliases [file path]     | File path pointing to user aliases.                                                              | '%CMDER_ROOT%\config\user-aliases.cmd' |
| /v                            | Enables verbose output.                                                                          | not set                                |

* Added new `cmder.exe /C \<path\>` argument

  * To use run Cmder.exe with "/C" command line argument. Example: `cmder.exe /C %userprofile%\cmder_config`
  * To use run with `Cmder as Admin` sessions you must specify "/c" command line argument to `init.bat` in tasks. See [README.md](./Readme.md) for details.
  * Enables shared Cmder install with Non-Portable Individual User Config
  * Supported by all supported shells (cmder, PowerShell, git bash, and external bash)
  * This will create the following directory structure if it is missing.

    ```plain
    c:\users\[username]\cmder_config
    ├───bin
    └───config
        └───profile.d
    ```

  * Shell init scripts run in the following order
    1. %cmder_root%\config\profile.d\*.[cmd|ps1|sh]
    1. %cmder_root%\config\user-profile.[cmd|ps1|sh]
    1. %userprofile%\cmder_config\config\profile.d\*.[cmd|ps1|sh]
    1. %userprofile%\cmder_config\config\user-profile.[cmd|ps1|sh]

## [1.3.5](https://github.com/cmderdev/cmder/releases/tag/v1.3.5) (2018-02-11)

This is the first Cmder release that comes with Git for Windows in the 64bit version. If you are still using a 32bit version, you have to fix this yourself.

**Updated components:**

* Git updated to v2.16.1.windows.4
* clink updated to 0.4.9 (official version)
* ConEmu updated to 180206

**Fixed bugs:**

* use /dir Switch instead of CMDER_START (previously [\#921](https://github.com/cmderdev/cmder/pull/921)) [\#1609](https://github.com/cmderdev/cmder/pull/1609) ([Stanzilla](https://github.com/Stanzilla))
* add config/settings to .gitignore [\#1592](https://github.com/cmderdev/cmder/pull/1592) ([daxgames](<(https://github.com/daxgames)>))
* Upgrade #1591 ([daxgames](<(https://github.com/daxgames)>))
* Fix startup folder issue [\#1547](https://github.com/cmderdev/cmder/pull/1547) (dr-tony-lin)
* Fix alias.bat handling "user-aliases.cmd" with spaces [\#1531](https://github.com/cmderdev/cmder/pull/1531) ([Varriount](https://github.com/Varriount))
* Compatible with Visual Studio Code (cmd) [\#1416](https://github.com/cmderdev/cmder/pull/1416) ([gucong3000](https://github.com/gucong3000))

## [1.3.4](https://github.com/cmderdev/cmder/releases/tag/v1.3.4) (2017-11-03)

We now use a forked version of clink since its original author is missing and we needed Windows 10 compatibility.

**Updated components:**

* Git: v2.15.0.windows.1

**Fixed bugs:**

* Fix lambada color after a ConEmu change: [a8d3261](https://github.com/cmderdev/cmder/commit/a8d32611a9b93cfb58f0318ae4b8041bc8a86c68)
* Compatible with Visual Studio Code (PowerShell): [\#1417](https://github.com/cmderdev/cmder/pull/1417)
* Make default tasks respect "Startup directory for new process": [b58ff9b](https://github.com/cmderdev/cmder/commit/b58ff9bb539d7f908f427fa34f377e1513fcd825)

## [1.3.3](https://github.com/cmderdev/cmder/releases/tag/v1.3.3) (2017-10-28)

We now use a forked version of clink since its original author is missing and we needed Windows 10 compat.

**Updated components:**

* Git: v2.14.3.windows.1
* ConEmu: 170910
* Clink: 0.4.9-FORK
* Clink-Completions: 0.3.3

## [1.3.2](https://github.com/cmderdev/cmder/releases/tag/v1.3.2) (2016-12-01)

**Implemented enhancements:**

* Change appveyor.yml to publish all resulting artifacts from builds. [\#717](https://github.com/cmderdev/cmder/issues/717)
* Stuff that should not be in the release zips [\#662](https://github.com/cmderdev/cmder/issues/662)
* Make cmder auto start with windows and auto minimize to the status bar. [\#532](https://github.com/cmderdev/cmder/issues/532)
* v1.2.0: Errors because of PowerShell execution policy [\#483](https://github.com/cmderdev/cmder/issues/483)
* Updating Vendors with chocolatey [\#442](https://github.com/cmderdev/cmder/issues/442)
* Alias without its opposite [\#281](https://github.com/cmderdev/cmder/issues/281)
* Improve new UX [\#230](https://github.com/cmderdev/cmder/issues/230)
* Different Font for the Lambda [\#211](https://github.com/cmderdev/cmder/issues/211)
* Git Credential Cache [\#184](https://github.com/cmderdev/cmder/issues/184)
* Crawling for executables in /bin [\#61](https://github.com/cmderdev/cmder/issues/61)
* Include Scoop as package manager [\#42](https://github.com/cmderdev/cmder/issues/42)
* Complete aliases on tab [\#38](https://github.com/cmderdev/cmder/issues/38)
* Path ordering issue - wrong find.exe executes by default [\#37](https://github.com/cmderdev/cmder/issues/37)
* User ConEmu cfg [\#1109](https://github.com/cmderdev/cmder/pull/1109) ([daxgames](https://github.com/daxgames))
* Msys bash [\#702](https://github.com/cmderdev/cmder/pull/702) ([daxgames](https://github.com/daxgames))
* Added code to check for the existence of a customized ini file.. [\#427](https://github.com/cmderdev/cmder/pull/427) ([kodybrown](https://github.com/kodybrown))
* New build and pack scripts [\#152](https://github.com/cmderdev/cmder/pull/152) ([samvasko](https://github.com/samvasko))
* Ability to change Font Size using Ctrl+MouseWheel [\#125](https://github.com/cmderdev/cmder/pull/125) ([saaguero](https://github.com/saaguero))

**Fixed bugs:**

* Git process not ending. [\#1060](https://github.com/cmderdev/cmder/issues/1060)
* Git: fatal: Unable to create '.git/index.lock': File exists. [\#1044](https://github.com/cmderdev/cmder/issues/1044)
* Aliases with environment variables not working [\#684](https://github.com/cmderdev/cmder/issues/684)
* msysgit is not injected into path. [\#493](https://github.com/cmderdev/cmder/issues/493)
* cmder display error [\#491](https://github.com/cmderdev/cmder/issues/491)
* Path issues on startup [\#487](https://github.com/cmderdev/cmder/issues/487)
* Missing DLL: MSVCP140.dll [\#482](https://github.com/cmderdev/cmder/issues/482)
* Single mode does not set current directory [\#420](https://github.com/cmderdev/cmder/issues/420)
* Fails to parse path in PATH system variable with '&' [\#185](https://github.com/cmderdev/cmder/issues/185)
* Cmder hangs after idling for a few minutes or when clicking above the cursor [\#109](https://github.com/cmderdev/cmder/issues/109)
* No color scheme in tabs opened as Administrator [\#94](https://github.com/cmderdev/cmder/issues/94)
* Bug in alias.bat [\#52](https://github.com/cmderdev/cmder/issues/52)
* Clicking/selecting text on terminal causes slowdown [\#40](https://github.com/cmderdev/cmder/issues/40)

**Closed issues:**

* some kind of project profile [\#1175](https://github.com/cmderdev/cmder/issues/1175)
* Does cmder support the notion of a plugin [\#1173](https://github.com/cmderdev/cmder/issues/1173)
* Cygwin? [\#1155](https://github.com/cmderdev/cmder/issues/1155)
* CMDER ERROR [\#1154](https://github.com/cmderdev/cmder/issues/1154)
* Remapping hot keys [\#1150](https://github.com/cmderdev/cmder/issues/1150)
* What is mintty in here? [\#1149](https://github.com/cmderdev/cmder/issues/1149)
* No make [\#1146](https://github.com/cmderdev/cmder/issues/1146)
* How can I set the path of cmder properly at the start ? [\#1136](https://github.com/cmderdev/cmder/issues/1136)
* PowerShell Slow Startup [\#1130](https://github.com/cmderdev/cmder/issues/1130)
* python for cmder [\#1129](https://github.com/cmderdev/cmder/issues/1129)
* Haskell repl \(ghci\) crashes only in cmder works elsewhere [\#1125](https://github.com/cmderdev/cmder/issues/1125)
* Latest update causes `error: failed to push some refs to git@gitlab....` [\#1124](https://github.com/cmderdev/cmder/issues/1124)
* Connection to SSH agent refused [\#1123](https://github.com/cmderdev/cmder/issues/1123)
* Slow on startup [\#1122](https://github.com/cmderdev/cmder/issues/1122)
* Shell script fail [\#1121](https://github.com/cmderdev/cmder/issues/1121)
* Ctrl+` shorcut does not work in version 161002 [\#1113](https://github.com/cmderdev/cmder/issues/1113)
* Git LFS not working with newer cmder versions [\#1112](https://github.com/cmderdev/cmder/issues/1112)
* Processes dying due to lack of memory? [\#1106](https://github.com/cmderdev/cmder/issues/1106)
* Broken links [\#1103](https://github.com/cmderdev/cmder/issues/1103)
* "\config\profile.d\Active"' is not recognized as an internal or external command, operable program or batch file. [\#1102](https://github.com/cmderdev/cmder/issues/1102)
* Can't run 'git commit' [\#1098](https://github.com/cmderdev/cmder/issues/1098)
* Unable to use keybase K:\ [\#1096](https://github.com/cmderdev/cmder/issues/1096)
* Can not Run mintty in v1.3.1 [\#1094](https://github.com/cmderdev/cmder/issues/1094)
* Shortcut for new tab ?? [\#1093](https://github.com/cmderdev/cmder/issues/1093)
* Bad symbols [\#1092](https://github.com/cmderdev/cmder/issues/1092)
* cmder turns slow when using GIT command after update to the latest version [\#1091](https://github.com/cmderdev/cmder/issues/1091)
* $ENV:CMDER_START has a double quote too much [\#1079](https://github.com/cmderdev/cmder/issues/1079)
* Incorrect checksum ? [\#1075](https://github.com/cmderdev/cmder/issues/1075)
* Unplugging the battery detaches the Quake console [\#1074](https://github.com/cmderdev/cmder/issues/1074)
* Mouse right click copy and paste at same time. [\#1072](https://github.com/cmderdev/cmder/issues/1072)
* strange display on Chinese windows 8 [\#1071](https://github.com/cmderdev/cmder/issues/1071)
* Permanently add all SSH keys to ssh-agent [\#1062](https://github.com/cmderdev/cmder/issues/1062)
* Wrong dir privilege in bash on Windows ? [\#1059](https://github.com/cmderdev/cmder/issues/1059)
* Invalid [\#1058](https://github.com/cmderdev/cmder/issues/1058)
* Python virtualenv not activating in Windows 10 Cmder [\#1057](https://github.com/cmderdev/cmder/issues/1057)
* prompt is Garbled [\#1054](https://github.com/cmderdev/cmder/issues/1054)
* startup is so slow [\#1053](https://github.com/cmderdev/cmder/issues/1053)
* ~ doesn't work in cmder? [\#1051](https://github.com/cmderdev/cmder/issues/1051)
* \[Solved myself\] .bash_history and winscp.rnd are not in Cmder's directories [\#1050](https://github.com/cmderdev/cmder/issues/1050)
* First run config fails with exclamation in path [\#1049](https://github.com/cmderdev/cmder/issues/1049)
* Can't run npm or any Node Module on Cmder \(Windows 7\) [\#1047](https://github.com/cmderdev/cmder/issues/1047)
* Cannot start cmder [\#1046](https://github.com/cmderdev/cmder/issues/1046)
* About letter overlapping [\#1045](https://github.com/cmderdev/cmder/issues/1045)
* %cmder_root%\config\user-aliases.ps1 is not created on a fresh install of v1.3.0 [\#1040](https://github.com/cmderdev/cmder/issues/1040)
* Cmder looking for user-aliases in wrong path [\#1039](https://github.com/cmderdev/cmder/issues/1039)
* multiple hg.exe processes spawned [\#1035](https://github.com/cmderdev/cmder/issues/1035)
* cls command spacing as well as spacing for input not wrapping to next line, global env vars not highlighted [\#1032](https://github.com/cmderdev/cmder/issues/1032)
* Cmder getting raped by dr.web quarantine system [\#1031](https://github.com/cmderdev/cmder/issues/1031)
* cmder no longer using path variables [\#1029](https://github.com/cmderdev/cmder/issues/1029)
* Can I switch vim in cmder to gvim installed by myself? [\#1021](https://github.com/cmderdev/cmder/issues/1021)
* \[Windows10 Bash\] Could use UP/Down/Home/End....key in cmder [\#1017](https://github.com/cmderdev/cmder/issues/1017)
* {lamb} problem again... :-\( [\#1012](https://github.com/cmderdev/cmder/issues/1012)
* High-lighting text and copying is broken [\#1008](https://github.com/cmderdev/cmder/issues/1008)
* issue with updating ConEmuPack.160619.7z [\#1006](https://github.com/cmderdev/cmder/issues/1006)
* using touch in cli doesn't work anymore with latest update [\#1002](https://github.com/cmderdev/cmder/issues/1002)
* When resizing cmder window an extra path line appears. [\#1000](https://github.com/cmderdev/cmder/issues/1000)
* v1.3.0-pre doesn't support running inside program files folder [\#998](https://github.com/cmderdev/cmder/issues/998)
* Text cursor disappears when window resized [\#997](https://github.com/cmderdev/cmder/issues/997)
* how to use clip command in the cmder? [\#996](https://github.com/cmderdev/cmder/issues/996)
* {git}{hg} appearing in path print out rather than the values they represent [\#995](https://github.com/cmderdev/cmder/issues/995)
* Don't just prepend the git path. [\#994](https://github.com/cmderdev/cmder/issues/994)
* `ls` et al slow after updating cmder [\#993](https://github.com/cmderdev/cmder/issues/993)
* Attempt to concatenate local 'package_version' \(a nil value\) [\#991](https://github.com/cmderdev/cmder/issues/991)
* After auto-update git/hg indication and lambda in prompt are broken [\#990](https://github.com/cmderdev/cmder/issues/990)
* Lack of Proxy Setting [\#989](https://github.com/cmderdev/cmder/issues/989)
* Clink completion failing [\#987](https://github.com/cmderdev/cmder/issues/987)
* \ [\#986](https://github.com/cmderdev/cmder/issues/986)
* default configuration does not support Chinese named file listing with ls [\#985](https://github.com/cmderdev/cmder/issues/985)
* When cmder opened in visual studio code, there is wrong path [\#981](https://github.com/cmderdev/cmder/issues/981)
* Is It Possible to recover the files removed by `rm -rf` [\#979](https://github.com/cmderdev/cmder/issues/979)
* . [\#973](https://github.com/cmderdev/cmder/issues/973)
* right click context menu open cmd without color [\#972](https://github.com/cmderdev/cmder/issues/972)
* git branch name is not red when there are pending changes [\#967](https://github.com/cmderdev/cmder/issues/967)
* git checkout autocomplete is showing files [\#966](https://github.com/cmderdev/cmder/issues/966)
* Cmder proxy Ubuntu Bash on Windows [\#964](https://github.com/cmderdev/cmder/issues/964)
* Update version on Chocolatey [\#959](https://github.com/cmderdev/cmder/issues/959)
* ConEmu Injecting hooks fail [\#958](https://github.com/cmderdev/cmder/issues/958)
* chocolatey.lua:1: module 'tables' not found [\#957](https://github.com/cmderdev/cmder/issues/957)
* cmder \(from cmder_mini.zip\) crashes on startup on windows 7 pro x64 [\#955](https://github.com/cmderdev/cmder/issues/955)
* Feature: add some extra prompt-tuning hooks to profile.ps1 from user-profile.ps1 [\#950](https://github.com/cmderdev/cmder/issues/950)
* Provide alternate icon colors [\#947](https://github.com/cmderdev/cmder/issues/947)
* "\cmder\config\settings was unexpected at this time" and {lamb} is shown instead of lambda symbol [\#937](https://github.com/cmderdev/cmder/issues/937)
* Cannot save settings [\#936](https://github.com/cmderdev/cmder/issues/936)
* init.bat fails and shows {lamb} and {git} [\#935](https://github.com/cmderdev/cmder/issues/935)
* Cmder minimizing when losing focus. [\#934](https://github.com/cmderdev/cmder/issues/934)
* init.bat always uses "npm" as window title [\#933](https://github.com/cmderdev/cmder/issues/933)
* `ls` return vertical list instead of horizontal? [\#924](https://github.com/cmderdev/cmder/issues/924)
* Arrow keys in Windows 10 Linux Subsystem [\#919](https://github.com/cmderdev/cmder/issues/919)
* Arrow keys do not work with bash \(Win10/Linux Subsystem\) [\#914](https://github.com/cmderdev/cmder/issues/914)
* Aliased commands: Syntax Highlighting Lost [\#912](https://github.com/cmderdev/cmder/issues/912)
* 'vim' hangs when loading in cmder bash session [\#910](https://github.com/cmderdev/cmder/issues/910)
* Unix commands not working in windows 10 [\#908](https://github.com/cmderdev/cmder/issues/908)
* git 2.8 ? [\#905](https://github.com/cmderdev/cmder/issues/905)
* Confusing "Settings" \> "Integration" dialog behavior [\#904](https://github.com/cmderdev/cmder/issues/904)
* v1.3.0 antivirus [\#903](https://github.com/cmderdev/cmder/issues/903)
* Feature Request: Send to all/group [\#896](https://github.com/cmderdev/cmder/issues/896)
* Updating git-for-windows after installing the full cmder? [\#887](https://github.com/cmderdev/cmder/issues/887)
* Tab autocompetion for git is inconsistent \(doesn't work with git add\) [\#885](https://github.com/cmderdev/cmder/issues/885)
* Line-wrapping breaks when using backspace key in a git repo with Cmder mini and Git for Windows. [\#883](https://github.com/cmderdev/cmder/issues/883)
* Cmder opens off screen [\#881](https://github.com/cmderdev/cmder/issues/881)
* ctrl+l with PowerShell in quake mode clears the first prompt line as well [\#879](https://github.com/cmderdev/cmder/issues/879)
* Enconding ? [\#877](https://github.com/cmderdev/cmder/issues/877)
* the {cmd} task [\#876](https://github.com/cmderdev/cmder/issues/876)
* Failed to start cmder, app crashed [\#871](https://github.com/cmderdev/cmder/issues/871)
* Cmder Windows Pinning Issue \[weird\] [\#869](https://github.com/cmderdev/cmder/issues/869)
* Why not use @ECHO OFF? [\#868](https://github.com/cmderdev/cmder/issues/868)
* alias with && doesn't work [\#859](https://github.com/cmderdev/cmder/issues/859)
* Having trouble with packaged ConEmu install, how can I point to a different one? [\#858](https://github.com/cmderdev/cmder/issues/858)
* path entry for \<git\>/cmd instead of \<git\>/bin? [\#853](https://github.com/cmderdev/cmder/issues/853)
* Cmder lists path on window resize. [\#851](https://github.com/cmderdev/cmder/issues/851)
* Alias with multi-word git commit message not working [\#847](https://github.com/cmderdev/cmder/issues/847)
* cmder and vim compatibility problem [\#846](https://github.com/cmderdev/cmder/issues/846)
* Unable to git pull,push or any action [\#845](https://github.com/cmderdev/cmder/issues/845)
* switch to use master a the default development branch [\#836](https://github.com/cmderdev/cmder/issues/836)
* Missing git support, install posth-git [\#834](https://github.com/cmderdev/cmder/issues/834)
* Git branch information is broken for submodules [\#833](https://github.com/cmderdev/cmder/issues/833)
* "-ExecutionPolicy' is not recognized as an internal or external command" [\#830](https://github.com/cmderdev/cmder/issues/830)
* How to upgrade from v1.1.4.1 to v1.2 ? [\#825](https://github.com/cmderdev/cmder/issues/825)
* Startup warning [\#821](https://github.com/cmderdev/cmder/issues/821)
* Cmder prompt screwed up with latest Windows 10 Build [\#820](https://github.com/cmderdev/cmder/issues/820)
* Cmder does not open in last open window position [\#816](https://github.com/cmderdev/cmder/issues/816)
* CMDer won't open Sublime [\#814](https://github.com/cmderdev/cmder/issues/814)
* integrating Git for Windows vs. Git for Windows SDK? [\#813](https://github.com/cmderdev/cmder/issues/813)
* Installer for cmder? [\#812](https://github.com/cmderdev/cmder/issues/812)
* When will the next version be available? [\#811](https://github.com/cmderdev/cmder/issues/811)
* Netcat is missing [\#810](https://github.com/cmderdev/cmder/issues/810)
* how to use /? to get the help doc in the `cmder` [\#808](https://github.com/cmderdev/cmder/issues/808)
* \[Enhancement\] PowerShell and Babun \(cygwin + zsh\) [\#807](https://github.com/cmderdev/cmder/issues/807)
* Cmder - Warning: Missing git support [\#806](https://github.com/cmderdev/cmder/issues/806)
* iul [\#800](https://github.com/cmderdev/cmder/issues/800)
* Update clink settings [\#793](https://github.com/cmderdev/cmder/issues/793)
* how to add the environment variable to the cmder? [\#792](https://github.com/cmderdev/cmder/issues/792)
* % variable expansion in config/alias [\#791](https://github.com/cmderdev/cmder/issues/791)
* Problems with node [\#790](https://github.com/cmderdev/cmder/issues/790)
* Resizing adds new lines [\#789](https://github.com/cmderdev/cmder/issues/789)
* How to remove "Cmder Here" in the context menu after .\cmder.exe /REGISTER ALL? [\#787](https://github.com/cmderdev/cmder/issues/787)
* \[v1.2.9\] Can not alias with env. variables. [\#784](https://github.com/cmderdev/cmder/issues/784)
* How should i add a context menu entry? [\#780](https://github.com/cmderdev/cmder/issues/780)
* Branch name not visible and vagrant commands not working [\#778](https://github.com/cmderdev/cmder/issues/778)
* Run command to start [\#775](https://github.com/cmderdev/cmder/issues/775)
* CMDER_START should always be set to USERPROFILE unless explicitly set through /START parameter [\#772](https://github.com/cmderdev/cmder/issues/772)
* Startup Error: cmder\vendor\profile.ps1 cannot be loaded. [\#769](https://github.com/cmderdev/cmder/issues/769)
* How to make Cmder stop displaying warning? [\#768](https://github.com/cmderdev/cmder/issues/768)
* Security Warning - cmder\vendor\profile.ps1 [\#767](https://github.com/cmderdev/cmder/issues/767)
* Unable to install cmder using Install-Package in Windows 10 [\#762](https://github.com/cmderdev/cmder/issues/762)
* How do confirm exe's are safe? md5? checksum? [\#761](https://github.com/cmderdev/cmder/issues/761)
* Option to disable preview stacking with multiple tabs [\#758](https://github.com/cmderdev/cmder/issues/758)
* 'ls' is no longer recognized command [\#757](https://github.com/cmderdev/cmder/issues/757)
* I can't run de Cmder.exe [\#755](https://github.com/cmderdev/cmder/issues/755)
* Multiple location references when maximizing [\#753](https://github.com/cmderdev/cmder/issues/753)
* Clink completions for npm increase cmder startup time for one second [\#750](https://github.com/cmderdev/cmder/issues/750)
* Prevent other apps from overwriting the prompt? [\#749](https://github.com/cmderdev/cmder/issues/749)
* cmder.exe infected with Variant.Kazy.767238 [\#748](https://github.com/cmderdev/cmder/issues/748)
* cmder.exe considered harmful by Bitdefender [\#744](https://github.com/cmderdev/cmder/issues/744)
* curl ntlm auth stopped working [\#741](https://github.com/cmderdev/cmder/issues/741)
* Sublime Integration fails - Can't find "C:\Programs"? [\#727](https://github.com/cmderdev/cmder/issues/727)
* Cmder and gulp, not friend? [\#725](https://github.com/cmderdev/cmder/issues/725)
* Antivirus deleting some files in cmder \(reporting them as infected\) [\#724](https://github.com/cmderdev/cmder/issues/724)
* Windows Defender on Windows 10 finds Trojan in extracted files [\#713](https://github.com/cmderdev/cmder/issues/713)
* e. shortcut not working ? [\#712](https://github.com/cmderdev/cmder/issues/712)
* "Cmder here" doesn't work if set start-up dir [\#709](https://github.com/cmderdev/cmder/issues/709)
* Is cmder support scrolling with touch screen? [\#706](https://github.com/cmderdev/cmder/issues/706)
* npm_prompt.lua:11: attempt to concatenate local 'package_version' \(a nil value\) [\#700](https://github.com/cmderdev/cmder/issues/700)
* Cmder \(cmd.exe\) startup crashes at clink step [\#699](https://github.com/cmderdev/cmder/issues/699)
* Doesn't run cmder.exe [\#696](https://github.com/cmderdev/cmder/issues/696)
* Not getting git status in 1.2.9 prompt [\#692](https://github.com/cmderdev/cmder/issues/692)
* Tab-Complete paths not working \[1.2.9\] [\#691](https://github.com/cmderdev/cmder/issues/691)
* The directory be duplicate displayed [\#689](https://github.com/cmderdev/cmder/issues/689)
* Don't work at my windows 7 \(misiing api-ms-win-crt-runtime-l1-1-0.dll\) [\#682](https://github.com/cmderdev/cmder/issues/682)
* Use tab to cycle through auto complete, like the original cmd does? [\#681](https://github.com/cmderdev/cmder/issues/681)
* git: 'pull' is not a git command. See 'git --help'. [\#679](https://github.com/cmderdev/cmder/issues/679)
* Error in NPM-Prompt [\#678](https://github.com/cmderdev/cmder/issues/678)
* msysgit commands not working [\#675](https://github.com/cmderdev/cmder/issues/675)
* Restore last session with history on start [\#672](https://github.com/cmderdev/cmder/issues/672)
* Restart As Admin bug [\#669](https://github.com/cmderdev/cmder/issues/669)
* git for windows 2.6.1 ssh folder [\#661](https://github.com/cmderdev/cmder/issues/661)
* der [\#660](https://github.com/cmderdev/cmder/issues/660)
* Cannot clean the terminal [\#659](https://github.com/cmderdev/cmder/issues/659)
* Cmder do not run if username has spaces between [\#658](https://github.com/cmderdev/cmder/issues/658)
* When exiting vim, cursor goes to first line of terminal instead of the end of it [\#656](https://github.com/cmderdev/cmder/issues/656)
* Cmder suddenly start crashing on startup [\#650](https://github.com/cmderdev/cmder/issues/650)
* Cannot switch to mapped network drive [\#649](https://github.com/cmderdev/cmder/issues/649)
* Ctrl + D? [\#648](https://github.com/cmderdev/cmder/issues/648)
* Is there any hotkey jump to "Search" box? [\#647](https://github.com/cmderdev/cmder/issues/647)
* File /vendor/ConEmu-maximus5/ConEmu.exe not found. [\#646](https://github.com/cmderdev/cmder/issues/646)
* As admin CMDER_ROOT not set in PowerShell [\#643](https://github.com/cmderdev/cmder/issues/643)
* Emoji support [\#642](https://github.com/cmderdev/cmder/issues/642)
* Having ls, cat, etc [\#641](https://github.com/cmderdev/cmder/issues/641)
* Cmder having Permission Errors for Windows 10 [\#640](https://github.com/cmderdev/cmder/issues/640)
* PowerShell - Msys Aliases [\#639](https://github.com/cmderdev/cmder/issues/639)
* Problem with install on window 7? [\#637](https://github.com/cmderdev/cmder/issues/637)
* Invoke-Expression : The term 'Invoke-Expression' is not recognized [\#636](https://github.com/cmderdev/cmder/issues/636)
* it doesn't like Docker [\#631](https://github.com/cmderdev/cmder/issues/631)
* Latest release : Windows 7 : Windows cannot find ".../vendor/ConEmu-maximus5/CpmE,u.exe" [\#629](https://github.com/cmderdev/cmder/issues/629)
* Strange Vim behaviour after Git for Windows upgrade [\#628](https://github.com/cmderdev/cmder/issues/628)
* msysGit has been superseded ,consider to switch to Git for Windows 2.x? [\#627](https://github.com/cmderdev/cmder/issues/627)
* tail command not found [\#625](https://github.com/cmderdev/cmder/issues/625)
* Cmder console remain unused text on screen [\#623](https://github.com/cmderdev/cmder/issues/623)
* er con emu [\#617](https://github.com/cmderdev/cmder/issues/617)
* first google hit for cmder shows 404 [\#616](https://github.com/cmderdev/cmder/issues/616)
* \[ Solved \] How to I change to width of Split screen divider \( border \) line. [\#613](https://github.com/cmderdev/cmder/issues/613)
* No Unix commands? [\#610](https://github.com/cmderdev/cmder/issues/610)
* using user installed git \(2.5\) with the suggested /bin/agent.cmd does not work [\#609](https://github.com/cmderdev/cmder/issues/609)
* vendor/init.bat is overwritten with new versions -\> use a user startup file? [\#608](https://github.com/cmderdev/cmder/issues/608)
* Git autocomplete is not working as in git bash [\#607](https://github.com/cmderdev/cmder/issues/607)
* api-ms-win-crt-runtime-l1-1-0.dll is missing error \(Windows 8.1\) [\#604](https://github.com/cmderdev/cmder/issues/604)
* Prevent inactive cmder windows to be dimmed [\#603](https://github.com/cmderdev/cmder/issues/603)
* Git for Windows 2.5 [\#602](https://github.com/cmderdev/cmder/issues/602)
* Incompatibility with ConEmu 150716+ / double pinned icon on taskbar [\#599](https://github.com/cmderdev/cmder/issues/599)
* Cant get it working on windows xp [\#598](https://github.com/cmderdev/cmder/issues/598)
* ls parameters error in Windows 10 [\#597](https://github.com/cmderdev/cmder/issues/597)
* Resizing split windows [\#596](https://github.com/cmderdev/cmder/issues/596)
* PowerShell Profile Aliases ignored in Cmder [\#593](https://github.com/cmderdev/cmder/issues/593)
* "Inject ConEmuHk" settings slows git down considerably [\#592](https://github.com/cmderdev/cmder/issues/592)
* Suggestion about transparency [\#591](https://github.com/cmderdev/cmder/issues/591)
* Powerline integration with cmder [\#590](https://github.com/cmderdev/cmder/issues/590)
* Wrong place [\#589](https://github.com/cmderdev/cmder/issues/589)
* Misleading install instructions? [\#588](https://github.com/cmderdev/cmder/issues/588)
* ENHANCE: Only add git to path if not exist [\#586](https://github.com/cmderdev/cmder/issues/586)
* new console confirmation - with Ctrl-T [\#583](https://github.com/cmderdev/cmder/issues/583)
* start-ssh-agent not found [\#580](https://github.com/cmderdev/cmder/issues/580)
* Missing DLL [\#579](https://github.com/cmderdev/cmder/issues/579)
* Invoking ConEmu instead of ConEmu64 on Windows 10 64-bit [\#574](https://github.com/cmderdev/cmder/issues/574)
* windows 10 incompatibility [\#572](https://github.com/cmderdev/cmder/issues/572)
* FIX: Incorrect startup directory. [\#571](https://github.com/cmderdev/cmder/issues/571)
* WARNING: Enable-GitColors is Obsolete and will be removed in a future version of posh-git. [\#568](https://github.com/cmderdev/cmder/issues/568)
* Path issue on startup - Invalid download path [\#567](https://github.com/cmderdev/cmder/issues/567)
* The term 'vim' is not recognized [\#566](https://github.com/cmderdev/cmder/issues/566)
* Using .bashrc [\#565](https://github.com/cmderdev/cmder/issues/565)
* Persist tab "View \(palette\)" selection [\#562](https://github.com/cmderdev/cmder/issues/562)
* git add --interactive fails [\#560](https://github.com/cmderdev/cmder/issues/560)
* Tab names as directory names [\#559](https://github.com/cmderdev/cmder/issues/559)
* Downloads for v1.2 missing DLLs [\#558](https://github.com/cmderdev/cmder/issues/558)
* Can't get rid of "unrecognized parameter" error [\#557](https://github.com/cmderdev/cmder/issues/557)
* How to use cmder in a batch file? [\#556](https://github.com/cmderdev/cmder/issues/556)
* Run init.bat before any new scripts [\#554](https://github.com/cmderdev/cmder/issues/554)
* ssh not working [\#552](https://github.com/cmderdev/cmder/issues/552)
* Restore opened tabs setting opens root drive [\#551](https://github.com/cmderdev/cmder/issues/551)
* Maximize single view/terminal/console to whole window [\#550](https://github.com/cmderdev/cmder/issues/550)
* not run successfully [\#547](https://github.com/cmderdev/cmder/issues/547)
* compass not working with cmder ? [\#546](https://github.com/cmderdev/cmder/issues/546)
* Bad unicode support \(wrong glyphs on alsamixer\) [\#545](https://github.com/cmderdev/cmder/issues/545)
* can we use Vundle to manage Cmder's vim plugins? Need some setup? [\#535](https://github.com/cmderdev/cmder/issues/535)
* Error on Windows 7 [\#534](https://github.com/cmderdev/cmder/issues/534)
* api-ms-win-crt-runtime l1-109.dll is missing [\#531](https://github.com/cmderdev/cmder/issues/531)
* Git checks for 'commits' every time a folder is changed? [\#529](https://github.com/cmderdev/cmder/issues/529)
* PowerShell tab title issue [\#528](https://github.com/cmderdev/cmder/issues/528)
* conhost.exe keeps on crashing. [\#527](https://github.com/cmderdev/cmder/issues/527)
* storage in userprofile \(instead of fixed config dir relative to the executable\) [\#526](https://github.com/cmderdev/cmder/issues/526)
* Cmder crashes when AVG falsely flags it as a virus. [\#522](https://github.com/cmderdev/cmder/issues/522)
* Incomplete git installation packaged with cmder v1.2 [\#521](https://github.com/cmderdev/cmder/issues/521)
* api-ms-win-crt-runtime-l1-1-0.dll error [\#518](https://github.com/cmderdev/cmder/issues/518)
* Can't set alias in 1.2 anymore [\#515](https://github.com/cmderdev/cmder/issues/515)
* git not properly setup in v1.2 [\#513](https://github.com/cmderdev/cmder/issues/513)
* Character persistence on cmder windows [\#506](https://github.com/cmderdev/cmder/issues/506)
* Git: fatal: Unable to find remote helper for 'https' [\#503](https://github.com/cmderdev/cmder/issues/503)
* api-ms-win-crt-runtime-l1-1-0.dll error [\#501](https://github.com/cmderdev/cmder/issues/501)
* ncurses borders incorrectly displayed with ssh.exe [\#499](https://github.com/cmderdev/cmder/issues/499)
* gitk not found due to changed PATH for msysgit [\#498](https://github.com/cmderdev/cmder/issues/498)
* {hg} on every folder [\#494](https://github.com/cmderdev/cmder/issues/494)
* Missing dll, APPCRT140.dll [\#485](https://github.com/cmderdev/cmder/issues/485)
* Symantec refuses to access cmder [\#484](https://github.com/cmderdev/cmder/issues/484)
* Missing MSVCP140.dll [\#480](https://github.com/cmderdev/cmder/issues/480)
* Windows 10 compatibility issues [\#478](https://github.com/cmderdev/cmder/issues/478)
* update msysgit [\#473](https://github.com/cmderdev/cmder/issues/473)
* Notifications about composer.json and CRLF [\#472](https://github.com/cmderdev/cmder/issues/472)
* How to add more commands beyond mysisgit? [\#470](https://github.com/cmderdev/cmder/issues/470)
* ~ should mean user home directory [\#466](https://github.com/cmderdev/cmder/issues/466)
* mklink /d creates symlink with wrong slashes [\#462](https://github.com/cmderdev/cmder/issues/462)
* Does cmder come with GCC or not? [\#461](https://github.com/cmderdev/cmder/issues/461)
* Question: How to start cmder with a command [\#457](https://github.com/cmderdev/cmder/issues/457)
* PATH environment variable has space problem [\#456](https://github.com/cmderdev/cmder/issues/456)
* Feature Request : Save opened tabs and locations of the tabs [\#455](https://github.com/cmderdev/cmder/issues/455)
* Error on cmder launch: "The syntax of the command is incorrect" [\#454](https://github.com/cmderdev/cmder/issues/454)
* Lag returning to prompt \(especially\) in git repo [\#447](https://github.com/cmderdev/cmder/issues/447)
* 'MySQL' is not recognized as an internal or external command, operable program or batch file. [\#443](https://github.com/cmderdev/cmder/issues/443)
* Not scaling on Windows 8.1 with High-DPI Monitor [\#437](https://github.com/cmderdev/cmder/issues/437)
* Shortcut missing icon in context menu [\#433](https://github.com/cmderdev/cmder/issues/433)
* How to update Git? [\#428](https://github.com/cmderdev/cmder/issues/428)
* How to redirect Window's cmd.exe to Cmder's cmder.exe? [\#426](https://github.com/cmderdev/cmder/issues/426)
* cmder exits with exitcode 4294967295 [\#423](https://github.com/cmderdev/cmder/issues/423)
* How do you create an alias? [\#421](https://github.com/cmderdev/cmder/issues/421)
* Git pull not working [\#419](https://github.com/cmderdev/cmder/issues/419)
* Create files from cmder. [\#417](https://github.com/cmderdev/cmder/issues/417)
* Error popup window on opening [\#416](https://github.com/cmderdev/cmder/issues/416)
* Vim help not working in cmder [\#415](https://github.com/cmderdev/cmder/issues/415)
* How to update bash [\#399](https://github.com/cmderdev/cmder/issues/399)
* could you put the version number into the download file [\#396](https://github.com/cmderdev/cmder/issues/396)
* git-p4.py \[Errno 2\] No such file or directory [\#392](https://github.com/cmderdev/cmder/issues/392)
* ConEmu auto attach with Cmder aliases [\#388](https://github.com/cmderdev/cmder/issues/388)
* Cmder unable to find .ssh folder [\#387](https://github.com/cmderdev/cmder/issues/387)
* extra character appears at the beginning,when used the arrow keys\(up,down\) navigate through the history [\#384](https://github.com/cmderdev/cmder/issues/384)
* create alias with multi word parameter [\#376](https://github.com/cmderdev/cmder/issues/376)
* UI broken characters [\#375](https://github.com/cmderdev/cmder/issues/375)
* Possible to change TSA icon? [\#373](https://github.com/cmderdev/cmder/issues/373)
* Is Cmder known to cause a false positive alert from some virus checking software? [\#371](https://github.com/cmderdev/cmder/issues/371)
* How to disable the crosshair [\#369](https://github.com/cmderdev/cmder/issues/369)
* Text reflow and line selection [\#359](https://github.com/cmderdev/cmder/issues/359)
* Using the context menu doesn't open a new tab in Single Instance Mode [\#356](https://github.com/cmderdev/cmder/issues/356)
* Git client side vulnerability [\#354](https://github.com/cmderdev/cmder/issues/354)
* Ctrl+Shift+Arrow does not work as expected [\#345](https://github.com/cmderdev/cmder/issues/345)
* i can not read windows path in cmder [\#342](https://github.com/cmderdev/cmder/issues/342)
* How to reload system variable [\#340](https://github.com/cmderdev/cmder/issues/340)
* SVN commands support [\#339](https://github.com/cmderdev/cmder/issues/339)
* Is it possible to show the current folder in front of cursor on the current line? [\#338](https://github.com/cmderdev/cmder/issues/338)
* backspace not work [\#334](https://github.com/cmderdev/cmder/issues/334)
* 'awk' is not recognized [\#330](https://github.com/cmderdev/cmder/issues/330)
* Cannot pin 1.1.4.1 to Win7 taskbar [\#329](https://github.com/cmderdev/cmder/issues/329)
* {lamb} instead of lambda sign \(possibly a UTF-8 problem?\) [\#322](https://github.com/cmderdev/cmder/issues/322)
* Instructions refer to Cmder.bat but it doesn't exist in download .zip [\#319](https://github.com/cmderdev/cmder/issues/319)
* Wrong link on cmder.net for msysgit [\#317](https://github.com/cmderdev/cmder/issues/317)
* Use system-wide Git [\#315](https://github.com/cmderdev/cmder/issues/315)
* Version update information is broken \(not found\) [\#310](https://github.com/cmderdev/cmder/issues/310)
* feature request vim-airline [\#306](https://github.com/cmderdev/cmder/issues/306)
* Integrate PSReadLine [\#301](https://github.com/cmderdev/cmder/issues/301)
* Full Screen [\#295](https://github.com/cmderdev/cmder/issues/295)
* Configure PowerShell to match CMD [\#294](https://github.com/cmderdev/cmder/issues/294)
* Tab Close on CTRL-W [\#293](https://github.com/cmderdev/cmder/issues/293)
* v1.1.4.1 /REGISTER ALL has broken icon [\#292](https://github.com/cmderdev/cmder/issues/292)
* CD in root not working.. [\#289](https://github.com/cmderdev/cmder/issues/289)
* How to enable 256 color? [\#288](https://github.com/cmderdev/cmder/issues/288)
* Support comments in /config/aliases [\#286](https://github.com/cmderdev/cmder/issues/286)
* Executing linux executables ./ doesn't work :S [\#285](https://github.com/cmderdev/cmder/issues/285)
* Moved Documents folder, running "ls" gives "ls: My Documents: No such file or directory" [\#284](https://github.com/cmderdev/cmder/issues/284)
* er [\#283](https://github.com/cmderdev/cmder/issues/283)
* \[1.1.4.1\] Auto Completion not working [\#280](https://github.com/cmderdev/cmder/issues/280)
* Git and lamb macro/symbols not expanded in Windows 10 preview [\#279](https://github.com/cmderdev/cmder/issues/279)
* cmder vs cmd using non-blocking STDIN [\#269](https://github.com/cmderdev/cmder/issues/269)
* Possible to blur translucent console? [\#267](https://github.com/cmderdev/cmder/issues/267)
* Duplicate Root Fires Twice? [\#266](https://github.com/cmderdev/cmder/issues/266)
* bug when using up and down key [\#264](https://github.com/cmderdev/cmder/issues/264)
* ps scripts: support space in foldernames [\#261](https://github.com/cmderdev/cmder/issues/261)
* utils [\#260](https://github.com/cmderdev/cmder/issues/260)
* Character mix [\#259](https://github.com/cmderdev/cmder/issues/259)
* strange issue no trace in google [\#257](https://github.com/cmderdev/cmder/issues/257)
* Can't start cmder 1.4.1.1 [\#252](https://github.com/cmderdev/cmder/issues/252)
* Cmder icon reverts to ConEmu icon when "Startup options" option is changed [\#251](https://github.com/cmderdev/cmder/issues/251)
* Old version files in v1.1.4 release archives [\#247](https://github.com/cmderdev/cmder/issues/247)
* "MSVCP120.dll is missing from your computer." [\#246](https://github.com/cmderdev/cmder/issues/246)
* Cmder.exe not opening on Windows 7 SP 1 [\#240](https://github.com/cmderdev/cmder/issues/240)
* Resize Tab Bar [\#236](https://github.com/cmderdev/cmder/issues/236)
* Accented characters [\#234](https://github.com/cmderdev/cmder/issues/234)
* Clicking in the window causes cmder to lock up [\#232](https://github.com/cmderdev/cmder/issues/232)
* Add cmder to Windows context menu [\#231](https://github.com/cmderdev/cmder/issues/231)
* libiconv-2.dll is missing [\#228](https://github.com/cmderdev/cmder/issues/228)
* color scheme lost after CTRL+C on git status [\#227](https://github.com/cmderdev/cmder/issues/227)
* Can't create process, ErrCode=0x000000C1, Description: %1 is not a valid Win32 application. [\#226](https://github.com/cmderdev/cmder/issues/226)
* Cant get powerline fonts to work \(need utf-8?\) [\#225](https://github.com/cmderdev/cmder/issues/225)
* Can't use aliases + && [\#224](https://github.com/cmderdev/cmder/issues/224)
* {git}, {lamb} and strange new console options [\#223](https://github.com/cmderdev/cmder/issues/223)
* CJK problem [\#222](https://github.com/cmderdev/cmder/issues/222)
* Wire up 'title' to "rename tab" [\#221](https://github.com/cmderdev/cmder/issues/221)
* system PATH overriding path set in init.bat [\#219](https://github.com/cmderdev/cmder/issues/219)
* command autocompletion not working [\#218](https://github.com/cmderdev/cmder/issues/218)
* Launcher opens new window separately [\#217](https://github.com/cmderdev/cmder/issues/217)
* Theme not applied on Run command prompt here [\#216](https://github.com/cmderdev/cmder/issues/216)
* Closes tab on Ctrl-C action [\#215](https://github.com/cmderdev/cmder/issues/215)
* "Your alias cannot contain a space" [\#214](https://github.com/cmderdev/cmder/issues/214)
* Problems with vim colors [\#213](https://github.com/cmderdev/cmder/issues/213)
* lambda bug when i install clink [\#212](https://github.com/cmderdev/cmder/issues/212)
* Did doskey break in the newest dev update? [\#207](https://github.com/cmderdev/cmder/issues/207)
* Bug within the version of msysgit 1.8.5.2 [\#206](https://github.com/cmderdev/cmder/issues/206)
* Blank line [\#205](https://github.com/cmderdev/cmder/issues/205)
* F7 support for command history? [\#204](https://github.com/cmderdev/cmder/issues/204)
* SSH Keys and push passphrase [\#202](https://github.com/cmderdev/cmder/issues/202)
* git diff highlight colors on ssh [\#201](https://github.com/cmderdev/cmder/issues/201)
* Cursor becomes fat, and i can't do anything [\#200](https://github.com/cmderdev/cmder/issues/200)
* Open cmder as Tab from the file explorer [\#197](https://github.com/cmderdev/cmder/issues/197)
* include zsh and tmux from cygwin [\#194](https://github.com/cmderdev/cmder/issues/194)
* How to enable ssh-agent? [\#193](https://github.com/cmderdev/cmder/issues/193)
* Git Not working [\#192](https://github.com/cmderdev/cmder/issues/192)
* Open cmder in 64-bit on 64-bit windows [\#191](https://github.com/cmderdev/cmder/issues/191)
* Output is very slow [\#188](https://github.com/cmderdev/cmder/issues/188)
* Running cmder from the file explorer [\#187](https://github.com/cmderdev/cmder/issues/187)
* Add hotkey to switch tabs [\#186](https://github.com/cmderdev/cmder/issues/186)
* how to config installed msysgit [\#183](https://github.com/cmderdev/cmder/issues/183)
* Windows 8.1 High-DPI Scaling [\#182](https://github.com/cmderdev/cmder/issues/182)
* how to disabled command line error beep? [\#179](https://github.com/cmderdev/cmder/issues/179)
* Child shells yields broken prompt [\#178](https://github.com/cmderdev/cmder/issues/178)
* Crash at start on Windows 8.1 [\#176](https://github.com/cmderdev/cmder/issues/176)
* Crashes with mintty.exe [\#175](https://github.com/cmderdev/cmder/issues/175)
* Chinese characters looked terribly awful when monospace is checked [\#171](https://github.com/cmderdev/cmder/issues/171)
* Copy and paste w/ mouse buttons [\#170](https://github.com/cmderdev/cmder/issues/170)
* generation of Pipe symbol not possible [\#168](https://github.com/cmderdev/cmder/issues/168)
* Lambda prompt bug [\#164](https://github.com/cmderdev/cmder/issues/164)
* Can't select and copy text [\#163](https://github.com/cmderdev/cmder/issues/163)
* not running in windows XP SP3 [\#161](https://github.com/cmderdev/cmder/issues/161)
* german characters not displaying [\#160](https://github.com/cmderdev/cmder/issues/160)
* Moving files with ../ [\#158](https://github.com/cmderdev/cmder/issues/158)
* Transparent image. A Detail but I would like to get it to work [\#156](https://github.com/cmderdev/cmder/issues/156)
* Taskbar icon after pinning the program reverts to default ConEmu icon. Systray icon is always ConEmu's. [\#154](https://github.com/cmderdev/cmder/issues/154)
* A neat way to add sublime text seamlessly. [\#153](https://github.com/cmderdev/cmder/issues/153)
* how to update cygwin shipped together within cmder [\#151](https://github.com/cmderdev/cmder/issues/151)
* attach to GUI was requested, but there is no console processes! [\#150](https://github.com/cmderdev/cmder/issues/150)
* The system cannot find the path specified. [\#148](https://github.com/cmderdev/cmder/issues/148)
* Changes to PATH do not persist [\#146](https://github.com/cmderdev/cmder/issues/146)
* git clone templates not found / Unable to find remote helper for 'https' [\#144](https://github.com/cmderdev/cmder/issues/144)
* handle could not be opened / terminal is not fully functional [\#143](https://github.com/cmderdev/cmder/issues/143)
* Create windows installer [\#142](https://github.com/cmderdev/cmder/issues/142)
* Auto-create fast new tab shortcuts for additional tasks [\#140](https://github.com/cmderdev/cmder/issues/140)
* ssh-agent, ssh-add, ssh all crash as soon as I open a PowerShell window [\#139](https://github.com/cmderdev/cmder/issues/139)
* Problems using cmder as an SSH client [\#137](https://github.com/cmderdev/cmder/issues/137)
* Add link to bliker.github.io/cmder to repo description/website [\#134](https://github.com/cmderdev/cmder/issues/134)
* Environmental variables are not reloaded on new console [\#132](https://github.com/cmderdev/cmder/issues/132)
* Git Branch Autocomplete [\#130](https://github.com/cmderdev/cmder/issues/130)
* The nice lambda left me :\( [\#129](https://github.com/cmderdev/cmder/issues/129)
* `ls` with output redirection writes ansi escape sequences to destination file [\#127](https://github.com/cmderdev/cmder/issues/127)
* Lamba prompt and git status scripts not running [\#126](https://github.com/cmderdev/cmder/issues/126)
* how to open specail directory? in sublime Terminal plugin? [\#123](https://github.com/cmderdev/cmder/issues/123)
* clink installed allready cmder hangs after install [\#122](https://github.com/cmderdev/cmder/issues/122)
* "The system cannot find the path specified" [\#121](https://github.com/cmderdev/cmder/issues/121)
* "chcp 65001" \(UTF-8\) support for cmd [\#119](https://github.com/cmderdev/cmder/issues/119)
* Incorrect version of clink is being used [\#117](https://github.com/cmderdev/cmder/issues/117)
* .bash_profile equivalent? [\#113](https://github.com/cmderdev/cmder/issues/113)
* Startup directory on new tab [\#112](https://github.com/cmderdev/cmder/issues/112)
* Looking for a contributor/Cmder user [\#110](https://github.com/cmderdev/cmder/issues/110)
* Terminate batch job bug \(I think?\) [\#108](https://github.com/cmderdev/cmder/issues/108)
* latin1 characters [\#107](https://github.com/cmderdev/cmder/issues/107)
* Script cleanup [\#105](https://github.com/cmderdev/cmder/issues/105)
* Changed "λ" to "?" [\#104](https://github.com/cmderdev/cmder/issues/104)
* How to search history using PgUp and PgDown [\#103](https://github.com/cmderdev/cmder/issues/103)
* Folder shortcuts doesn't seem to work in FAR manager under cmder [\#102](https://github.com/cmderdev/cmder/issues/102)
* opening cmder.bat on windows 8 [\#101](https://github.com/cmderdev/cmder/issues/101)
* Change the builder from google code [\#99](https://github.com/cmderdev/cmder/issues/99)
* Text color not honored upon restart [\#97](https://github.com/cmderdev/cmder/issues/97)
* Launcher is not recognized as a valid Win32 application on windows XP. [\#96](https://github.com/cmderdev/cmder/issues/96)
* Allow the launcher to be pinned to the taskbar [\#95](https://github.com/cmderdev/cmder/issues/95)
* VS2013 runtime requirement [\#93](https://github.com/cmderdev/cmder/issues/93)
* git flow [\#92](https://github.com/cmderdev/cmder/issues/92)
* How to start in a given directory [\#91](https://github.com/cmderdev/cmder/issues/91)
* Can't type backslash \(clink issue\) [\#89](https://github.com/cmderdev/cmder/issues/89)
* command history [\#87](https://github.com/cmderdev/cmder/issues/87)
* Install cmder [\#86](https://github.com/cmderdev/cmder/issues/86)
* Can not work well with Chinese [\#81](https://github.com/cmderdev/cmder/issues/81)
* Does not work with Julia [\#80](https://github.com/cmderdev/cmder/issues/80)
* Build script does not work through proxy [\#79](https://github.com/cmderdev/cmder/issues/79)
* "C:\Users\bliker" reference in config/ConEmu.xml [\#71](https://github.com/cmderdev/cmder/issues/71)
* Is it possible to install wget into cmder\(clink, or ConEmu\) ? [\#69](https://github.com/cmderdev/cmder/issues/69)
* cyrillic characters problem [\#68](https://github.com/cmderdev/cmder/issues/68)
* Unable to run in Windows XP if path contains spaces [\#67](https://github.com/cmderdev/cmder/issues/67)
* Path not set correctly on Windows XP [\#66](https://github.com/cmderdev/cmder/issues/66)
* Filenames with special characters e.g. ! are not handled correctly [\#64](https://github.com/cmderdev/cmder/issues/64)
* Clink completion does not work [\#59](https://github.com/cmderdev/cmder/issues/59)
* Git hosts defined in .ssh/config not working in cmder [\#58](https://github.com/cmderdev/cmder/issues/58)
* Setting cmder startup directory. [\#57](https://github.com/cmderdev/cmder/issues/57)
* cmder doesn't work with gvim [\#55](https://github.com/cmderdev/cmder/issues/55)
* vendor\msysgit\libexec\git-core dir contains 1.45mb git.exe duplicated 110 times. [\#54](https://github.com/cmderdev/cmder/issues/54)
* "terminal is not fully functional" [\#50](https://github.com/cmderdev/cmder/issues/50)
* Open new tab as Admin by default. [\#49](https://github.com/cmderdev/cmder/issues/49)
* Chinese characters overlapped [\#45](https://github.com/cmderdev/cmder/issues/45)
* `screen irssi`, `mutt` - Cannot find terminfo entry for 'msys'. [\#44](https://github.com/cmderdev/cmder/issues/44)
* ps doesn't work [\#43](https://github.com/cmderdev/cmder/issues/43)
* Pinning Cmder to taskbar doesn't work as expected [\#39](https://github.com/cmderdev/cmder/issues/39)
* Prompt does not work with clink 0.4 [\#35](https://github.com/cmderdev/cmder/issues/35)
* vendor/init.bat fails on paths with spaces [\#28](https://github.com/cmderdev/cmder/issues/28)
* "windows cannot find ...\cmder\vendor/ConEmu-maximus5/ConEmu.exe" [\#27](https://github.com/cmderdev/cmder/issues/27)
* Issue with SSH and tmux [\#25](https://github.com/cmderdev/cmder/issues/25)
* PWD, VI, VIM commands don't work on windows 7. [\#23](https://github.com/cmderdev/cmder/issues/23)
* Include icon [\#21](https://github.com/cmderdev/cmder/issues/21)
* init.bat failing on Vista x64 [\#19](https://github.com/cmderdev/cmder/issues/19)
* Not possible to write @ on Norwegian keyboard [\#17](https://github.com/cmderdev/cmder/issues/17)
* Weird output when starting cmder [\#16](https://github.com/cmderdev/cmder/issues/16)
* Set a name for the Tab on a task [\#14](https://github.com/cmderdev/cmder/issues/14)
* Git branch name [\#13](https://github.com/cmderdev/cmder/issues/13)
* bin directories not loaded in path [\#12](https://github.com/cmderdev/cmder/issues/12)
* Cmder ssh keys for github [\#11](https://github.com/cmderdev/cmder/issues/11)
* How to use cmder with integration mode [\#10](https://github.com/cmderdev/cmder/issues/10)
* tab manipulation problem [\#9](https://github.com/cmderdev/cmder/issues/9)
* Remove ugly black startup window [\#8](https://github.com/cmderdev/cmder/issues/8)
* Unable to `cd` to another drive [\#6](https://github.com/cmderdev/cmder/issues/6)
* cant change start directory [\#4](https://github.com/cmderdev/cmder/issues/4)
* lalt + arrow left/right not working as a macro hotkey [\#3](https://github.com/cmderdev/cmder/issues/3)
* alt gr + 2 opens new PowerShell [\#2](https://github.com/cmderdev/cmder/issues/2)
* Gvim preferences are not used in {cmd} [\#1](https://github.com/cmderdev/cmder/issues/1)

**Merged pull requests:**

* Development [\#1169](https://github.com/cmderdev/cmder/pull/1169) ([Stanzilla](https://github.com/Stanzilla))
* Fix typo in init.bat [\#1157](https://github.com/cmderdev/cmder/pull/1157) ([winks](https://github.com/winks))
* Bump clink-completions to 0.3.2 [\#1153](https://github.com/cmderdev/cmder/pull/1153) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Fixed 3 typos [\#1143](https://github.com/cmderdev/cmder/pull/1143) ([panzer-planet](https://github.com/panzer-planet))
* Fix for slow startup under certain conditions \(\#1122\) [\#1131](https://github.com/cmderdev/cmder/pull/1131) ([lamarqua](https://github.com/lamarqua))
* Development [\#1127](https://github.com/cmderdev/cmder/pull/1127) ([Stanzilla](https://github.com/Stanzilla))
* fix error when path has a space [\#1126](https://github.com/cmderdev/cmder/pull/1126) ([gucong3000](https://github.com/gucong3000))
* Added closing process in get_git_status [\#1101](https://github.com/cmderdev/cmder/pull/1101) ([alexandr-san4ez](https://github.com/alexandr-san4ez))
* Update Readme.md [\#1082](https://github.com/cmderdev/cmder/pull/1082) ([nverno](https://github.com/nverno))
* Fix bash login when $CMDER_ROOT has spaces [\#1078](https://github.com/cmderdev/cmder/pull/1078) ([orionlee](https://github.com/orionlee))
* Parse the original prompt for cwd and env names [\#1070](https://github.com/cmderdev/cmder/pull/1070) ([janschulz](https://github.com/janschulz))
* Added kill ssh-agent to build.ps1 [\#1042](https://github.com/cmderdev/cmder/pull/1042) ([daxgames](https://github.com/daxgames))
* Development [\#1037](https://github.com/cmderdev/cmder/pull/1037) ([Stanzilla](https://github.com/Stanzilla))
* Minor update in README.md [\#1016](https://github.com/cmderdev/cmder/pull/1016) ([Mansuro](https://github.com/Mansuro))
* Added rainbow icons [\#1014](https://github.com/cmderdev/cmder/pull/1014) ([JoshuaKGoldberg](https://github.com/JoshuaKGoldberg))
* Fix git branch colouring [\#1011](https://github.com/cmderdev/cmder/pull/1011) ([MoFo88](https://github.com/MoFo88))
* Bump clink-completions to 0.3.1 [\#992](https://github.com/cmderdev/cmder/pull/992) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Fix git branch name never shown as dirty [\#974](https://github.com/cmderdev/cmder/pull/974) ([janschulz](https://github.com/janschulz))
* Disable history switching behavior of ctrl+tab. Sequential switching. [\#963](https://github.com/cmderdev/cmder/pull/963) ([Jackbennett](https://github.com/Jackbennett))
* Register cmder in the context menu from PowerShell [\#962](https://github.com/cmderdev/cmder/pull/962) ([Jackbennett](https://github.com/Jackbennett))
* cmd: change the prompt in lua [\#961](https://github.com/cmderdev/cmder/pull/961) ([janschulz](https://github.com/janschulz))
* Custom prompt hooks protected from later overwriting [\#952](https://github.com/cmderdev/cmder/pull/952) ([Jackbennett](https://github.com/Jackbennett))
* Update clink-completions to 0.3.0 [\#946](https://github.com/cmderdev/cmder/pull/946) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Added :verbose-output subroutine, made aliases update more functional [\#945](https://github.com/cmderdev/cmder/pull/945) ([daxgames](https://github.com/daxgames))
* fixed git not working in cmder cmd session and added some comments [\#943](https://github.com/cmderdev/cmder/pull/943) ([daxgames](https://github.com/daxgames))
* More variable quoting in init.bat [\#941](https://github.com/cmderdev/cmder/pull/941) ([janschulz](https://github.com/janschulz))
* Add quotes around all variables [\#940](https://github.com/cmderdev/cmder/pull/940) ([janschulz](https://github.com/janschulz))
* Fix missing "\" when building dirpath to psmodules [\#916](https://github.com/cmderdev/cmder/pull/916) ([liftir](https://github.com/liftir))
* upgraded git to 2.8.1 [\#911](https://github.com/cmderdev/cmder/pull/911) ([daxgames](https://github.com/daxgames))
* Added proxy support [\#909](https://github.com/cmderdev/cmder/pull/909) ([daxgames](https://github.com/daxgames))
* fixed - not running user-aliases.cmd if aliases variable is overridde… [\#892](https://github.com/cmderdev/cmder/pull/892) ([daxgames](https://github.com/daxgames))
* Merge latest Development [\#890](https://github.com/cmderdev/cmder/pull/890) ([MartiUK](https://github.com/MartiUK))
* Process profile.d scripts before adding user aliases [\#874](https://github.com/cmderdev/cmder/pull/874) ([daxgames](https://github.com/daxgames))
* Prefer use of first line @echo off vs. @ per line to turn off echo pe… [\#873](https://github.com/cmderdev/cmder/pull/873) ([daxgames](https://github.com/daxgames))
* silenced bash profile.d when profile.d is empty [\#872](https://github.com/cmderdev/cmder/pull/872) ([daxgames](https://github.com/daxgames))
* Various fixes for profile.d support [\#867](https://github.com/cmderdev/cmder/pull/867) ([daxgames](https://github.com/daxgames))
* Revert "Set CMDER_START to homeprofile" [\#866](https://github.com/cmderdev/cmder/pull/866) ([janschulz](https://github.com/janschulz))
* better git path handling [\#865](https://github.com/cmderdev/cmder/pull/865) ([janschulz](https://github.com/janschulz))
* Enhanced alias.bat to allow file storage path [\#862](https://github.com/cmderdev/cmder/pull/862) ([daxgames](https://github.com/daxgames))
* Fix cmd plugin.d [\#860](https://github.com/cmderdev/cmder/pull/860) ([daxgames](https://github.com/daxgames))
* Added profile.d like support for all supported shells [\#855](https://github.com/cmderdev/cmder/pull/855) ([daxgames](https://github.com/daxgames))
* Typo in Readme.md [\#852](https://github.com/cmderdev/cmder/pull/852) ([janschulz](https://github.com/janschulz))
* Fixed get_git_dir\(\) to take submodules into account. Fixes \#833 [\#841](https://github.com/cmderdev/cmder/pull/841) ([gpakosz](https://github.com/gpakosz))
* Add appveyor batch to README [\#837](https://github.com/cmderdev/cmder/pull/837) ([janschulz](https://github.com/janschulz))
* Fixed checkGit\(\) in case of submodules [\#835](https://github.com/cmderdev/cmder/pull/835) ([gpakosz](https://github.com/gpakosz))
* 1.3 Pre-Release Merge [\#831](https://github.com/cmderdev/cmder/pull/831) ([MartiUK](https://github.com/MartiUK))
* Fix build script not exiting on msbuild failure. [\#804](https://github.com/cmderdev/cmder/pull/804) ([MartiUK](https://github.com/MartiUK))
* Set tasks to always use CMDER_START [\#803](https://github.com/cmderdev/cmder/pull/803) ([MartiUK](https://github.com/MartiUK))
* Make "cmder here" work again [\#798](https://github.com/cmderdev/cmder/pull/798) ([janschulz](https://github.com/janschulz))
* Reorganize how clink settings are loaded [\#794](https://github.com/cmderdev/cmder/pull/794) ([janschulz](https://github.com/janschulz))
* Bump clink to 0.4.6 [\#781](https://github.com/cmderdev/cmder/pull/781) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Fix vendor/init.bat when the PATH contains spaces. [\#773](https://github.com/cmderdev/cmder/pull/773) ([glureau](https://github.com/glureau))
* Merge latest development [\#771](https://github.com/cmderdev/cmder/pull/771) ([MartiUK](https://github.com/MartiUK))
* Bump clink-completions to 0.2.2 [\#766](https://github.com/cmderdev/cmder/pull/766) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Fix: don't garble the input line for long lines in git projects [\#756](https://github.com/cmderdev/cmder/pull/756) ([janschulz](https://github.com/janschulz))
* README.md Updates [\#746](https://github.com/cmderdev/cmder/pull/746) ([daxgames](https://github.com/daxgames))
* Cmder exinit [\#740](https://github.com/cmderdev/cmder/pull/740) ([daxgames](https://github.com/daxgames))
* added config\user-\* to packignore [\#738](https://github.com/cmderdev/cmder/pull/738) ([daxgames](https://github.com/daxgames))
* Use consistent naming: user-profile.{sh|bat|ps1} [\#737](https://github.com/cmderdev/cmder/pull/737) ([janschulz](https://github.com/janschulz))
* More config [\#736](https://github.com/cmderdev/cmder/pull/736) ([janschulz](https://github.com/janschulz))
* Do not overwrite aliases on update [\#735](https://github.com/cmderdev/cmder/pull/735) ([janschulz](https://github.com/janschulz))
* Added check for git install path in init.bat. [\#734](https://github.com/cmderdev/cmder/pull/734) ([chase-miller](https://github.com/chase-miller))
* Fix icons [\#731](https://github.com/cmderdev/cmder/pull/731) ([daxgames](https://github.com/daxgames))
* Fixed - PowerShell vim/vim alias opening a new tab when editing a file [\#729](https://github.com/cmderdev/cmder/pull/729) ([daxgames](https://github.com/daxgames))
* Added vi/vim aliases and fixed PowerShell startup errors [\#726](https://github.com/cmderdev/cmder/pull/726) ([daxgames](https://github.com/daxgames))
* Release 1.3 [\#723](https://github.com/cmderdev/cmder/pull/723) ([MartiUK](https://github.com/MartiUK))
* Update to ConEmu 151119 [\#722](https://github.com/cmderdev/cmder/pull/722) ([MartiUK](https://github.com/MartiUK))
* Disable appveyor test search [\#720](https://github.com/cmderdev/cmder/pull/720) ([MartiUK](https://github.com/MartiUK))
* Fix gitter webhook [\#719](https://github.com/cmderdev/cmder/pull/719) ([MartiUK](https://github.com/MartiUK))
* Publish appveyor artefacts [\#718](https://github.com/cmderdev/cmder/pull/718) ([MartiUK](https://github.com/MartiUK))
* add bundled vim to path [\#705](https://github.com/cmderdev/cmder/pull/705) ([wenzowski](https://github.com/wenzowski))
* Fix batch files [\#698](https://github.com/cmderdev/cmder/pull/698) ([daxgames](https://github.com/daxgames))
* Speed up git prompt filtering [\#697](https://github.com/cmderdev/cmder/pull/697) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Upgrade clink-completions to 0.2.1 [\#676](https://github.com/cmderdev/cmder/pull/676) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Enable the '/single' switch \(\#577\) [\#673](https://github.com/cmderdev/cmder/pull/673) ([DoCode](https://github.com/DoCode))
* Fixed problem with Invoke-Expression [\#667](https://github.com/cmderdev/cmder/pull/667) ([Pireax](https://github.com/Pireax))
* Add user startup file for PowerShell [\#666](https://github.com/cmderdev/cmder/pull/666) ([Pireax](https://github.com/Pireax))
* Build from behind proxy & appveyor [\#665](https://github.com/cmderdev/cmder/pull/665) ([MartiUK](https://github.com/MartiUK))
* Fix init.bat generation [\#663](https://github.com/cmderdev/cmder/pull/663) ([janschulz](https://github.com/janschulz))
* Upgrade clink-completions to 0.2.0 [\#653](https://github.com/cmderdev/cmder/pull/653) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Make wording clearer [\#652](https://github.com/cmderdev/cmder/pull/652) ([jkingsman](https://github.com/jkingsman))
* fix typos and better phrasing [\#651](https://github.com/cmderdev/cmder/pull/651) ([jkingsman](https://github.com/jkingsman))
* Revert 8b8f98c [\#634](https://github.com/cmderdev/cmder/pull/634) ([Stanzilla](https://github.com/Stanzilla))
* Update clink to 0.4.5 [\#619](https://github.com/cmderdev/cmder/pull/619) ([Stanzilla](https://github.com/Stanzilla))
* Add a user startup file which can be modified [\#612](https://github.com/cmderdev/cmder/pull/612) ([janschulz](https://github.com/janschulz))
* Update README.md [\#606](https://github.com/cmderdev/cmder/pull/606) ([pyprism](https://github.com/pyprism))
* Converting msysgit support to git-for-windows support. [\#605](https://github.com/cmderdev/cmder/pull/605) ([Stanzilla](https://github.com/Stanzilla))
* :arrow_up: ConEmu@150816 [\#601](https://github.com/cmderdev/cmder/pull/601) ([Stanzilla](https://github.com/Stanzilla))
* Use standard path for ConEmu.xml [\#600](https://github.com/cmderdev/cmder/pull/600) ([Maximus5](https://github.com/Maximus5))
* Revert "Run PowerShell as default" [\#585](https://github.com/cmderdev/cmder/pull/585) ([Stanzilla](https://github.com/Stanzilla))
* update VS to 2015 release version and switch to /MT for static linking [\#578](https://github.com/cmderdev/cmder/pull/578) ([Stanzilla](https://github.com/Stanzilla))
* Enhance Path in profile.ps1 [\#575](https://github.com/cmderdev/cmder/pull/575) ([Bobo1239](https://github.com/Bobo1239))
* Fixed: 'Enable-GitColors is Obsolete...' warning [\#569](https://github.com/cmderdev/cmder/pull/569) ([eeree](https://github.com/eeree))
* Update .gitignore [\#548](https://github.com/cmderdev/cmder/pull/548) ([thomgit](https://github.com/thomgit))
* Add `-ExecutionPolicy Bypass` to PowerShell tasks [\#543](https://github.com/cmderdev/cmder/pull/543) ([malobre](https://github.com/malobre))
* Remove depreciated Enable-GitColors in posh-git [\#517](https://github.com/cmderdev/cmder/pull/517) ([bondz](https://github.com/bondz))
* Fix cleanup script. [\#479](https://github.com/cmderdev/cmder/pull/479) ([MartiUK](https://github.com/MartiUK))
* Fix link to msysgit's site. Google's repo was moved or removed. [\#465](https://github.com/cmderdev/cmder/pull/465) ([TheMolkaPL](https://github.com/TheMolkaPL))
* Update sources.json [\#451](https://github.com/cmderdev/cmder/pull/451) ([MartiUK](https://github.com/MartiUK))
* Merge development into master for 1.2 [\#450](https://github.com/cmderdev/cmder/pull/450) ([MartiUK](https://github.com/MartiUK))
* Helper function using PowerShell to register the cmder context menu [\#441](https://github.com/cmderdev/cmder/pull/441) ([Jackbennett](https://github.com/Jackbennett))
* git and Posh-git check [\#440](https://github.com/cmderdev/cmder/pull/440) ([Jackbennett](https://github.com/Jackbennett))
* Improves performance of prompt filtering [\#438](https://github.com/cmderdev/cmder/pull/438) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Preview PR for including external completions into Cmder [\#434](https://github.com/cmderdev/cmder/pull/434) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Revert new line from commit dc834cc28f [\#432](https://github.com/cmderdev/cmder/pull/432) ([Jackbennett](https://github.com/Jackbennett))
* Leverage the Module Autoload path and save doing it ourselves. [\#431](https://github.com/cmderdev/cmder/pull/431) ([Jackbennett](https://github.com/Jackbennett))
* Adds support for PS 4.0 native hash command to remove a dependency [\#430](https://github.com/cmderdev/cmder/pull/430) ([Jackbennett](https://github.com/Jackbennett))
* Fix build script removing a trailing comma. Download into a temp folder. [\#429](https://github.com/cmderdev/cmder/pull/429) ([Jackbennett](https://github.com/Jackbennett))
* Update clink url [\#425](https://github.com/cmderdev/cmder/pull/425) ([danneu](https://github.com/danneu))
* Added git shell task. [\#422](https://github.com/cmderdev/cmder/pull/422) ([ragekit](https://github.com/ragekit))
* Public site docs update matching the repo readme [\#411](https://github.com/cmderdev/cmder/pull/411) ([Jackbennett](https://github.com/Jackbennett))
* Install steps clarity [\#410](https://github.com/cmderdev/cmder/pull/410) ([Jackbennett](https://github.com/Jackbennett))
* Update ConEmu \<preview release\>, update clink 4.4 [\#407](https://github.com/cmderdev/cmder/pull/407) ([Jackbennett](https://github.com/Jackbennett))
* Use a -Full parameter to download all sources rather than the minimum [\#406](https://github.com/cmderdev/cmder/pull/406) ([Jackbennett](https://github.com/Jackbennett))
* Adding mercuial prompt [\#401](https://github.com/cmderdev/cmder/pull/401) ([utek](https://github.com/utek))
* Handle quoted paths [\#398](https://github.com/cmderdev/cmder/pull/398) ([mikesigs](https://github.com/mikesigs))
* Add a Gitter chat badge to README.md [\#390](https://github.com/cmderdev/cmder/pull/390) ([gitter-badger](https://github.com/gitter-badger))
* Support UTF-8 file list [\#378](https://github.com/cmderdev/cmder/pull/378) ([asika32764](https://github.com/asika32764))
* Updated vendor references [\#374](https://github.com/cmderdev/cmder/pull/374) ([CumpsD](https://github.com/CumpsD))
* Prefer user installed git over cmder one. [\#364](https://github.com/cmderdev/cmder/pull/364) ([narnaud](https://github.com/narnaud))
* Update clink to latest \(0.4.3\) version [\#362](https://github.com/cmderdev/cmder/pull/362) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Rework `alias` command to not to use external tools [\#358](https://github.com/cmderdev/cmder/pull/358) ([vladimir-kotikov](https://github.com/vladimir-kotikov))
* Updating to msysgit 1.9.5 [\#353](https://github.com/cmderdev/cmder/pull/353) ([Celeo](https://github.com/Celeo))
* Adding script to enable SSH-agent \#193 [\#352](https://github.com/cmderdev/cmder/pull/352) ([ogrim](https://github.com/ogrim))
* Docs update for issue \#319 [\#337](https://github.com/cmderdev/cmder/pull/337) ([Jackbennett](https://github.com/Jackbennett))
* changes copied from PR\#256 [\#326](https://github.com/cmderdev/cmder/pull/326) ([kohenkatz](https://github.com/kohenkatz))
* Border less window mode [\#324](https://github.com/cmderdev/cmder/pull/324) ([cgrail](https://github.com/cgrail))
* Update alias.bat to show an existing alias [\#314](https://github.com/cmderdev/cmder/pull/314) ([glucas](https://github.com/glucas))
* Add an unalias command [\#313](https://github.com/cmderdev/cmder/pull/313) ([glucas](https://github.com/glucas))
* Revert "Add single mode support." [\#312](https://github.com/cmderdev/cmder/pull/312) ([MartiUK](https://github.com/MartiUK))
* FIX CMDER_ROOT for admin launch [\#311](https://github.com/cmderdev/cmder/pull/311) ([sescandell](https://github.com/sescandell))
* Lambda color in PowerShell was changed to DarkGray [\#308](https://github.com/cmderdev/cmder/pull/308) ([SheGe](https://github.com/SheGe))
* Add option to reload aliases from file [\#304](https://github.com/cmderdev/cmder/pull/304) ([glucas](https://github.com/glucas))
* Clean aliases script [\#300](https://github.com/cmderdev/cmder/pull/300) ([melku](https://github.com/melku))
* Adding history alias [\#299](https://github.com/cmderdev/cmder/pull/299) ([robgithub](https://github.com/robgithub))
* Fixes the ambiguity about notice and parameter [\#298](https://github.com/cmderdev/cmder/pull/298) ([LeoColomb](https://github.com/LeoColomb))
* Fixed small issue in README [\#296](https://github.com/cmderdev/cmder/pull/296) ([brunowego](https://github.com/brunowego))
* Fixes small PowerShell' loader issues [\#273](https://github.com/cmderdev/cmder/pull/273) ([LeoColomb](https://github.com/LeoColomb))
* Update Dev Branch [\#272](https://github.com/cmderdev/cmder/pull/272) ([MartiUK](https://github.com/MartiUK))
* Add custom loader for PowerShell & improve its implementation [\#271](https://github.com/cmderdev/cmder/pull/271) ([LeoColomb](https://github.com/LeoColomb))
* Add single mode support. [\#256](https://github.com/cmderdev/cmder/pull/256) ([TheCjw](https://github.com/TheCjw))
* Revert "Start in the HOME folder." [\#253](https://github.com/cmderdev/cmder/pull/253) ([MartiUK](https://github.com/MartiUK))
* Ensure-Exists is necessary for build.ps1, add it back. [\#249](https://github.com/cmderdev/cmder/pull/249) ([narnaud](https://github.com/narnaud))
* Fix clink version [\#244](https://github.com/cmderdev/cmder/pull/244) ([narnaud](https://github.com/narnaud))
* Start in the HOME folder. [\#243](https://github.com/cmderdev/cmder/pull/243) ([narnaud](https://github.com/narnaud))
* The latest msysgit comes with vim 7.4. [\#241](https://github.com/cmderdev/cmder/pull/241) ([narnaud](https://github.com/narnaud))
* Bump versions [\#208](https://github.com/cmderdev/cmder/pull/208) ([MartiUK](https://github.com/MartiUK))
* New section for user help with an integration feature of Cmder. [\#199](https://github.com/cmderdev/cmder/pull/199) ([Jackbennett](https://github.com/Jackbennett))
* Fix typos [\#198](https://github.com/cmderdev/cmder/pull/198) ([mtsk](https://github.com/mtsk))
* Update Clink URL [\#180](https://github.com/cmderdev/cmder/pull/180) ([CoolOppo](https://github.com/CoolOppo))
* Try to find 7-zip if it's installed before an error. [\#177](https://github.com/cmderdev/cmder/pull/177) ([Jackbennett](https://github.com/Jackbennett))
* Update clink hyperlink [\#173](https://github.com/cmderdev/cmder/pull/173) ([gmsantos](https://github.com/gmsantos))
* Typo fix [\#172](https://github.com/cmderdev/cmder/pull/172) ([robinbijlani](https://github.com/robinbijlani))
* Only cd to $HOME if started in CMDER_ROOT. [\#167](https://github.com/cmderdev/cmder/pull/167) ([schlamar](https://github.com/schlamar))
* Find cmder files when running as Administrator. [\#166](https://github.com/cmderdev/cmder/pull/166) ([glucas](https://github.com/glucas))
* Allow for existing HOME variable [\#165](https://github.com/cmderdev/cmder/pull/165) ([glucas](https://github.com/glucas))
* Minor changes for \#152 [\#162](https://github.com/cmderdev/cmder/pull/162) ([Jackbennett](https://github.com/Jackbennett))
* Add registration for right-click on folder item; Add context-menu icon [\#159](https://github.com/cmderdev/cmder/pull/159) ([kohenkatz](https://github.com/kohenkatz))
* Getting the build script to a working state [\#157](https://github.com/cmderdev/cmder/pull/157) ([Jackbennett](https://github.com/Jackbennett))
* Update index.html [\#145](https://github.com/cmderdev/cmder/pull/145) ([CoolOppo](https://github.com/CoolOppo))
* Update fast new tab shortcut in gh-pages/index.html [\#131](https://github.com/cmderdev/cmder/pull/131) ([sopel](https://github.com/sopel))
* Update links on the webpage to latest version. [\#111](https://github.com/cmderdev/cmder/pull/111) ([sc0tt](https://github.com/sc0tt))
* Update fast new tab shortcut in README. [\#98](https://github.com/cmderdev/cmder/pull/98) ([jcheng31](https://github.com/jcheng31))
* Make application use Cmder icon [\#88](https://github.com/cmderdev/cmder/pull/88) ([sc0tt](https://github.com/sc0tt))
* Git exe Cleanup. [\#85](https://github.com/cmderdev/cmder/pull/85) ([MartiUK](https://github.com/MartiUK))
* Fixed errors and grammar in README files. [\#78](https://github.com/cmderdev/cmder/pull/78) ([sicil1ano](https://github.com/sicil1ano))
* Fixed a couple tiny typos in the readme [\#77](https://github.com/cmderdev/cmder/pull/77) ([jdsumsion](https://github.com/jdsumsion))
* Change TERM from msys to cygwin. [\#75](https://github.com/cmderdev/cmder/pull/75) ([brkc](https://github.com/brkc))
* Removed "C:\Users\bliker" reference in config/ConEmu.xml [\#74](https://github.com/cmderdev/cmder/pull/74) ([MartiUK](https://github.com/MartiUK))
* Updated links on gh-pages to newer release of cmder [\#70](https://github.com/cmderdev/cmder/pull/70) ([MartiUK](https://github.com/MartiUK))
* Add launcher [\#62](https://github.com/cmderdev/cmder/pull/62) ([austinwagner](https://github.com/austinwagner))
* Remove wget dependency and verify existence of 7z.exe in build script [\#60](https://github.com/cmderdev/cmder/pull/60) ([austinwagner](https://github.com/austinwagner))
* Allow use of Vim from msysgit. [\#51](https://github.com/cmderdev/cmder/pull/51) ([MartiUK](https://github.com/MartiUK))
* Fix line ending handling if autocrlf is false. [\#34](https://github.com/cmderdev/cmder/pull/34) ([schlamar](https://github.com/schlamar))
* Fix spelling in init.bat [\#32](https://github.com/cmderdev/cmder/pull/32) ([Shoozza](https://github.com/Shoozza))
* Added minimal validation and usage help. [\#26](https://github.com/cmderdev/cmder/pull/26) ([Vivix](https://github.com/Vivix))
* Fix spelling [\#22](https://github.com/cmderdev/cmder/pull/22) ([Shoozza](https://github.com/Shoozza))
* Proofreading index.html [\#20](https://github.com/cmderdev/cmder/pull/20) ([manolomartinez](https://github.com/manolomartinez))
* Fixed grammar [\#18](https://github.com/cmderdev/cmder/pull/18) ([tonylau](https://github.com/tonylau))
* Fixed issue when rootDir contains spaces. [\#15](https://github.com/cmderdev/cmder/pull/15) ([jyggen](https://github.com/jyggen))
* Another typo. Fixed link to msysgit. [\#7](https://github.com/cmderdev/cmder/pull/7) ([BeingTomGreen](https://github.com/BeingTomGreen))
* minor typo fix [\#5](https://github.com/cmderdev/cmder/pull/5) ([BeingTomGreen](https://github.com/BeingTomGreen))

\* _This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)_

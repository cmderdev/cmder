# Moving from Cmder 1.x to 2.0

The 2.0 release candidate brings the accumulated Windows Terminal, launcher,
startup, and packaging work to the current release line. You can try it while
keeping your existing installation. The 1.x source remains on
[`legacy/1.x`](https://github.com/cmderdev/cmder/tree/legacy/1.x).

## Try the RC beside your current installation

1. Close shells that use the installation you intend to update. Make a complete
   backup, including `config`, custom `bin` and `opt` files, and any separate
   configuration root selected with `/C`.
2. Extract the RC into a new directory. Start it once with its clean defaults.
3. Copy your user-owned configuration into the new installation deliberately.
   Compare files before replacing them. Do not copy the old `vendor` tree over
   the new one.
4. Try your usual cmd, PowerShell, and Bash profiles, startup directory,
   aliases, prompt, and Git commands. Keep the old installation until those
   checks pass for your setup.

Do not treat a successful build as proof that every custom terminal profile or
third-party shell works. Report problems with the exact RC, package, terminal,
shell, and steps to reproduce them.

## Choose a package by its contents

`full` means Git for Windows is included. `nogit` means it is not included;
you can use an external Git installation. `launcher` packages do not bundle a
terminal emulator. They still include Cmder's startup scripts and Clink.

| 2.0 archive | Terminal emulator | Git for Windows |
| --- | --- | --- |
| `cmder_full.zip` / `cmder_full.7z` | Windows Terminal | Included |
| `cmder_nogit.zip` | Windows Terminal | External Git, if wanted |
| `cmder_conemu_full.zip` / `cmder_conemu_full.7z` | ConEmu | Included |
| `cmder_conemu_nogit.zip` | ConEmu | External Git, if wanted |
| `cmder_launcher.zip` / `cmder_launcher.7z` | Your chosen terminal | Included |
| `cmder_launcher_nogit.zip` | Your chosen terminal | External Git, if wanted |

At the 2.0 boundary, the current-line names change as follows:

| Earlier current-line name | 2.0 name |
| --- | --- |
| `cmder.zip` / `cmder.7z` | `cmder_full.zip` / `cmder_full.7z` |
| `cmder_mini.zip` | `cmder_nogit.zip` |
| `cmder_conemu.zip` / `cmder_conemu.7z` | `cmder_conemu_full.zip` / `cmder_conemu_full.7z` |
| `cmder_conemu_mini.zip` | `cmder_conemu_nogit.zip` |
| `cmder_launcher_mini.zip` | `cmder_launcher_nogit.zip` |

The published 1.x release asset names do not change. Package-manager manifests
must select the correct new archive and checksum before offering 2.0. That work
is tracked in [#3094](https://github.com/cmderdev/cmder/issues/3094).

## Existing terminal commands and init.bat

The current startup script is `vendor/init.cmd`. The release still ships
`vendor/init.bat` as a compatibility shim. Existing profiles can keep calling
the shim while you update them. Do not delete it: it is part of the package and
will return on an update.

In ConEmu, edit your existing command under **Settings > Startup > Tasks**.
In Windows Terminal, edit the existing profile's command line. Replace only the
`vendor/init.bat` filename with `vendor/init.cmd`; keep your shell executable,
quoted paths, and other arguments. New profiles already use `init.cmd`.

## The generated user_init.cmd file

`config/user_init.cmd` is a generated startup configuration that is also
editable. Cmder loads an existing file instead of discovering everything again
on each startup. A separate `/C` configuration can have its own file too, but
the current startup script checks the installation's `config/user_init.cmd`
first. If that shared file exists, it takes precedence over the `/C` file.

There is no general automatic invalidation of every user edit after an upgrade,
a moved installation, or a changed Git location. Do not assume that replacing
the package has refreshed an existing generated file.

To refresh it safely:

1. Back up the complete configuration and close its shells.
2. Rename that configuration's `user_init.cmd` to a uniquely named backup. Keep
   it; do not overwrite or delete your previous version.
   For a `/C` configuration, also back up and rename the installation's
   `config/user_init.cmd` if it exists. Renaming only the `/C` file will not
   trigger regeneration while the shared file takes precedence.
3. Start the new installation using the same configuration root. Cmder can
   generate a fresh `user_init.cmd` when it is absent.
4. Compare the new file with your backup and reapply intentional customizations
   one by one. Test the next startup before removing any backup.

The default configuration and a `/C` configuration are different roots. A later
startup of the default configuration can recreate the shared file and make it
take precedence again. Keep the backups and account for this current limitation
when switching roots. Cache precedence and migration work is tracked in
[#3132](https://github.com/cmderdev/cmder/issues/3132).

## Separate user roots and terminal settings

`/C` selects a separate Cmder shell configuration. Bundled Windows Terminal
uses settings shared by that installation; `/C` does not create an isolated
Windows Terminal settings file. Use separate installations if you need fully
separate bundled Terminal settings. Back up existing terminal settings before
changing them.

## Continue work and compare release lines

Continue new and unfinished work through feature PRs to `main`; `development`
must not collect ongoing work. An admin must finish the
default-branch/protection handoff in
[#3130](https://github.com/cmderdev/cmder/issues/3130).

- [Compare legacy/1.x with main, hiding whitespace](https://github.com/cmderdev/cmder/compare/legacy%2F1.x..main?w=1).
- [David's recovered execution backlog](https://github.com/cmderdev/cmder/issues/3133).
- [Independent final 1.x checklist](https://github.com/cmderdev/cmder/issues/3131).

The 1.x branch name does not itself guarantee support for Windows 7, every
Git version, or every hardware configuration. Dependency OS requirements and real
host tests must be checked for each legacy release.

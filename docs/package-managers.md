# Package Manager Release Prep

This document describes the Cmder-side preparation for Windows package-manager releases. It does not publish anything by itself; maintainers still need to review and submit generated files to the external registries.

Canonical tracking:

- Master issue: <https://github.com/cmderdev/cmder/issues/3094>
- Wiki status: <https://github.com/cmderdev/cmder/wiki/Package-Manager-Status>

## Generate Release Files

After a Cmder release has assets and `hashes.txt`, run:

```powershell
.\scripts\package-managers.ps1 `
  -Version 1.3.25 `
  -ReleaseTag v1.3.25 `
  -ReleaseDate 2024-05-31 `
  -Clean
```

By default the script reads `build\hashes.txt` if present. If it is not present, it downloads `hashes.txt` from:

```text
https://github.com/cmderdev/cmder/releases/download/<tag>/hashes.txt
```

Generated files are written to `build\package-managers`.

## WinGet

The generated WinGet files are under:

```text
build\package-managers\winget\manifests\c\Cmder\Cmder\<version>
build\package-managers\winget\manifests\c\Cmder\CmderMini\<version>
```

Validate them locally:

```powershell
winget validate --manifest .\build\package-managers\winget\manifests\c\Cmder\Cmder\1.3.25
winget validate --manifest .\build\package-managers\winget\manifests\c\Cmder\CmderMini\1.3.25
```

To submit, copy the generated manifest folders into a fork of [`microsoft/winget-pkgs`](https://github.com/microsoft/winget-pkgs) and open a PR. Proposed package IDs are:

- `Cmder.Cmder` for the full archive, using `cmder.zip` and `Architecture: x64`
- `Cmder.CmderMini` for the mini archive, using `cmder_mini.zip` and `Architecture: neutral`

The full package is marked `x64` because the full Cmder archive vendors 64-bit Git for Windows.

## Chocolatey

The generated Chocolatey package sources are under:

```text
build\package-managers\chocolatey\Cmder
build\package-managers\chocolatey\cmdermini
```

Build them locally:

```powershell
choco pack .\build\package-managers\chocolatey\Cmder\Cmder.nuspec
choco pack .\build\package-managers\chocolatey\cmdermini\cmdermini.nuspec
```

Current Chocolatey packages already exist, but they are community-maintained rather than owned by `cmderdev`:

- <https://community.chocolatey.org/packages/Cmder>
- <https://community.chocolatey.org/packages/cmdermini>

Before publishing official packages, contact the current maintainers and ask them to add Cmder maintainers or coordinate ownership. Chocolatey's vendor guidance asks software vendors/authors to contact current maintainers first, then contact Chocolatey site admins with the contact history if there is no response after 7 days.

## Scoop

Scoop manifests already exist in `ScoopInstaller/Main`:

- <https://github.com/ScoopInstaller/Main/blob/master/bucket/cmder.json>
- <https://github.com/ScoopInstaller/Main/blob/master/bucket/cmder-full.json>

They already use official Cmder release assets and `hashes.txt`. If the manifests lag after a release, submit an update PR to `ScoopInstaller/Main` unless the core team decides to create a separate official bucket.

# Package Manager Release Prep

This document describes the Cmder-side preparation for Windows package-manager releases. Generated files can be reviewed locally, uploaded as workflow artifacts, or published through the package-manager workflow once maintainers configure the required external credentials.

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

The same generation step is available in GitHub Actions through **Package Manager Publishing**. The workflow defaults to a dry run so maintainers can inspect generated files before enabling any external publishing.

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

To submit manually, copy the generated manifest folders into a fork of [`microsoft/winget-pkgs`](https://github.com/microsoft/winget-pkgs) and open a PR. To submit through GitHub Actions, configure `WINGETCREATE_GITHUB_TOKEN` and run the package-manager workflow with WinGet publishing enabled.

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

To publish through GitHub Actions, configure `CHOCOLATEY_API_KEY` and run the package-manager workflow with Chocolatey publishing enabled. The workflow uses `https://push.chocolatey.org/` by default, or `CHOCOLATEY_PUSH_SOURCE` if the repository variable is set.

## Scoop

The generated Scoop manifests are under:

```text
build\package-managers\scoop\bucket\cmder.json
build\package-managers\scoop\bucket\cmder-full.json
```

Scoop manifests also exist in `ScoopInstaller/Main`:

- <https://github.com/ScoopInstaller/Main/blob/master/bucket/cmder.json>
- <https://github.com/ScoopInstaller/Main/blob/master/bucket/cmder-full.json>

They already use official Cmder release assets and `hashes.txt`. If the manifests lag after a release, submit an update PR to `ScoopInstaller/Main` unless the core team decides to create a separate official bucket.

To publish through GitHub Actions, configure `SCOOP_GITHUB_TOKEN` and set the Scoop repository variables described in the private maintainer setup note. The workflow copies the generated manifests into the configured bucket and opens a pull request.

## GitHub Actions Publishing

Workflow: `.github/workflows/package-managers.yml`

The workflow can be triggered manually with release details, or by a published GitHub release. Published releases remain dry-run only unless `PACKAGE_MANAGERS_AUTO_PUBLISH` is enabled through repository variables.

Dry-run behavior:

- generates WinGet, Chocolatey, and Scoop files;
- validates WinGet manifests when `winget` is available on the runner;
- packs Chocolatey `.nupkg` files;
- parses Scoop manifests as JSON;
- uploads all generated files as the `package-manager-files` artifact.

Publishing behavior:

- WinGet: uses WingetCreate to submit manifest PRs to `microsoft/winget-pkgs`;
- Chocolatey: pushes generated `.nupkg` files to the configured Chocolatey push source;
- Scoop: opens or updates a pull request against the configured Scoop bucket repository.

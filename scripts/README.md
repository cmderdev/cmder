# Scripts

This folder contains helper scripts used to:

- Update sources for vendor components.
- Build the launcher and download vendor components.
- Package release archives.

The scripts share a small library of helper functions located in `utils.ps1`.

**Overview**
- **build.ps1**: Builds the Cmder distribution. It downloads and unpacks vendor components, preserves user configuration (ConEmu / Windows Terminal), prepares portable components, and can optionally compile the launcher when run with the `-Compile` switch. It supports skipping vendor downloads (`-NoVendor`), selecting which terminal to include (`-terminal`), and customizing paths (`-sourcesPath`, `-saveTo`, `-launcher`, `-config`). The script uses `msbuild` when compiling the launcher and utilities like `7z` for extraction.
- **pack.ps1**: Packages the built distribution into several distributable archives. Use this to assemble release artifacts (zip/tar, checksums, etc.). Output is grouped by terminal profile under `build/<profile>/`.
- **package-profiles.json**: Central configuration for the terminal profiles, output folders, and excluded vendors used by `build.ps1`, `pack.ps1`, and the CI workflow.
- **update.ps1**: Updates what will be bundled by `build.ps1`.

**Shared helpers**
- **utils.ps1**: A shared library of helper functions used by the other scripts. Common utilities include:
  - environment and executable checks (e.g. `Ensure-Executable`, `Ensure-Exists`)
  - download and archive helpers (e.g. `Download-File`, `Extract-Archive`)
  - file operations and cleanup (e.g. `Delete-Existing`, `Flatten-Directory`)
  - build helpers (e.g. `Create-RC`, `Get-VersionStr`)
  - logging and verbosity helpers

The scripts dot-source `utils.ps1` at runtime to reuse the above functions and centralize error handling, logging, and platform-specific behavior.

**Quick examples**
- Run a default build (downloads vendors and prepares distribution):

```powershell
.\build.ps1 -verbose
```

- Build and compile the launcher (requires `msbuild`/VS build tools):

```powershell
.\build.ps1 -verbose -Compile
```

- Compile but skip vendor downloads (quick launcher build):

```powershell
.\build.ps1 -verbose -Compile -NoVendor
```

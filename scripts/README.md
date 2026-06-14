# Scripts

This folder contains helper scripts used to:

- Update sources.
- Build the launcheer and download sources.
- Package release archives.

The scripts share a small library of helper functions located in `utils.ps1`.

**Overview**
- **build.ps1**: Builds the Cmder distribution. It downloads and unpacks vendor components, preserves user configuration (ConEmu / Windows Terminal), prepares portable components, and can optionally compile the launcher when run with the `-Compile` switch. It supports skipping vendor downloads (`-NoVendor`), selecting which terminal to include (`-terminal`), and customizing paths (`-sourcesPath`, `-saveTo`, `-launcher`, `-config`). The script uses `msbuild` when compiling the launcher and utilities like `7z` for extraction.
- **pack.ps1**: Packages the built distribution into a distributable archive. Use this to assemble release artifacts (zip/tar, checksums, etc.).
- **update.ps1**: Updates or refreshes vendored components and related metadata. Use this to pull newer vendor archives or to refresh what will be bundled by `build.ps1`.

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
.\build.ps1
```

- Build and compile the launcher (requires `msbuild`/VS build tools):

```powershell
.\build.ps1 -Compile
```

- Compile but skip vendor downloads (quick launcher build):

```powershell
.\build.ps1 -Compile -NoVendor
```

If you want, I can open the new README or run a quick spell-check/change. The file was created at: [scripts/README.md](scripts/README.md)

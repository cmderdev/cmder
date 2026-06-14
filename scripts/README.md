# Scripts

This folder contains helper scripts used to:

- Update sources for vendor components.
- Build the launcher and download vendor components.
- Package release archives.

The scripts share a small library of helper functions located in `utils.ps1`.

**Overview**
- **build.ps1**: Builds the Cmder distribution. It downloads and unpacks vendor components, preserves user configuration (ConEmu / Windows Terminal), prepares portable components, and can optionally compile the launcher when run with the `-Compile` switch. It supports skipping vendor downloads (`-NoVendor`), selecting which terminal to include (`-Terminal`), and customizing paths (`-sourcesPath`, `-saveTo`, `-launcher`, `-config`). The script uses `msbuild` when compiling the launcher and utilities like `7z` for extraction.
- **pack.ps1**: Packages the built distribution into the distributable archives declared in `package-profiles.json`. Output is grouped by terminal profile under `build/<profile>/`.
- **package-profiles.json**: Central configuration for the terminal profiles, output folders, included vendors, and package variants used by `build.ps1`, `pack.ps1`, and the CI workflow.
- **update.ps1**: Updates what will be bundled by `build.ps1`.

**Shared helpers**
- **utils.ps1**: A shared library of helper functions used by the other scripts. Common utilities include:
  - environment and executable checks (e.g. `Ensure-Executable`, `Ensure-Exists`)
  - download and archive helpers (e.g. `Download-File`, `Extract-Archive`)
  - file operations and cleanup (e.g. `Delete-Existing`, `Flatten-Directory`)
  - build helpers (e.g. `Create-RC`, `Get-VersionStr`)
  - logging and verbosity helpers

The scripts dot-source `utils.ps1` at runtime to reuse the above functions and centralize error handling, logging, and platform-specific behavior.

**Packaging variations**
- Edit [`scripts/package-profiles.json`](./package-profiles.json) to rename, add, or remove package variations.
- Each profile defines a default `includedVendors` list for the full variants, and each package entry can override that list when a variation needs a different vendor set.
- If a package entry omits `includedVendors`, it inherits the profile default.
- `outputFolder` controls the `build/<profile>/` directory, while each package entry's `name` controls the archive filename written inside that folder.

**Quick examples**
- Run a default build (downloads vendors and prepares distribution):

```powershell
.\build.ps1 -Verbose
```

- Build and compile the launcher (requires `msbuild`/VS build tools):

```powershell
.\build.ps1 -Compile -Verbose
```

- Compile but skip vendor downloads (quick launcher build):

```powershell
.\build.ps1 -Compile -NoVendor -Verbose
```

# Cmder Repository Instructions

Cmder is a portable Windows console distribution.  Changes commonly span
Windows command scripts, PowerShell profiles, Lua prompt configuration, shell
scripts, and the native C++ launcher.  Preserve portability: do not introduce
machine-specific paths, assumptions about installed software, or changes that
overwrite user configuration.

## Repository map

- `vendor/` contains the shipped startup scripts, shell integrations, defaults,
  and dependency metadata in `vendor/sources.json`.
- `config/` and the `vendor/user_*.default` files define user-customizable
  configuration.  User changes belong in `config/user_*` or `config/profile.d`,
  not in files marked as overwritten during updates.
- `scripts/` builds, packages, and updates the distribution.  Shared PowerShell
  helpers live in `scripts/utils.ps1`; package variants are data-driven by
  `scripts/package-profiles.json`.
- `launcher/` is the Visual C++ Cmder launcher (`CmderLauncher.vcxproj`).
- `.github/workflows/` is the authoritative CI behavior.

## Implementation rules

- Prefer `.cmd` for new command scripts.  The only tracked `.bat` files are
  `Cmder.bat` and the `vendor/init.bat` compatibility shim.
- Keep command, PowerShell, and shell initialization compatible with portable
  installations and separate user configuration (`CMDER_USER_CONFIG`).
- When altering startup behavior, consider `cmd.exe`, PowerShell, Git Bash,
  Mintty, Windows Terminal, and ConEmu as applicable.  Preserve the selected
  terminal profile and user settings.
- Reuse helpers in `scripts/utils.ps1`; use `-Verbose` output and fail clearly
  when prerequisites or operations are missing.
- Keep `scripts/utils.ps1` UTF-8 with BOM for Windows PowerShell 5.1.  Preserve
  existing encodings and line endings elsewhere: `.cmd`, `.bat`, and `.ps1`
  use CRLF; Markdown and shell scripts use LF.
- Update `scripts/package-profiles.json` rather than adding profile-specific
  branching to build or pack scripts.  Keep `vendor/sources.json` versions and
  URLs aligned when changing bundled dependencies.
- Keep launcher changes compatible with the supported Win32 and x64 Debug and
  Release configurations, Visual Studio toolset v143, and Windows SDK 10.0.

## Validation

Run the smallest applicable Windows PowerShell or PowerShell checks:

```powershell
.\scripts\check-trailing-whitespace.ps1
.\scripts\test-update.ps1
```

For changes that affect build behavior or the launcher, run:

```powershell
.\scripts\build.ps1 -Compile -NoVendor -Verbose
```

For distribution changes, use the CI-equivalent build and package commands on
Windows with `msbuild` and `7z` available:

```powershell
.\scripts\build.ps1 -Compile -Terminal all -Verbose
.\scripts\pack.ps1 -Terminal all -Verbose
```

Also run `git diff --check` before committing.  Test user-facing startup or
configuration changes on a fresh Windows environment when possible.

## Code review

Diff the changes against main origin/main branch or the specified base branch.

Prior to starting a review ensure there are no uncommitted changes.

- If doing an interractive code ask the user about committing files.
- Required uncommitted changes should be committed with relevant commit messages.
- If there are unreleated changes in the same commit, split them into separate commits.

Create an untracked code_review_findigs.md file to document any issues found during the review.  Include
the following information for each issue:

- Status: Open, Fixed, or Won't Fix
- File name and line number
- Description of the issue
- Proposed solution or recommendation

Make sure there is an appropriately versioned CHANGELOG entry for any
changes that affect the user experience, including new features,
improvements, bug fixes, and breaking changes.  If the change is a bug fix,
include the issue number in the CHANGELOG entry.

Prioritize behavior regressions over style.  Review changes with these
repository-specific checks:

- Startup and launcher changes must preserve existing `cmd.exe`, PowerShell,
  Git Bash, Mintty, ConEmu, and Windows Terminal behavior where applicable.
  Pay particular attention to upgrade compatibility for existing user task
  configurations and `init.bat` callers.
- Verify that shipped scripts do not overwrite user-owned configuration or
  assume a fixed installation path, shell, terminal, or external Git
  installation.
- For PowerShell changes, check Windows PowerShell 5.1 compatibility,
  `$PSScriptRoot` initialization timing, encoding, quoting, and error
  propagation; CI running PowerShell 7 is not sufficient coverage by itself.
- For build and packaging changes, verify every affected terminal profile and
  full/no-Git package variant.  Flag hardcoded vendor or package branches that
  should be expressed through `package-profiles.json`.
- For vendor updates, confirm the version, URL, package inclusion, release
  notes, and generated artifacts stay consistent.
- For launcher changes, verify both x64 and Win32 release configurations and
  review command-line parsing, path quoting, and settings backup/restore.
- Treat changes to `.gitattributes`, scripts, and workflow files as release
  affecting.  Confirm the matching CI checks and documentation are updated.

### CodeReview Changes

When fixing issues found during code review, please make sure to address all the
comments and suggestions provided by the reviewer.

If you disagree with any feedback, provide a clear explanation for your decision.

Commits should indicate it is a code review finding fix, be atomic and focused on
a single change, avoid bundling unrelated changes together.

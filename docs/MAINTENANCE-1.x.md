# Maintaining Cmder 1.x

`legacy/1.x` keeps the ConEmu-based Cmder behavior available for selective fixes.
It has its own launcher, `vendor/init.bat`, build scripts and three archive names:
`cmder.zip`, `cmder.7z`, and `cmder_mini.zip`. New features target `main`.
`development` is historical and must not collect new work.

The exact pre-integration master remains at
[`legacy/1.x-baseline-2026-11-10`](https://github.com/cmderdev/cmder/tree/legacy/1.x-baseline-2026-11-10),
commit `2b25c570a2b58c3c46b7f672a0a25677970aa9c7`. Maintenance changes advance
`legacy/1.x` normally; do not force-push the baseline or merge the entire current
line into it.

## Prepare a backport

1. Read the original issue, current-line fix, and review comments.
2. Preserve local edits, branches, and stashes. Use a separate source checkout
   rather than building inside a daily Cmder installation.
3. Create a short branch from `origin/legacy/1.x`. Cherry-pick a compatible fix
   with provenance, or make the smallest equivalent change for the old source.
4. Keep 1.x command paths, package names, user configuration and contributor credit.
   Do not introduce the 2.0 generated-cache or Windows Terminal model as a backport.
5. Add a regression check for changed behavior and update `CHANGELOG.md`.
6. Send a PR to `legacy/1.x`, linking the original work and the checks performed.

## Checks

Use Visual Studio 2022/v143 and Windows SDK 10 for launcher changes. The CI builds
and runs the production-source launcher tests on Win32 and x64. Build helpers
and historical shell defaults are checked on Windows PowerShell 5.1 and 7.

```powershell
.\scripts\check-trailing-whitespace.ps1
.\scripts\test-update.ps1
.\scripts\test-shell-detection.ps1
.\scripts\test-build-helpers.ps1
.\scripts\test-legacy-packaging.ps1
.\scripts\build.ps1 -Compile -NoVendor -Verbose
git diff --check
```

For a release, run the full build and pack in that separate checkout. Independently
download and verify the tagged assets, SHA-256 manifest, archive contents and
versioned launcher. Check that every archive excludes Windows Terminal, Full
includes Git, Mini excludes Git, and private user configuration is absent.

## Component and OS limits

The selected Full package uses Git for Windows `2.56.0.windows.4` on x64 and
therefore requires Windows 10 or later. See the
[upstream requirements](https://gitforwindows.org/requirements.html).
The legacy startup paths retain support for older `mingw64`/`mingw32` layouts
alongside `ucrt64`.

Mini leaves Git selection to the user. An external component's own OS and security
requirements still apply. A 1.x branch or a successful Win32 build does not prove
that the package works on Windows 7 or on a physical 32-bit/ARM machine.

The TCC/TCCLE change restores the four previous shell-helper defaults removed by
`e3d9f81`, retaining user overrides and existing initialization behavior. It does
not require a new TCC installation or introduce a new shell policy.

Current follow-ups remain in [David's backlog](https://github.com/cmderdev/cmder/issues/3133).
Use the [direct legacy/main comparison with whitespace hidden](https://github.com/cmderdev/cmder/compare/legacy%2F1.x..main?w=1)
to review porting differences. The [default-branch admin handoff](https://github.com/cmderdev/cmder/issues/3130)
is independent of maintenance releases.

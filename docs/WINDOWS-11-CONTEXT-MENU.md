# Windows 11 context menu

`Cmder Here` can appear in the Windows 11 menu for one selected filesystem
folder or drive, or a folder's background. It starts the `Cmder.exe` belonging
to that installation, in the selected directory. Virtual folders and multiple
selections are excluded. Cmder continues to choose its configured terminal.

This optional integration requires **x64 Windows 11 22H2 (build 22621) or later**.
Windows uses a sparse identity package to discover the native `IExplorerCommand`;
the portable launcher, settings, and dependencies remain outside that package.
It is registered only when requested, for the current user.

## Register a release build

Extract the complete distribution to its intended location, then run:

```powershell
.\Cmder.exe /REGISTER MODERN
# Optional Cmder configuration root; its directory must exist:
.\Cmder.exe /REGISTER MODERN /C 'D:\My Cmder Settings'
# ConEmu packages without Windows Terminal also support /SINGLE:
.\Cmder.exe /REGISTER MODERN /SINGLE
```

The identity package must have a signature trusted by Windows. Organizational
deployment policy can also restrict registration. An unsigned CI package produces
an actionable error; it does not enable Developer Mode, add a certificate, or
change machine-wide shell policy. A maintainer-signed release is required for
ordinary end-user installation.

Open a new Explorer window and right-click a folder, its background, or a drive.
If Windows has cached the menu, sign out and back in when convenient. Cmder does
not terminate or restart Explorer.

## Remove or move the integration

```powershell
.\Cmder.exe /UNREGISTER MODERN
```

There is one active modern-menu Cmder location per user. A different publisher
cannot replace its registration or preferences silently.
Unregister it before moving or deleting that installation, then register the new
location. If `Cmder.exe` is missing, the shipped helper can still remove the
registration:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bin\cmder-shell\Register-CmderContextMenu.ps1 -Action Unregister
```

Removal targets only Cmder's exact current-user package identity, its menu
preference file, and four owned registration values. It leaves user profiles, terminal settings, unrelated
packages, and classic menu registration alone. `/REGISTER USER`, `/REGISTER ALL`,
and their `/UNREGISTER` counterparts continue to manage the classic menu.

## Build, test, and sign

With Visual Studio v143, MSBuild, and the Windows 11 SDK on PATH:

```powershell
.\scripts\build.ps1 -Compile -NoVendor
# Rebuild/repackage the Explorer integration separately:
.\scripts\build-shell-integration.ps1
# Use a signing certificate already available to the build account:
.\scripts\build-shell-integration.ps1 -Version 2.0.0.0 -CertificateThumbprint '<thumbprint>'
```

The builder derives `Publisher` from the selected certificate's full subject,
creates correctly sized logos from Cmder's existing icon, and emits
`bin/cmder-shell/`. It also accepts `-TimestampServer` for release signing. Keep
the publisher stable across updates and increment the four-part package version
for an updated release. Signing does not install or trust that certificate.
All terminal/full/no-Git archives include the same optional integration payload.

The menu's `/C` and ConEmu `/SINGLE` preferences live in the current user's
package `LocalState` folder. They do not change the selected terminal's profiles.
The Explorer command starts Cmder outside the package runtime so terminal
settings and credentials keep their normal locations.

Unsigned builds can be tested on a machine where **Developer Mode is already
enabled**, by explicitly registering the loose manifest:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\bin\cmder-shell\Register-CmderContextMenu.ps1 -Action Register -Development
# Remove afterward with /UNREGISTER MODERN or the helper's Unregister action.
```

No `-AllowUnsigned` production path or automatic certificate trust is provided.
The normal registration command does not silently select development mode.

Native direct-COM tests and PowerShell fixtures run in CI without registering
a package. They cover selection/background handling, argument boundaries,
failure propagation, identity ownership, preference rollback, and unregistration.
Actual Explorer rendering and trusted-signed deployment should also be checked
on the target Windows installation; source/fixture success alone does not prove
those behaviors.

## Implementation references

The requirement is in [#2788](https://github.com/cmderdev/cmder/issues/2788).
Its HTML comment points to [grepWin's native command implementation](https://github.com/stefankueng/grepWin/commit/607e86e3b501bccd67f1c7d0ba64324ce2c663ce).
Cmder's implementation is original MIT-licensed code using the Windows SDK and
WRL, without importing grepWin's GPL source or adding a native library dependency.

- [Microsoft Explorer command integration](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/integrate-packaged-app-with-file-explorer)
- [Sparse package identity](https://learn.microsoft.com/en-us/windows/apps/desktop/modernize/grant-identity-to-nonpackaged-apps)
- [Drive context-menu schema and minimum Windows version](https://learn.microsoft.com/en-us/uwp/schemas/appxpackage/uapmanifestschema/element-desktop10-itemtype)
- [Signing an MSIX package](https://learn.microsoft.com/en-us/windows/msix/package/sign-app-package-using-signtool)

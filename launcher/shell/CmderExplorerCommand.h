// SPDX-License-Identifier: MIT
#pragma once

#include <windows.h>
#include <shobjidl.h>
#include <ocidl.h>
#include <wrl.h>
#include <string>
#include <string_view>
#include "WindowsArguments.h"

// Shared with the per-user package/registration manifest. Never reuse another
// application's shell-extension identity.
inline constexpr GUID CLSID_CmderExplorerCommand =
    {0x62662ef3, 0x4ae5, 0x4ab0, {0x84, 0xf4, 0xc9, 0x63, 0xfa, 0x66, 0xb9, 0xbd}};

namespace CmderShell
{
    struct Preferences
    {
        std::wstring configRoot;
        bool singleInstance = false;
    };

    bool IsAbsolutePath(std::wstring_view path) noexcept;
}

class __declspec(uuid("62662EF3-4AE5-4AB0-84F4-C963FA66B9BD")) CmderExplorerCommand final :
    public Microsoft::WRL::RuntimeClass<
        Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>,
        IExplorerCommand, IObjectWithSite>
{
public:
    IFACEMETHODIMP GetTitle(IShellItemArray*, LPWSTR* title) noexcept override;
    IFACEMETHODIMP GetIcon(IShellItemArray*, LPWSTR* icon) noexcept override;
    IFACEMETHODIMP GetToolTip(IShellItemArray*, LPWSTR* toolTip) noexcept override;
    IFACEMETHODIMP GetCanonicalName(GUID* name) noexcept override;
    IFACEMETHODIMP GetState(IShellItemArray* selection, BOOL okToBeSlow, EXPCMDSTATE* state) noexcept override;
    IFACEMETHODIMP Invoke(IShellItemArray* selection, IBindCtx*) noexcept override;
    IFACEMETHODIMP GetFlags(EXPCMDFLAGS* flags) noexcept override;
    IFACEMETHODIMP EnumSubCommands(IEnumExplorerCommand** commands) noexcept override;
    IFACEMETHODIMP SetSite(IUnknown* site) noexcept override;
    IFACEMETHODIMP GetSite(REFIID iid, void** site) noexcept override;

private:
    HRESULT GetTargetItem(IShellItemArray* selection, IShellItem** item);
    Microsoft::WRL::ComPtr<IUnknown> site_;
};

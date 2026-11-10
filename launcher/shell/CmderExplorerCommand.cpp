// SPDX-License-Identifier: MIT
#include "CmderExplorerCommand.h"

#include <shlguid.h>
#include <servprov.h>
#include <wrl/module.h>
#include <new>
#include <vector>
#include <appmodel.h>
#include <shlobj.h>
#include <exdisp.h>
#include <shldisp.h>
#ifdef ShellExecute
#undef ShellExecute
#endif

using Microsoft::WRL::ComPtr;
using Microsoft::WRL::InProc;
using Microsoft::WRL::Module;

namespace
{
    HINSTANCE moduleInstance = nullptr;

    template <typename Action>
    HRESULT ComBoundary(Action&& action) noexcept
    {
        try { return action(); }
        catch (const std::bad_alloc&) { return E_OUTOFMEMORY; }
        catch (...) { return E_UNEXPECTED; }
    }

    HRESULT CopyString(const std::wstring& text, LPWSTR* result)
    {
        if (!result) { return E_POINTER; }
        *result = nullptr;
        const size_t bytes = (text.size() + 1) * sizeof(wchar_t);
        auto memory = static_cast<wchar_t*>(CoTaskMemAlloc(bytes));
        if (!memory) { return E_OUTOFMEMORY; }
        memcpy(memory, text.c_str(), bytes);
        *result = memory;
        return S_OK;
    }

    std::wstring ParentPath(const std::wstring& path)
    {
        const size_t slash = path.find_last_of(L"\\/");
        if (slash == 2 && path[1] == L':') { return path.substr(0, 3); }
        if (slash == 6 && path.compare(0, 4, L"\\\\?\\") == 0 && path[5] == L':') { return path.substr(0, 7); }
        return slash == std::wstring::npos ? std::wstring() : path.substr(0, slash);
    }

    std::wstring JoinPath(const std::wstring& directory, const wchar_t* relative)
    {
        return directory + (directory.back() == L'\\' || directory.back() == L'/' ? L"" : L"\\") + relative;
    }

    HRESULT GetRoot(std::wstring& root)
    {
        std::vector<wchar_t> path(512);
        for (;;)
        {
            const DWORD length = GetModuleFileNameW(moduleInstance, path.data(), static_cast<DWORD>(path.size()));
            if (!length)
            {
                const DWORD error = GetLastError();
                return HRESULT_FROM_WIN32(error ? error : ERROR_GEN_FAILURE);
            }
            if (length < path.size())
            {
                // ROOT\bin\cmder-shell\CmderExplorerCommand.dll
                root = ParentPath(ParentPath(ParentPath(std::wstring(path.data(), length))));
                return CmderShell::IsAbsolutePath(root) ? S_OK : E_UNEXPECTED;
            }
            if (path.size() >= 32768) { return HRESULT_FROM_WIN32(ERROR_FILENAME_EXCED_RANGE); }
            path.resize((path.size() * 2 > 32768) ? 32768 : path.size() * 2);
        }
    }

    bool MissingFile(DWORD status) noexcept
    {
        return status == ERROR_FILE_NOT_FOUND || status == ERROR_PATH_NOT_FOUND;
    }

    HRESULT ReadPreferences(CmderShell::Preferences& preferences)
    {
        wchar_t family[PACKAGE_FAMILY_NAME_MAX_LENGTH + 1] = {};
        UINT32 length = ARRAYSIZE(family);
        const LONG identity = GetCurrentPackageFamilyName(&length, family);
        if (identity != ERROR_SUCCESS) { return HRESULT_FROM_WIN32(identity); }
        constexpr std::wstring_view prefix = L"Cmder.ContextMenu_";
        const std::wstring_view name(family);
        if (name.size() != prefix.size() + 13 || name.substr(0, prefix.size()) != prefix)
        {
            return HRESULT_FROM_WIN32(ERROR_INVALID_DATA);
        }
        for (const wchar_t character : name.substr(prefix.size()))
        {
            if (!((character >= L'a' && character <= L'z') || (character >= L'0' && character <= L'9')))
            {
                return HRESULT_FROM_WIN32(ERROR_INVALID_DATA);
            }
        }
        LPWSTR localAppData = nullptr;
        const HRESULT knownFolder = SHGetKnownFolderPath(FOLDERID_LocalAppData,
            KF_FLAG_DONT_VERIFY | KF_FLAG_NO_PACKAGE_REDIRECTION, nullptr, &localAppData);
        if (FAILED(knownFolder)) { CoTaskMemFree(localAppData); return knownFolder; }
        std::wstring directory;
        try { if (localAppData) { directory = localAppData; } }
        catch (...) { CoTaskMemFree(localAppData); throw; }
        CoTaskMemFree(localAppData);
        if (!CmderShell::IsAbsolutePath(directory)) { return HRESULT_FROM_WIN32(ERROR_INVALID_DATA); }
        const std::wstring path = JoinPath(directory, (L"Packages\\" + std::wstring(name) + L"\\LocalState\\CmderContextMenu.ini").c_str());
        if (!CmderShell::IsAbsolutePath(path)) { return HRESULT_FROM_WIN32(ERROR_FILENAME_EXCED_RANGE); }
        const DWORD attributes = GetFileAttributesW(path.c_str());
        if (attributes == INVALID_FILE_ATTRIBUTES)
        {
            const DWORD error = GetLastError();
            return MissingFile(error) ? S_OK : HRESULT_FROM_WIN32(error ? error : ERROR_GEN_FAILURE);
        }
        if (attributes & FILE_ATTRIBUTE_DIRECTORY) { return HRESULT_FROM_WIN32(ERROR_INVALID_DATA); }
        std::vector<wchar_t> config(32769, L'\0');
        SetLastError(ERROR_SUCCESS);
        const DWORD copied = GetPrivateProfileStringW(L"Cmder", L"ConfigRoot", L"", config.data(),
            static_cast<DWORD>(config.size()), path.c_str());
        DWORD error = GetLastError();
        if (error && !MissingFile(error)) { return HRESULT_FROM_WIN32(error); }
        if (copied >= config.size() - 1) { return HRESULT_FROM_WIN32(ERROR_MORE_DATA); }
        preferences.configRoot.assign(config.data(), copied);
        if (!preferences.configRoot.empty() && !CmderShell::IsAbsolutePath(preferences.configRoot))
        {
            return HRESULT_FROM_WIN32(ERROR_INVALID_DATA);
        }
        wchar_t single[3] = {};
        SetLastError(ERROR_SUCCESS);
        const DWORD singleLength = GetPrivateProfileStringW(L"Cmder", L"SingleInstance", L"0", single, ARRAYSIZE(single), path.c_str());
        error = GetLastError();
        if (error && !MissingFile(error)) { return HRESULT_FROM_WIN32(error); }
        if (singleLength != 1 || (single[0] != L'0' && single[0] != L'1')) { return HRESULT_FROM_WIN32(ERROR_INVALID_DATA); }
        preferences.singleInstance = single[0] == L'1';
        return S_OK;
    }

    HRESULT ValidateFolder(IShellItem* item)
    {
        if (!item) { return E_INVALIDARG; }
        constexpr SFGAOF required = SFGAO_FILESYSTEM | SFGAO_FOLDER;
        SFGAOF attributes = 0;
        const HRESULT result = item->GetAttributes(required, &attributes);
        if (FAILED(result)) { return result; }
        return (attributes & required) == required ? S_OK : E_INVALIDARG;
    }

    bool IsDirectory(const std::wstring& path)
    {
        const DWORD attributes = GetFileAttributesW(path.c_str());
        return attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
    }

    class ScopedVariant
    {
    public:
        VARIANT value;
        ScopedVariant() noexcept { VariantInit(&value); }
        ~ScopedVariant() { VariantClear(&value); }
        ScopedVariant(const ScopedVariant&) = delete;
        ScopedVariant& operator=(const ScopedVariant&) = delete;
        HRESULT String(const std::wstring& text)
        {
            value.bstrVal = SysAllocStringLen(text.data(), static_cast<UINT>(text.size()));
            if (!value.bstrVal) { return E_OUTOFMEMORY; }
            value.vt = VT_BSTR;
            return S_OK;
        }
    };

    HRESULT InterfaceResult(HRESULT result, const void* pointer) noexcept
    {
        return result == S_OK && pointer ? S_OK : FAILED(result) ? result : E_NOINTERFACE;
    }

    HRESULT LaunchFromDesktopExplorer(const std::wstring& launcher, const std::wstring& parameters, const std::wstring& folder)
    {
        // Ask the existing desktop Explorer to launch Cmder. A direct launch
        // from the packaged COM surrogate would pass its virtualized settings
        // environment to Cmder and terminals, breaking portable user settings.
        const DWORD attributes = GetFileAttributesW(launcher.c_str());
        if (attributes == INVALID_FILE_ATTRIBUTES)
        {
            const DWORD error = GetLastError();
            return HRESULT_FROM_WIN32(error ? error : ERROR_FILE_NOT_FOUND);
        }
        if (attributes & FILE_ATTRIBUTE_DIRECTORY) { return HRESULT_FROM_WIN32(ERROR_INVALID_DATA); }
        if (launcher.size() + parameters.size() + 4 >= 32768) { return HRESULT_FROM_WIN32(ERROR_FILENAME_EXCED_RANGE); }
        ComPtr<IShellWindows> windows;
        HRESULT result = CoCreateInstance(CLSID_ShellWindows, nullptr, CLSCTX_LOCAL_SERVER, IID_PPV_ARGS(&windows));
        result = InterfaceResult(result, windows.Get());
        if (FAILED(result)) { return result; }
        ScopedVariant location, empty;
        location.value.vt = VT_I4;
        location.value.lVal = CSIDL_DESKTOP;
        LONG window = 0;
        ComPtr<IDispatch> desktop;
        result = windows->FindWindowSW(&location.value, &empty.value, SWC_DESKTOP, &window, SWFO_NEEDDISPATCH, &desktop);
        result = InterfaceResult(result, desktop.Get());
        if (FAILED(result)) { return result; }
        ComPtr<IServiceProvider> services;
        result = desktop.As(&services);
        result = InterfaceResult(result, services.Get());
        if (FAILED(result)) { return result; }
        ComPtr<IShellBrowser> browser;
        result = services->QueryService(SID_STopLevelBrowser, IID_PPV_ARGS(&browser));
        result = InterfaceResult(result, browser.Get());
        if (FAILED(result)) { return result; }
        ComPtr<IShellView> view;
        result = browser->QueryActiveShellView(&view);
        result = InterfaceResult(result, view.Get());
        if (FAILED(result)) { return result; }
        ComPtr<IDispatch> background;
        result = view->GetItemObject(SVGIO_BACKGROUND, IID_PPV_ARGS(&background));
        result = InterfaceResult(result, background.Get());
        if (FAILED(result)) { return result; }
        ComPtr<IShellFolderViewDual> automation;
        result = background.As(&automation);
        result = InterfaceResult(result, automation.Get());
        if (FAILED(result)) { return result; }
        ComPtr<IDispatch> application;
        result = automation->get_Application(&application);
        result = InterfaceResult(result, application.Get());
        if (FAILED(result)) { return result; }
        ComPtr<IShellDispatch2> shell;
        result = application.As(&shell);
        result = InterfaceResult(result, shell.Get());
        if (FAILED(result)) { return result; }
        ScopedVariant file, arguments, directory, verb, show;
        if (FAILED(file.String(launcher)) || FAILED(arguments.String(parameters)) ||
            FAILED(directory.String(folder)) || FAILED(verb.String(L"open"))) { return E_OUTOFMEMORY; }
        show.value.vt = VT_I4;
        show.value.lVal = SW_SHOWNORMAL;
        result = shell->ShellExecute(file.value.bstrVal, arguments.value, directory.value, verb.value, show.value);
        return result == S_OK ? S_OK : FAILED(result) ? result : E_FAIL;
    }
}

namespace CmderShell
{
    bool IsAbsolutePath(std::wstring_view path) noexcept
    {
        if (path.empty() || path.size() >= 32768 || path.find_first_of(L"\r\n\"") != std::wstring_view::npos)
        {
            return false;
        }
        const auto separator = [](wchar_t c) { return c == L'\\' || c == L'/'; };
        const auto driveLetter = [](wchar_t c) { return (c >= L'A' && c <= L'Z') || (c >= L'a' && c <= L'z'); };
        if (path.size() >= 3 && driveLetter(path[0]) &&
            path[1] == L':' && separator(path[2])) { return true; }
        if (path.size() < 5 || path[0] != L'\\' || path[1] != L'\\' || path[2] == L'.') { return false; }
        size_t serverStart = 2;
        if (path.substr(0, 4) == L"\\\\?\\")
        {
            if (path.size() >= 7 && path[5] == L':' && separator(path[6]) &&
                driveLetter(path[4])) { return true; }
            if (path.size() < 8 || _wcsnicmp(path.data() + 4, L"UNC\\", 4) != 0) { return false; }
            serverStart = 8;
        }
        const size_t serverEnd = path.find(L'\\', serverStart);
        if (serverEnd == std::wstring_view::npos || serverEnd == serverStart || serverEnd + 1 == path.size()) { return false; }
        const size_t shareEnd = path.find(L'\\', serverEnd + 1);
        return shareEnd != serverEnd + 1;
    }
}

HRESULT CmderExplorerCommand::GetTargetItem(IShellItemArray* selection, IShellItem** item)
{
    *item = nullptr;
    if (selection)
    {
        DWORD count = 0;
        HRESULT result = selection->GetCount(&count);
        if (FAILED(result)) { return result; }
        if (count > 1) { return E_INVALIDARG; }
        if (count == 1) { return selection->GetItemAt(0, item); }
    }
    if (!site_) { return E_INVALIDARG; }
    ComPtr<IServiceProvider> provider;
    HRESULT result = site_.As(&provider);
    if (FAILED(result)) { return result; }
    ComPtr<IFolderView> view;
    result = provider->QueryService(SID_SFolderView, IID_PPV_ARGS(&view));
    if (FAILED(result)) { return result; }
    result = view->GetFolder(IID_PPV_ARGS(item));
    if (SUCCEEDED(result)) { return result; }
    // IFolderView also documents a one-item IShellItemArray representation.
    ComPtr<IShellItemArray> folder;
    result = view->GetFolder(IID_PPV_ARGS(&folder));
    if (FAILED(result)) { return result; }
    DWORD count = 0;
    result = folder->GetCount(&count);
    if (FAILED(result)) { return result; }
    return count == 1 ? folder->GetItemAt(0, item) : E_INVALIDARG;
}

IFACEMETHODIMP CmderExplorerCommand::GetTitle(IShellItemArray*, LPWSTR* title) noexcept
{
    if (title) { *title = nullptr; }
    return ComBoundary([&] { return CopyString(L"Cmder Here", title); });
}

IFACEMETHODIMP CmderExplorerCommand::GetIcon(IShellItemArray*, LPWSTR* icon) noexcept
{
    if (!icon) { return E_POINTER; }
    *icon = nullptr;
    return ComBoundary([&]() -> HRESULT {
        std::wstring root;
        const HRESULT result = GetRoot(root);
        if (FAILED(result)) { return result; }
        return CopyString(L"\"" + JoinPath(root, L"icons\\cmder.ico") + L"\",0", icon);
    });
}

IFACEMETHODIMP CmderExplorerCommand::GetToolTip(IShellItemArray*, LPWSTR* toolTip) noexcept
{
    if (toolTip) { *toolTip = nullptr; }
    return ComBoundary([&] { return CopyString(L"Open Cmder in this folder.", toolTip); });
}

IFACEMETHODIMP CmderExplorerCommand::GetCanonicalName(GUID* name) noexcept
{
    if (!name) { return E_POINTER; }
    *name = CLSID_CmderExplorerCommand;
    return S_OK;
}

IFACEMETHODIMP CmderExplorerCommand::GetState(IShellItemArray* selection, BOOL, EXPCMDSTATE* state) noexcept
{
    if (!state) { return E_POINTER; }
    *state = ECS_HIDDEN;
    return ComBoundary([&]() -> HRESULT {
        ComPtr<IShellItem> item;
        // No registry, disk/network probing, launcher lookup, or process creation.
        if (SUCCEEDED(GetTargetItem(selection, &item)) && SUCCEEDED(ValidateFolder(item.Get())))
        {
            *state = ECS_ENABLED;
        }
        return S_OK;
    });
}

IFACEMETHODIMP CmderExplorerCommand::Invoke(IShellItemArray* selection, IBindCtx*) noexcept
{
    return ComBoundary([&]() -> HRESULT {
        ComPtr<IShellItem> item;
        HRESULT result = GetTargetItem(selection, &item);
        if (FAILED(result)) { return result; }
        result = ValidateFolder(item.Get());
        if (FAILED(result)) { return result; }
        LPWSTR path = nullptr;
        result = item->GetDisplayName(SIGDN_FILESYSPATH, &path);
        if (FAILED(result)) { CoTaskMemFree(path); return result; }
        std::wstring folder;
        try { if (path) { folder = path; } }
        catch (...) { CoTaskMemFree(path); throw; }
        CoTaskMemFree(path);
        if (!CmderShell::IsAbsolutePath(folder)) { return E_INVALIDARG; }
        std::wstring root;
        result = GetRoot(root);
        if (FAILED(result)) { return result; }
        CmderShell::Preferences preferences;
        result = ReadPreferences(preferences);
        if (FAILED(result)) { return result; }
        const std::wstring launcher = JoinPath(root, L"Cmder.exe");
        std::wstring arguments = L"/start " + CmderShell::QuoteArgument(folder);
        if (!preferences.configRoot.empty()) { arguments += L" /c " + CmderShell::QuoteArgument(preferences.configRoot); }
        // Keep the launcher's existing ConEmu-only /single policy if the
        // portable installation changes terminal after the menu is registered.
        if (preferences.singleInstance && IsDirectory(JoinPath(root, L"vendor\\conemu-maximus5")) &&
            !IsDirectory(JoinPath(root, L"vendor\\windows-terminal"))) { arguments += L" /single"; }
        return LaunchFromDesktopExplorer(launcher, arguments, folder);
    });
}

IFACEMETHODIMP CmderExplorerCommand::GetFlags(EXPCMDFLAGS* flags) noexcept
{
    if (!flags) { return E_POINTER; }
    *flags = ECF_DEFAULT;
    return S_OK;
}

IFACEMETHODIMP CmderExplorerCommand::EnumSubCommands(IEnumExplorerCommand** commands) noexcept
{
    if (!commands) { return E_POINTER; }
    *commands = nullptr;
    return E_NOTIMPL;
}

IFACEMETHODIMP CmderExplorerCommand::SetSite(IUnknown* site) noexcept
{
    return ComBoundary([&]() -> HRESULT { site_ = site; return S_OK; });
}

IFACEMETHODIMP CmderExplorerCommand::GetSite(REFIID iid, void** site) noexcept
{
    if (!site) { return E_POINTER; }
    *site = nullptr;
    return ComBoundary([&]() -> HRESULT { return site_ ? site_->QueryInterface(iid, site) : E_FAIL; });
}

CoCreatableClass(CmderExplorerCommand);

extern "C" BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID)
{
    // Static CRT builds retain their required thread notifications.
    if (reason == DLL_PROCESS_ATTACH) { moduleInstance = instance; }
    return TRUE;
}

STDAPI DllGetClassObject(REFCLSID clsid, REFIID iid, void** object)
{
    if (!object) { return E_POINTER; }
    *object = nullptr;
    return ComBoundary([&] { return Module<InProc>::GetModule().GetClassObject(clsid, iid, object); });
}

STDAPI DllCanUnloadNow()
{
    return ComBoundary([]() -> HRESULT { return Module<InProc>::GetModule().Terminate() ? S_OK : S_FALSE; });
}

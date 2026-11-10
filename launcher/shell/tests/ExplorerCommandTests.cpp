// SPDX-License-Identifier: MIT
#include "../CmderExplorerCommand.h"
#include <shlguid.h>
#include <servprov.h>
#include <shellapi.h>
#include <wrl/module.h>
#include <cstdio>
#include <stdexcept>
#include <vector>
#include <appmodel.h>
#include <shlobj.h>
#include <exdisp.h>
#include <shldisp.h>

namespace Test
{
    unsigned checks = 0;
    void Check(bool condition, const char* message)
    {
        ++checks;
        if (!condition) { throw std::runtime_error(message); }
    }

    struct NativeCalls
    {
        std::wstring module = L"C:\\portable Cmder & \u03bb\\bin\\cmder-shell\\CmderExplorerCommand.dll";
        std::wstring config;
        DWORD single = 0;
        DWORD configError = ERROR_SUCCESS, singleError = ERROR_SUCCESS;
        std::wstring singleOverride;
        std::wstring family = L"Cmder.ContextMenu_zsafhr408y41g";
        std::wstring localAppData = L"C:\\Users\\fixture\\AppData\\Local";
        LONG packageError = ERROR_SUCCESS;
        HRESULT knownFolderError = S_OK;
        DWORD preferencesAttributes = FILE_ATTRIBUTE_NORMAL, preferencesError = ERROR_FILE_NOT_FOUND;
        DWORD moduleError = ERROR_SUCCESS;
        unsigned automationStage = 0, desktopResolutions = 0;
        HRESULT automationResult = E_ACCESSDENIED;
        bool badDesktopInterface = false, badFolderInterface = false, badApplicationInterface = false;
        unsigned bstrAllocations = 0, bstrFailAt = 0;
        DWORD launcherAttributes = FILE_ATTRIBUTE_NORMAL, launcherError = ERROR_FILE_NOT_FOUND;
        bool conemuPresent = true, windowsTerminalPresent = false;
        unsigned moduleReads = 0, profileReads = 0, processCalls = 0, fileReads = 0;
        unsigned packageReads = 0, knownFolderReads = 0;
        std::wstring application, commandLine, directory;
        std::vector<std::wstring> arguments;
    } native;

    std::vector<std::wstring> Parse(const std::wstring& commandLine)
    {
        int count = 0;
        LPWSTR* values = CommandLineToArgvW(commandLine.c_str(), &count);
        if (!values) { throw std::runtime_error("CommandLineToArgvW"); }
        std::vector<std::wstring> arguments(values, values + count);
        LocalFree(values);
        return arguments;
    }

    DWORD WINAPI ModuleName(HMODULE, LPWSTR output, DWORD capacity)
    {
        ++native.moduleReads;
        if (native.moduleError) { SetLastError(native.moduleError); return 0; }
        if (native.module.size() >= capacity)
        {
            memcpy(output, native.module.data(), capacity * sizeof(wchar_t));
            SetLastError(ERROR_INSUFFICIENT_BUFFER);
            return capacity;
        }
        memcpy(output, native.module.c_str(), (native.module.size() + 1) * sizeof(wchar_t));
        return static_cast<DWORD>(native.module.size());
    }

    LONG WINAPI PackageFamily(UINT32* capacity, PWSTR output)
    {
        ++native.packageReads;
        if (native.packageError) { return native.packageError; }
        if (*capacity <= native.family.size()) { return ERROR_INSUFFICIENT_BUFFER; }
        memcpy(output, native.family.c_str(), (native.family.size() + 1) * sizeof(wchar_t));
        *capacity = static_cast<UINT32>(native.family.size() + 1);
        return ERROR_SUCCESS;
    }

    HRESULT WINAPI KnownFolder(REFKNOWNFOLDERID id, DWORD flags, HANDLE token, PWSTR* output)
    {
        ++native.knownFolderReads;
        Check(id == FOLDERID_LocalAppData && !token && flags == static_cast<DWORD>(KF_FLAG_DONT_VERIFY | KF_FLAG_NO_PACKAGE_REDIRECTION),
            "physical current-user LocalAppData without creation or package redirection");
        *output = nullptr;
        if (FAILED(native.knownFolderError)) { return native.knownFolderError; }
        const size_t bytes = (native.localAppData.size() + 1) * sizeof(wchar_t);
        *output = static_cast<LPWSTR>(CoTaskMemAlloc(bytes));
        if (!*output) { return E_OUTOFMEMORY; }
        memcpy(*output, native.localAppData.c_str(), bytes);
        return S_OK;
    }

    std::wstring PreferenceFile()
    {
        return native.localAppData + L"\\Packages\\" + native.family + L"\\LocalState\\CmderContextMenu.ini";
    }

    DWORD WINAPI ProfileString(LPCWSTR section, LPCWSTR name, LPCWSTR fallback, LPWSTR output, DWORD capacity, LPCWSTR path)
    {
        ++native.profileReads;
        Check(wcscmp(section, L"Cmder") == 0 && path == PreferenceFile(), "only current package LocalState preferences read");
        const bool config = wcscmp(name, L"ConfigRoot") == 0;
        Check(config || wcscmp(name, L"SingleInstance") == 0, "no arbitrary launcher or other preferences read");
        Check(wcscmp(fallback, config ? L"" : L"0") == 0, "safe optional preference defaults");
        const DWORD error = config ? native.configError : native.singleError;
        if (error)
        {
            SetLastError(error);
            if (error == ERROR_FILE_NOT_FOUND)
            {
                wcscpy_s(output, capacity, fallback);
                return static_cast<DWORD>(wcslen(fallback));
            }
            *output = L'\0';
            return 0;
        }
        const std::wstring value = config ? native.config :
            (native.singleOverride.empty() ? std::to_wstring(native.single) : native.singleOverride);
        const size_t copied = value.size() < capacity - 1 ? value.size() : capacity - 1;
        memcpy(output, value.data(), copied * sizeof(wchar_t));
        output[copied] = L'\0';
        return static_cast<DWORD>(copied);
    }

    DWORD WINAPI FileAttributes(LPCWSTR path)
    {
        ++native.fileReads;
        const std::wstring value(path);
        if (value == PreferenceFile())
        {
            SetLastError(native.preferencesError);
            return native.preferencesAttributes;
        }
        const size_t bin = native.module.rfind(L"\\bin\\cmder-shell\\");
        if (bin != std::wstring::npos && value == native.module.substr(0, bin) + L"\\Cmder.exe")
        {
            SetLastError(native.launcherError);
            return native.launcherAttributes;
        }
        const std::wstring conemu = L"\\vendor\\conemu-maximus5";
        const std::wstring terminal = L"\\vendor\\windows-terminal";
        if (value.size() >= conemu.size() && value.compare(value.size() - conemu.size(), conemu.size(), conemu) == 0)
        { return native.conemuPresent ? FILE_ATTRIBUTE_DIRECTORY : INVALID_FILE_ATTRIBUTES; }
        Check(value.size() >= terminal.size() && value.compare(value.size() - terminal.size(), terminal.size(), terminal) == 0,
            "only selected installation terminal directories probed");
        return native.windowsTerminalPresent ? FILE_ATTRIBUTE_DIRECTORY : INVALID_FILE_ATTRIBUTES;
    }

    BSTR WINAPI AllocateString(const OLECHAR* text, UINT length)
    {
        ++native.bstrAllocations;
        return native.bstrFailAt == native.bstrAllocations ? nullptr : ::SysAllocStringLen(text, length);
    }

}

#ifdef ShellExecute
#undef ShellExecute
#endif
#include "DesktopAutomationMocks.h"

// Compile the production implementation, changing only native side-effect APIs.
// The shipped DLL never includes these substitutions or exports test hooks.
#define GetModuleFileNameW Test::ModuleName
#define GetCurrentPackageFamilyName Test::PackageFamily
#define SHGetKnownFolderPath Test::KnownFolder
#define GetPrivateProfileStringW Test::ProfileString
#define GetFileAttributesW Test::FileAttributes
#define CoCreateInstance Test::DesktopCreate
#define SysAllocStringLen Test::AllocateString
#include "../CmderExplorerCommand.cpp"
#undef CoCreateInstance
#undef SysAllocStringLen
#undef GetModuleFileNameW
#undef GetCurrentPackageFamilyName
#undef SHGetKnownFolderPath
#undef GetPrivateProfileStringW
#undef GetFileAttributesW

using Microsoft::WRL::Make;
using Microsoft::WRL::RuntimeClass;
using Microsoft::WRL::RuntimeClassFlags;
using Microsoft::WRL::ClassicCom;

namespace Test
{
    constexpr SFGAOF realFolder = SFGAO_FILESYSTEM | SFGAO_FOLDER;

    class Item final : public RuntimeClass<RuntimeClassFlags<ClassicCom>, IShellItem>
    {
    public:
        std::wstring path = L"C:\\target";
        SFGAOF attributes = realFolder;
        unsigned pathReads = 0;
        HRESULT pathResult = S_OK;
        int throwAttributes = 0;
        IFACEMETHODIMP BindToHandler(IBindCtx*, REFGUID, REFIID, void**) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetParent(IShellItem**) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetDisplayName(SIGDN type, LPWSTR* output) override
        {
            ++pathReads;
            Check(type == SIGDN_FILESYSPATH, "filesystem path requested");
            *output = nullptr;
            if (FAILED(pathResult)) { return pathResult; }
            return CopyString(path, output);
        }
        IFACEMETHODIMP GetAttributes(SFGAOF mask, SFGAOF* output) override
        {
            if (throwAttributes == 1) { throw std::bad_alloc(); }
            if (throwAttributes == 2) { throw std::runtime_error("COM boundary"); }
            *output = attributes & mask;
            return S_OK;
        }
        IFACEMETHODIMP Compare(IShellItem*, SICHINTF, int*) override { return E_NOTIMPL; }
    };

    class Selection final : public RuntimeClass<RuntimeClassFlags<ClassicCom>, IShellItemArray>
    {
    public:
        std::vector<ComPtr<IShellItem>> items;
        HRESULT countResult = S_OK;
        IFACEMETHODIMP BindToHandler(IBindCtx*, REFGUID, REFIID, void**) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetPropertyStore(GETPROPERTYSTOREFLAGS, REFIID, void**) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetPropertyDescriptionList(REFPROPERTYKEY, REFIID, void**) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetAttributes(SIATTRIBFLAGS, SFGAOF, SFGAOF*) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetCount(DWORD* count) override { *count = static_cast<DWORD>(items.size()); return countResult; }
        IFACEMETHODIMP GetItemAt(DWORD index, IShellItem** item) override
        {
            *item = nullptr;
            return index < items.size() ? items[index].CopyTo(item) : E_INVALIDARG;
        }
        IFACEMETHODIMP EnumItems(IEnumShellItems**) override { return E_NOTIMPL; }
    };

    class Site final : public RuntimeClass<RuntimeClassFlags<ClassicCom>, IServiceProvider, IFolderView>
    {
    public:
        ComPtr<IShellItem> folder;
        ComPtr<IShellItemArray> array;
        HRESULT serviceResult = S_OK;
        IFACEMETHODIMP QueryService(REFGUID service, REFIID iid, void** output) override
        {
            *output = nullptr;
            Check(service == SID_SFolderView, "background requests the folder view service");
            return FAILED(serviceResult) ? serviceResult : QueryInterface(iid, output);
        }
        IFACEMETHODIMP GetFolder(REFIID iid, void** output) override
        {
            *output = nullptr;
            if (iid == __uuidof(IShellItem) && folder) { return folder.CopyTo(iid, output); }
            if (iid == __uuidof(IShellItemArray) && array) { return array.CopyTo(iid, output); }
            return E_NOINTERFACE;
        }
        IFACEMETHODIMP GetCurrentViewMode(UINT*) override { return E_NOTIMPL; }
        IFACEMETHODIMP SetCurrentViewMode(UINT) override { return E_NOTIMPL; }
        IFACEMETHODIMP Item(int, PITEMID_CHILD*) override { return E_NOTIMPL; }
        IFACEMETHODIMP ItemCount(UINT, int*) override { return E_NOTIMPL; }
        IFACEMETHODIMP Items(UINT, REFIID, void**) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetSelectionMarkedItem(int*) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetFocusedItem(int*) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetItemPosition(PCUITEMID_CHILD, POINT*) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetSpacing(POINT*) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetDefaultSpacing(POINT*) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetAutoArrange() override { return E_NOTIMPL; }
        IFACEMETHODIMP SelectItem(int, DWORD) override { return E_NOTIMPL; }
        IFACEMETHODIMP SelectAndPositionItems(UINT, PCUITEMID_CHILD_ARRAY, POINT*, DWORD) override { return E_NOTIMPL; }
    };

    ComPtr<IExplorerCommand> Create()
    {
        ComPtr<IClassFactory> factory;
        Check(DllGetClassObject(CLSID_CmderExplorerCommand, IID_PPV_ARGS(&factory)) == S_OK, "direct COM class factory");
        ComPtr<IExplorerCommand> command;
        Check(factory->CreateInstance(nullptr, IID_PPV_ARGS(&command)) == S_OK, "create IExplorerCommand");
        return command;
    }

    ComPtr<Selection> Select(IShellItem* item)
    {
        auto selection = Make<Selection>();
        selection->items.emplace_back(item);
        return selection;
    }

    void ExpectState(IExplorerCommand* command, IShellItemArray* selection, EXPCMDSTATE expected)
    {
        for (BOOL slow : {FALSE, TRUE})
        {
            EXPCMDSTATE state = ECS_ENABLED;
            Check(command->GetState(selection, slow, &state) == S_OK && state == expected, "visibility for selection/background");
        }
    }

    void QuoteTests()
    {
        const wchar_t* cases[] = {L"", L"simple", L"C:\\", L"C:\\with space\\", L"\\\\server\\share\\",
            L"a&b%PATH%^c|d<e>f", L"\u03bb\u4e2d\u6587", L"embedded\"quote", L"\\\\\"", L"end\\\\"};
        for (const auto value : cases)
        {
            const auto parsed = Parse(L"program " + CmderShell::QuoteArgument(value));
            Check(parsed.size() == 2 && parsed[1] == value, "Windows argument round trip");
        }
        for (const auto path : {L"C:\\", L"D:/folder", L"\\\\server\\share", L"\\\\server\\share\\", L"\\\\?\\C:\\a", L"\\\\?\\UNC\\server\\share"})
        { Check(CmderShell::IsAbsolutePath(path), "absolute filesystem path accepted"); }
        for (const auto path : {L"", L"relative", L"C:relative", L"\\rooted", L"\\\\server", L"\\\\server\\", L"\\\\.\\pipe\\x", L"C:\\bad\"path", L"C:\\line\nbreak"})
        { Check(!CmderShell::IsAbsolutePath(path), "ambiguous/device path rejected"); }
    }

    void InterfaceTests()
    {
        native = {};
        void* object = reinterpret_cast<void*>(1);
        Check(DllGetClassObject(GUID_NULL, IID_IClassFactory, &object) == CLASS_E_CLASSNOTAVAILABLE && !object, "unknown CLSID rejected");
        Check(DllGetClassObject(CLSID_CmderExplorerCommand, IID_IClassFactory, nullptr) == E_POINTER, "factory output required");
        auto command = Create();
        Check(DllCanUnloadNow() == S_FALSE, "live command keeps module loaded");
        ComPtr<IObjectWithSite> withSite;
        Check(command.As(&withSite) == S_OK, "IObjectWithSite exposed");
        ComPtr<IClassFactory> factory;
        Check(DllGetClassObject(CLSID_CmderExplorerCommand, IID_PPV_ARGS(&factory)) == S_OK, "factory reacquired");
        Check(factory->CreateInstance(command.Get(), IID_IExplorerCommand, &object) == CLASS_E_NOAGGREGATION, "aggregation rejected");
        Check(command->QueryInterface(IID_IStream, &object) == E_NOINTERFACE, "unsupported interface rejected");
        LPWSTR text = nullptr;
        Check(command->GetTitle(nullptr, &text) == S_OK && wcscmp(text, L"Cmder Here") == 0, "title");
        CoTaskMemFree(text);
        Check(command->GetToolTip(nullptr, &text) == S_OK && text, "tooltip allocation");
        CoTaskMemFree(text);
        Check(command->GetIcon(nullptr, &text) == S_OK && std::wstring(text) == L"\"C:\\portable Cmder & \u03bb\\icons\\cmder.ico\",0", "icon resolved from shipped DLL layout");
        CoTaskMemFree(text);
        GUID name = {};
        Check(command->GetCanonicalName(&name) == S_OK && name == CLSID_CmderExplorerCommand, "canonical identity");
        EXPCMDFLAGS flags;
        Check(command->GetFlags(&flags) == S_OK && flags == ECF_DEFAULT, "single command flags");
        IEnumExplorerCommand* children = reinterpret_cast<IEnumExplorerCommand*>(1);
        Check(command->EnumSubCommands(&children) == E_NOTIMPL && !children, "no children");
        Check(command->GetTitle(nullptr, nullptr) == E_POINTER && command->GetToolTip(nullptr, nullptr) == E_POINTER &&
            command->GetIcon(nullptr, nullptr) == E_POINTER && command->GetCanonicalName(nullptr) == E_POINTER &&
            command->GetFlags(nullptr) == E_POINTER && command->GetState(nullptr, FALSE, nullptr) == E_POINTER &&
            command->EnumSubCommands(nullptr) == E_POINTER && withSite->GetSite(IID_IUnknown, nullptr) == E_POINTER, "null outputs rejected");
        Check(withSite->GetSite(IID_IUnknown, &object) == E_FAIL && !object, "no implicit background site");
        native.module = L"C:\\bin\\cmder-shell\\CmderExplorerCommand.dll";
        Check(command->GetIcon(nullptr, &text) == S_OK && std::wstring(text) == L"\"C:\\icons\\cmder.ico\",0", "installation at drive root");
        CoTaskMemFree(text);
        native.module = L"\\\\?\\C:\\bin\\cmder-shell\\CmderExplorerCommand.dll";
        Check(command->GetIcon(nullptr, &text) == S_OK && std::wstring(text) == L"\"\\\\?\\C:\\icons\\cmder.ico\",0", "extended drive-root installation");
        CoTaskMemFree(text);
        native.module = L"\\\\server\\share\\bin\\cmder-shell\\CmderExplorerCommand.dll";
        Check(command->GetIcon(nullptr, &text) == S_OK && std::wstring(text) == L"\"\\\\server\\share\\icons\\cmder.ico\",0", "UNC installation root");
        CoTaskMemFree(text);
        native.moduleReads = 0;
        native.module = L"C:\\" + std::wstring(900, L'a') + L"\\bin\\cmder-shell\\CmderExplorerCommand.dll";
        Check(command->GetIcon(nullptr, &text) == S_OK && native.moduleReads == 2, "module path grows beyond MAX_PATH");
        CoTaskMemFree(text);
        native.moduleError = ERROR_ACCESS_DENIED;
        Check(command->GetIcon(nullptr, &text) == HRESULT_FROM_WIN32(ERROR_ACCESS_DENIED) && !text, "module lookup failure propagated");
    }

    void SelectionAndInvokeTests()
    {
        native = {};
        auto command = Create();
        auto item = Make<Item>();
        auto selection = Select(item.Get());
        ExpectState(command.Get(), selection.Get(), ECS_ENABLED);
        Check(native.desktopResolutions == 0 && native.profileReads == 0 && native.packageReads == 0 && native.knownFolderReads == 0 && native.processCalls == 0 && native.moduleReads == 0 && item->pathReads == 0 && native.fileReads == 0,
            "GetState has no path, preferences, automation or module lookup");
        for (const auto folder : {L"C:\\", L"C:\\with space & %PATH% ^ ! (test)\\", L"\\\\server\\share\\", L"C:\\\u03bb\u4e2d\u6587"})
        {
            native = {};
            item->path = folder;
            Check(command->Invoke(selection.Get(), nullptr) == S_OK, "valid folder launches");
            Check(native.application == L"C:\\portable Cmder & \u03bb\\Cmder.exe", "fixed absolute application");
            Check(native.arguments == std::vector<std::wstring>{native.application, L"/start", folder}, "exact /start argument and quoting");
            Check(native.directory == folder && native.desktopResolutions == 1,
                "selected CWD and exactly one desktop automation resolution");
        }
        native = {};
        native.configError = native.singleError = ERROR_SUCCESS;
        native.config = L"D:\\user config & \u03bb\\";
        native.single = 1;
        Check(command->Invoke(selection.Get(), nullptr) == S_OK, "configured launch");
        Check(native.arguments == std::vector<std::wstring>{native.application, L"/start", item->path, L"/c", native.config, L"/single"}, "configuration root and single instance quoted");
        for (bool conemu : {false, true}) {
            for (bool terminal : {false, true}) {
                native = {};
                native.singleError = ERROR_SUCCESS;
                native.single = 1;
                native.conemuPresent = conemu;
                native.windowsTerminalPresent = terminal;
                Check(command->Invoke(selection.Get(), nullptr) == S_OK, "stored single preference remains usable after terminal change");
                std::vector<std::wstring> expected = {native.application, L"/start", item->path};
                if (conemu && !terminal) { expected.push_back(L"/single"); }
                Check(native.arguments == expected, "stored /single forwarded only for supported ConEmu installation");
            }
        }
        for (const auto invalid : {L"relative", L"C:relative", L"C:\\bad\"value"})
        {
            native = {};
            native.configError = ERROR_SUCCESS;
            native.config = invalid;
            Check(command->Invoke(selection.Get(), nullptr) == HRESULT_FROM_WIN32(ERROR_INVALID_DATA) && !native.processCalls, "invalid preference cannot launch");
        }
        native = {};
        native.singleOverride = L"invalid";
        Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.processCalls, "malformed INI single-instance preference cannot launch");
        native = {};
        native.configError = ERROR_SUCCESS;
        native.config.assign(32769, L'a');
        Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.processCalls, "truncated INI configuration value rejected");
        native = {};
        native.singleError = ERROR_ACCESS_DENIED;
        Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.processCalls, "unreadable preference cannot launch");
        native = {};
        native.configError = native.singleError = ERROR_FILE_NOT_FOUND;
        Check(command->Invoke(selection.Get(), nullptr) == S_OK && native.arguments.size() == 3, "missing optional INI keys use defaults");
        native = {};
        native.preferencesAttributes = INVALID_FILE_ATTRIBUTES;
        Check(command->Invoke(selection.Get(), nullptr) == S_OK && native.profileReads == 0 && native.arguments.size() == 3,
            "missing preference file uses defaults without profile reads");
        native = {};
        native.preferencesAttributes = INVALID_FILE_ATTRIBUTES;
        native.preferencesError = ERROR_ACCESS_DENIED;
        Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.processCalls, "inaccessible preference file cannot launch");
        native = {};
        native.preferencesAttributes = FILE_ATTRIBUTE_DIRECTORY;
        Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.processCalls, "directory masquerading as INI rejected");
        for (const auto family : {L"Other.ContextMenu_zsafhr408y41g", L"Cmder.ContextMenu_..\\otherpath", L"Cmder.ContextMenu_short"})
        {
            native = {};
            native.family = family;
            Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.profileReads && !native.processCalls,
                "unrelated or invalid package family cannot select a preferences path");
        }
        native = {};
        native.packageError = APPMODEL_ERROR_NO_PACKAGE;
        Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.profileReads && !native.processCalls, "missing package identity cannot select preferences");
        native = {};
        native.knownFolderError = E_ACCESSDENIED;
        Check(command->Invoke(selection.Get(), nullptr) == E_ACCESSDENIED && !native.processCalls, "known folder lookup failure propagated");
        native = {};
        native.localAppData = L"relative";
        Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.profileReads && !native.processCalls, "invalid known folder cannot select preferences path");
        native = {};
        native.automationStage = 7;
        native.automationResult = HRESULT_FROM_WIN32(ERROR_ACCESS_DENIED);
        Check(command->Invoke(selection.Get(), nullptr) == HRESULT_FROM_WIN32(ERROR_ACCESS_DENIED) &&
            native.processCalls == 1 && native.desktopResolutions == 1, "desktop execution error propagated without fallback");

        auto site = Make<Site>();
        site->folder = item;
        ComPtr<IObjectWithSite> withSite;
        Check(command.As(&withSite) == S_OK && withSite->SetSite(static_cast<IServiceProvider*>(site.Get())) == S_OK, "background site set");
        ComPtr<IServiceProvider> returnedSite;
        Check(withSite->GetSite(IID_PPV_ARGS(&returnedSite)) == S_OK && returnedSite.Get() == static_cast<IServiceProvider*>(site.Get()), "background site retained");
        for (const SFGAOF invalidAttributes : {static_cast<SFGAOF>(SFGAO_FILESYSTEM), static_cast<SFGAOF>(SFGAO_FOLDER), static_cast<SFGAOF>(0)})
        {
            native = {};
            item->attributes = invalidAttributes;
            ExpectState(command.Get(), selection.Get(), ECS_HIDDEN);
            Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.processCalls, "file/virtual selection does not fall back to background");
        }
        item->attributes = realFolder;
        native = {};
        selection->items.push_back(item);
        ExpectState(command.Get(), selection.Get(), ECS_HIDDEN);
        Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.processCalls, "multi-selection never launches background");
        selection->items.pop_back();
        selection->countResult = E_ACCESSDENIED;
        ExpectState(command.Get(), selection.Get(), ECS_HIDDEN);
        Check(command->Invoke(selection.Get(), nullptr) == E_ACCESSDENIED, "selection count error preserved");
        selection->countResult = S_OK;
        item->pathResult = E_ACCESSDENIED;
        Check(command->Invoke(selection.Get(), nullptr) == E_ACCESSDENIED && !native.processCalls, "unresolved filesystem path cannot launch");
        item->pathResult = S_OK;
        item->path = L"relative";
        Check(command->Invoke(selection.Get(), nullptr) == E_INVALIDARG && !native.processCalls, "relative item path cannot launch");
        item->path = L"C:\\background";
        ExpectState(command.Get(), nullptr, ECS_ENABLED);
        native = {};
        Check(command->Invoke(nullptr, nullptr) == S_OK && native.arguments[2] == item->path, "background folder from IFolderView");
        auto empty = Make<Selection>();
        ExpectState(command.Get(), empty.Get(), ECS_ENABLED);
        native = {};
        Check(command->Invoke(empty.Get(), nullptr) == S_OK, "empty selection means background");
        site->folder.Reset();
        site->array = selection;
        ExpectState(command.Get(), nullptr, ECS_ENABLED);
        native = {};
        Check(command->Invoke(nullptr, nullptr) == S_OK, "documented single-item folder array fallback");
        selection->items.push_back(item);
        ExpectState(command.Get(), nullptr, ECS_HIDDEN);
        native = {};
        Check(FAILED(command->Invoke(nullptr, nullptr)) && !native.processCalls, "multi-item background representation rejected");
        selection->items.pop_back();
        site->serviceResult = E_NOINTERFACE;
        ExpectState(command.Get(), nullptr, ECS_HIDDEN);
        Check(FAILED(command->Invoke(nullptr, nullptr)), "no arbitrary CWD fallback");
        Check(withSite->SetSite(nullptr) == S_OK, "background site cleared");
        ExpectState(command.Get(), nullptr, ECS_HIDDEN);
        Check(FAILED(command->Invoke(nullptr, nullptr)), "no selection or site cannot launch");
        for (int exception = 1; exception <= 2; ++exception)
        {
            item->throwAttributes = exception;
            EXPCMDSTATE state = ECS_ENABLED;
            const HRESULT expected = exception == 1 ? E_OUTOFMEMORY : E_UNEXPECTED;
            Check(command->GetState(selection.Get(), FALSE, &state) == expected && state == ECS_HIDDEN, "GetState catches COM boundary exceptions");
            Check(command->Invoke(selection.Get(), nullptr) == expected, "Invoke catches COM boundary exceptions");
        }
    }

    void DesktopAutomationFailureTests()
    {
        auto command = Create();
        auto item = Make<Item>();
        auto selection = Select(item.Get());
        for (unsigned stage = 1; stage <= 6; ++stage)
        {
            for (HRESULT result : {E_ACCESSDENIED, S_FALSE, S_OK})
            {
                native = {};
                native.automationStage = stage;
                native.automationResult = result;
                const HRESULT expected = FAILED(result) ? result : E_NOINTERFACE;
                Check(command->Invoke(selection.Get(), nullptr) == expected && native.processCalls == 0 &&
                    native.desktopResolutions == 1, "failed, S_FALSE or null desktop interface has no fallback launch");
            }
        }
        native = {};
        native.badDesktopInterface = true;
        Check(command->Invoke(selection.Get(), nullptr) == E_NOINTERFACE && !native.processCalls,
            "desktop without browser service rejected");
        native = {};
        native.badFolderInterface = true;
        Check(command->Invoke(selection.Get(), nullptr) == E_NOINTERFACE && !native.processCalls,
            "background without FolderViewDual rejected");
        native = {};
        native.badApplicationInterface = true;
        Check(command->Invoke(selection.Get(), nullptr) == E_NOINTERFACE && !native.processCalls,
            "application without ShellDispatch2 rejected");
        for (unsigned allocation = 1; allocation <= 4; ++allocation)
        {
            native = {};
            native.bstrFailAt = allocation;
            Check(command->Invoke(selection.Get(), nullptr) == E_OUTOFMEMORY && !native.processCalls,
                "BSTR allocation failure prevents launch at every argument");
        }
        for (DWORD attributes : {INVALID_FILE_ATTRIBUTES, static_cast<DWORD>(FILE_ATTRIBUTE_DIRECTORY)})
        {
            native = {};
            native.launcherAttributes = attributes;
            Check(FAILED(command->Invoke(selection.Get(), nullptr)) && !native.processCalls && !native.desktopResolutions,
                "missing or non-file launcher rejected before desktop automation");
        }
        native = {};
        native.launcherAttributes = INVALID_FILE_ATTRIBUTES;
        native.launcherError = ERROR_ACCESS_DENIED;
        Check(command->Invoke(selection.Get(), nullptr) == HRESULT_FROM_WIN32(ERROR_ACCESS_DENIED) && !native.desktopResolutions,
            "inaccessible launcher rejected without shell dialog");
        native = {};
        native.automationStage = 7;
        native.automationResult = S_FALSE;
        Check(command->Invoke(selection.Get(), nullptr) == E_FAIL && native.processCalls == 1 && native.desktopResolutions == 1,
            "ShellExecute S_FALSE is not treated as successful execution");
        native = {};
        item->path = L"C:\\" + std::wstring(32740, L'a');
        Check(command->Invoke(selection.Get(), nullptr) == HRESULT_FROM_WIN32(ERROR_FILENAME_EXCED_RANGE) &&
            !native.desktopResolutions && !native.processCalls, "oversized process command line rejected before shell automation");
    }

    void RealDllTests(const wchar_t* path)
    {
        HMODULE dll = LoadLibraryW(path);
        Check(dll != nullptr, "real built DLL loads without registration");
        auto factoryExport = reinterpret_cast<HRESULT (STDAPICALLTYPE*)(REFCLSID, REFIID, void**)>(GetProcAddress(dll, "DllGetClassObject"));
        auto unloadExport = reinterpret_cast<HRESULT (STDAPICALLTYPE*)()>(GetProcAddress(dll, "DllCanUnloadNow"));
        Check(factoryExport && unloadExport, "real DLL exports");
        {
            ComPtr<IClassFactory> factory;
            Check(factoryExport(CLSID_CmderExplorerCommand, IID_PPV_ARGS(&factory)) == S_OK, "real DLL factory");
            ComPtr<IExplorerCommand> command;
            Check(factory->CreateInstance(nullptr, IID_PPV_ARGS(&command)) == S_OK, "real DLL command");
            ComPtr<IObjectWithSite> site;
            Check(command.As(&site) == S_OK && unloadExport() == S_FALSE, "real DLL interfaces and lifetime");
            LPWSTR title = nullptr;
            Check(command->GetTitle(nullptr, &title) == S_OK && wcscmp(title, L"Cmder Here") == 0, "real DLL title");
            CoTaskMemFree(title);
        }
        Check(unloadExport() == S_OK, "real DLL unloads after references released");
        FreeLibrary(dll);
    }

    int RegisteredInvoke(const wchar_t* root, const wchar_t* folder)
    {
        Check(CmderShell::IsAbsolutePath(root) && CmderShell::IsAbsolutePath(folder), "registered fixture paths must be absolute");
        ComPtr<IExplorerCommand> command;
        const HRESULT activation = CoCreateInstance(CLSID_CmderExplorerCommand, nullptr, CLSCTX_LOCAL_SERVER, IID_PPV_ARGS(&command));
        std::wprintf(L"Registered activation: 0x%08lX\n", static_cast<unsigned long>(activation));
        Check(activation == S_OK, "registered packaged COM activation");
        ComPtr<IShellItem> item;
        Check(SHCreateItemFromParsingName(folder, nullptr, IID_PPV_ARGS(&item)) == S_OK, "real fixture folder item");
        ComPtr<IShellItemArray> selection;
        Check(SHCreateShellItemArrayFromShellItem(item.Get(), IID_PPV_ARGS(&selection)) == S_OK, "real fixture folder selection");
        ExpectState(command.Get(), selection.Get(), ECS_ENABLED);
        LPWSTR icon = nullptr;
        Check(command->GetIcon(selection.Get(), &icon) == S_OK, "registered DLL icon");
        const std::wstring expectedIcon = L"\"" + JoinPath(root, L"icons\\cmder.ico") + L"\",0";
        const bool correctRoot = icon && expectedIcon == icon;
        CoTaskMemFree(icon);
        Check(correctRoot, "registered DLL root matches isolated fixture");
        const HRESULT invoke = command->Invoke(selection.Get(), nullptr);
        std::wprintf(L"Registered invoke: 0x%08lX\n", static_cast<unsigned long>(invoke));
        Check(invoke == S_OK, "registered command Invoke");
        return 0;
    }
}

int wmain(int argc, wchar_t** argv)
{
    const HRESULT initialized = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (FAILED(initialized)) { return 2; }
    int result = 0;
    try
    {
        if (argc == 4 && wcscmp(argv[1], L"--registered") == 0)
        {
            result = Test::RegisteredInvoke(argv[2], argv[3]);
        }
        else
        {
            Test::Check(argc == 2, "usage: ExplorerCommandTests.exe <built-DLL> | --registered <root> <folder>");
            Test::QuoteTests();
            Test::InterfaceTests();
            Test::SelectionAndInvokeTests();
            Test::DesktopAutomationFailureTests();
            Test::Check(DllCanUnloadNow() == S_OK, "test module released all command/site references");
            Test::RealDllTests(argv[1]);
        }
        std::printf("PASS: %u native COM assertions\n", Test::checks);
    }
    catch (const std::exception& error) { std::fprintf(stderr, "FAIL: %s (assertion %u)\n", error.what(), Test::checks); result = 1; }
    catch (...) { std::fprintf(stderr, "FAIL: unexpected exception\n"); result = 1; }
    CoUninitialize();
    return result;
}

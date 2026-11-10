#include <windows.h>
#include <tchar.h>
#include <Shlwapi.h>
#include <shlobj.h>
#include <vector>
#include <regex>
#include <iostream>
#include <stdexcept>

// Exercise the production launcher without dialogs, shell launches, or registry
// writes. Only process input and the executable-path API are replaced.
struct LauncherExit { int code; };
static std::wstring testCommandLine = L"Cmder.exe";
static std::wstring testExecutable = L"C:\\Cmder\\Cmder.exe";
static bool failModulePath = false;
static DWORD modulePathCapacity = 0;
static int helpDialogs = 0;
static int registryWrites = 0;
static int terminalLaunches = 0;
static WORD nativeArchitecture = PROCESSOR_ARCHITECTURE_AMD64;
static std::wstring lastTerminalPath;
static std::wstring lastProcessArguments;

[[noreturn]] static void TestExit(int code) { throw LauncherExit{code}; }
static LPWSTR WINAPI TestGetCommandLineW() { return &testCommandLine[0]; }
static DWORD WINAPI TestGetModuleFileNameW(HMODULE, LPWSTR path, DWORD capacity)
{
    modulePathCapacity = capacity;
    if (failModulePath) {
        SetLastError(ERROR_ACCESS_DENIED);
        return 0;
    }
    if (testExecutable.length() >= capacity) {
        wcsncpy_s(path, capacity, testExecutable.c_str(), _TRUNCATE);
        return capacity;
    }
    wcscpy_s(path, capacity, testExecutable.c_str());
    return static_cast<DWORD>(testExecutable.length());
}
static int WINAPI TestMessageBoxW(HWND, LPCWSTR, LPCWSTR, UINT) { return IDOK; }
static HRESULT WINAPI TestTaskDialogIndirect(const TASKDIALOGCONFIG*, int*, int*, BOOL*)
{
    ++helpDialogs;
    return S_OK;
}
static LSTATUS WINAPI TestRegCreateKeyExW(HKEY, LPCWSTR, DWORD, LPWSTR, DWORD,
    REGSAM, const LPSECURITY_ATTRIBUTES, PHKEY, LPDWORD)
{
    ++registryWrites;
    return ERROR_ACCESS_DENIED;
}
static BOOL WINAPI TestCreateProcessW(LPCWSTR application, LPWSTR arguments, LPSECURITY_ATTRIBUTES,
    LPSECURITY_ATTRIBUTES, BOOL, DWORD, LPVOID, LPCWSTR, LPSTARTUPINFOW, LPPROCESS_INFORMATION)
{
    ++terminalLaunches;
    lastTerminalPath = application;
    lastProcessArguments = arguments ? arguments : L"";
    SetLastError(ERROR_FILE_NOT_FOUND);
    return FALSE;
}
static void WINAPI TestGetNativeSystemInfo(LPSYSTEM_INFO info)
{
    ZeroMemory(info, sizeof(*info));
    info->wProcessorArchitecture = nativeArchitecture;
}

#define exit TestExit
#define GetCommandLineW TestGetCommandLineW
#define GetModuleFileNameW TestGetModuleFileNameW
#define MessageBoxW TestMessageBoxW
#define TaskDialogIndirect TestTaskDialogIndirect
#define RegCreateKeyExW TestRegCreateKeyExW
#define CreateProcessW TestCreateProcessW
#define GetNativeSystemInfo TestGetNativeSystemInfo
#include "../src/CmderLauncher.cpp"
#undef exit
#undef GetCommandLineW
#undef GetModuleFileNameW
#undef MessageBoxW
#undef TaskDialogIndirect
#undef RegCreateKeyExW
#undef CreateProcessW
#undef GetNativeSystemInfo

static void Check(bool condition, const char* message)
{
    if (!condition) { throw std::runtime_error(message); }
}

template <typename F>
static void ExpectControlledExit(F action)
{
    try { action(); }
    catch (const LauncherExit& error) {
        Check(error.code == 1, "Unexpected launcher error code");
        return;
    }
    throw std::runtime_error("Launcher accepted an invalid path");
}

static void TestPathBounds()
{
    wchar_t path[MAX_PATH] = {};
    const std::wstring longestPath(MAX_PATH - 1, L'a');
    CopyPathOrExit(longestPath, path);
    Check(longestPath == path, "259-character copy failed");
    for (size_t length : {size_t(MAX_PATH), size_t(MAX_PATH + 1), size_t(4096)}) {
        const std::wstring oversized(length, L'a');
        ExpectControlledExit([&]() { CopyPathOrExit(oversized, path); });
        Check(longestPath == path, "Rejected input changed the destination");
        ExpectControlledExit([&]() { StartCmder(L"", false, L"", L"", L"", oversized); });
        ExpectControlledExit([&]() { RegisterShellMenu(L"USER", const_cast<wchar_t*>(L"unused"), oversized, false); });
    }

    GetExecutablePath(path);
    Check(modulePathCapacity == MAX_PATH, "Module API received bytes instead of characters");
    Check(testExecutable == path, "Executable path changed");
    testExecutable.assign(MAX_PATH - 1, L'a');
    GetExecutablePath(path);
    Check(testExecutable == path, "259-character executable path failed");
    testExecutable.assign(MAX_PATH, L'a');
    ExpectControlledExit([&]() { GetExecutablePath(path); });
    testExecutable.assign(MAX_PATH + 1, L'a');
    ExpectControlledExit([&]() { GetExecutablePath(path); });
    testExecutable = L"C:\\Cmder\\Cmder.exe";
    failModulePath = true;
    ExpectControlledExit([&]() { GetExecutablePath(path); });
    failModulePath = false;
    Check(registryWrites == 0, "Rejected configuration path reached registry writes");
}

static cmderOptions Parse(const std::wstring& arguments)
{
    testCommandLine = L"Cmder.exe " + arguments;
    return GetOption();
}

static void WriteFixture(const std::wstring& path, const std::string& content)
{
    HANDLE file = CreateFileW(path.c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    Check(file != INVALID_HANDLE_VALUE, "Could not create fixture file");
    DWORD written = 0;
    const BOOL result = WriteFile(file, content.data(), static_cast<DWORD>(content.length()), &written, NULL);
    CloseHandle(file);
    Check(result && written == content.length(), "Could not write fixture file");
}

static std::string ReadFixture(const std::wstring& path)
{
    HANDLE file = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    Check(file != INVALID_HANDLE_VALUE, "Could not open fixture file");
    char content[256] = {};
    DWORD read = 0;
    const BOOL result = ReadFile(file, content, sizeof(content), &read, NULL);
    CloseHandle(file);
    Check(result != 0, "Could not read fixture file");
    return std::string(content, read);
}

static void TestArgumentParsing()
{
    wchar_t temporaryPath[MAX_PATH] = {};
    wchar_t fixturePath[MAX_PATH] = {};
    Check(GetTempPathW(MAX_PATH, temporaryPath) != 0, "Could not get temporary path");
    Check(GetTempFileNameW(temporaryPath, L"cmd", 0, fixturePath) != 0, "Could not allocate fixture path");
    Check(DeleteFileW(fixturePath) != 0, "Could not prepare fixture directory");
    Check(CreateDirectoryW(fixturePath, NULL) != 0, "Could not create fixture directory");
    const std::wstring root(fixturePath);
    const std::wstring vendor = root + L"\\vendor";
    const std::wstring conemu = vendor + L"\\conemu-maximus5";
    const std::wstring windowsTerminal = vendor + L"\\windows-terminal";
    const std::wstring installationConfig = root + L"\\config";
    Check(CreateDirectoryW(vendor.c_str(), NULL) != 0, "Could not create vendor fixture");
    Check(CreateDirectoryW(installationConfig.c_str(), NULL) != 0, "Could not create installation config fixture");
    testExecutable = root + L"\\Cmder.exe";

    for (int terminal = 0; terminal < 3; ++terminal) {
        if (terminal == 0) {
            StartCmder(L"", false, L"powershell");
            wchar_t windows[MAX_PATH] = {};
            Check(GetWindowsDirectoryW(windows, MAX_PATH) != 0, "Cannot get Windows path");
            Check(_wcsicmp(lastTerminalPath.c_str(), (std::wstring(windows) + L"\\system32\\cmd.exe").c_str()) == 0,
                "Terminal-free PowerShell task did not use the shared host selector");
            Check(lastProcessArguments == L"\"" + lastTerminalPath + L"\" /d /v:off /s /c \"\"" + vendor + L"\\start_powershell.cmd\" \"",
                "Terminal-free PowerShell selector command was not quoted correctly");
            terminalLaunches = 0;
        }
        if (terminal == 1) {
            Check(CreateDirectoryW(conemu.c_str(), NULL) != 0, "Could not create ConEmu fixture");
            WriteFixture(vendor + L"\\ConEmu.xml.default", "<settings />");
            for (WORD architecture : {WORD(PROCESSOR_ARCHITECTURE_INTEL), WORD(PROCESSOR_ARCHITECTURE_AMD64), WORD(PROCESSOR_ARCHITECTURE_ARM64)}) {
                nativeArchitecture = architecture;
                StartCmder();
                Check(lastTerminalPath == conemu + (architecture == PROCESSOR_ARCHITECTURE_AMD64 ? L"\\ConEmu64.exe" : L"\\ConEmu.exe"),
                    "ConEmu executable did not match native architecture");
            }
        }
        if (terminal == 2) {
            Check(CreateDirectoryW(windowsTerminal.c_str(), NULL) != 0, "Could not create Windows Terminal fixture");
        }
        for (const wchar_t* arguments : {L"/start", L"/start \"\"", L"/task", L"/task \"\"",
                L"/task --", L"/x", L"/x \"\"", L"\"\""}) {
            const int dialogs = helpDialogs;
            Check(Parse(arguments).error, "Malformed arguments did not produce an error");
            Check(helpDialogs == dialogs + 1, "Malformed arguments did not display help");
        }
        auto options = Parse(L"\"" + root + L"\" /task Custom");
        Check(!options.error && options.cmderStart == root && options.cmderTask == L"Custom",
            "A positional folder consumed the next switch");
        options = Parse(L"/start \"" + root + L"\" /task Custom");
        Check(!options.error && options.cmderStart == root && options.cmderTask == L"Custom",
            "Explicit start folder or task changed");
        options = Parse(L"/c -- new-tab");
        Check(!options.error && !options.cmderCfgRoot.empty() && options.cmderTerminalArgs == L"new-tab",
            "Optional configuration root consumed the argument separator");
        options = Parse(L"/task Custom /x \"-foo bar\"");
        Check(!options.error && options.cmderTask == L"Custom" && options.cmderTerminalArgs == L"-foo bar",
            "Legacy terminal arguments changed");
        Check(!Parse(L"/register USER").error && !Parse(L"/unregister ALL").error,
            "Valid registration arguments changed");
        Parse(L"/register /start");
        Check(_tWinMain(NULL, NULL, NULL, 0) == 1 && registryWrites == 0,
            "Invalid registration command reached registry writes");
        if (terminal == 1) {
            for (const wchar_t* arguments : {L"/title", L"/title \"\"", L"/icon", L"/icon \"\""}) {
                Check(Parse(arguments).error, "Missing ConEmu option value did not produce an error");
            }
            options = Parse(L"bash /single /m /title Custom /icon custom.ico");
            Check(!options.error && options.cmderTask == L"bash" && options.cmderSingle &&
                !options.cmderUserCfg && options.cmderTitle == L"Custom" && options.cmderIcon == L"custom.ico",
                "ConEmu arguments or shorthand task consumed another option");
        }
    }

    const std::wstring settingsDirectory = windowsTerminal + L"\\settings";
    const std::wstring settings = settingsDirectory + L"\\settings.json";
    const std::wstring defaults = vendor + L"\\windows_terminal_default_settings.json";
    const std::wstring userRoot = root + L"\\user";
    const std::wstring userConfig = userRoot + L"\\config";
    const std::wstring userSettings = userConfig + L"\\user_windows_terminal_settings.json";
    Check(CreateDirectoryW(settingsDirectory.c_str(), NULL) != 0, "Could not create settings directory");
    Check(CreateDirectoryW(userRoot.c_str(), NULL) != 0, "Could not create user root");
    Check(CreateDirectoryW(userConfig.c_str(), NULL) != 0, "Could not create user config directory");
    WriteFixture(defaults, "{\"source\":\"Cmder defaults\"}");
    WriteFixture(userSettings, "{\"source\":\"user root\"}");
    StartCmder(L"", false, L"", L"", L"", userRoot);
    Check(ReadFixture(settings) == ReadFixture(defaults), "First /c launch did not initialize shared defaults");
    Check(ReadFixture(userSettings) == "{\"source\":\"user root\"}", "First /c launch changed user terminal settings");
    WriteFixture(settings, "{\"source\":\"edited shared settings\"}");
    StartCmder(L"", false, L"", L"", L"", userRoot);
    Check(ReadFixture(settings) == "{\"source\":\"edited shared settings\"}", "Subsequent /c launch overwrote shared settings");
    Check(ReadFixture(userSettings) == "{\"source\":\"user root\"}", "Subsequent /c launch changed user terminal settings");
    Check(terminalLaunches == 5, "Startup did not reach the terminal launch boundary");

    Check(DeleteFileW(userSettings.c_str()) != 0, "Could not remove user settings fixture");
    Check(DeleteFileW(settings.c_str()) != 0, "Could not remove shared settings fixture");
    Check(DeleteFileW(defaults.c_str()) != 0, "Could not remove default settings fixture");
    Check(DeleteFileW((vendor + L"\\ConEmu.xml.default").c_str()) != 0, "Could not remove ConEmu default fixture");
    Check(DeleteFileW((conemu + L"\\ConEmu.xml").c_str()) != 0, "Could not remove ConEmu settings fixture");
    Check(DeleteFileW((installationConfig + L"\\user-ConEmu.xml").c_str()) != 0, "Could not remove ConEmu user settings fixture");
    Check(RemoveDirectoryW(installationConfig.c_str()) != 0, "Could not remove installation config fixture");
    Check(RemoveDirectoryW((userConfig + L"\\profile.d").c_str()) != 0, "Could not remove user profile directory");
    Check(RemoveDirectoryW((userRoot + L"\\bin").c_str()) != 0, "Could not remove user bin directory");
    Check(RemoveDirectoryW(userConfig.c_str()) != 0, "Could not remove user config directory");
    Check(RemoveDirectoryW(userRoot.c_str()) != 0, "Could not remove user root");
    Check(RemoveDirectoryW(settingsDirectory.c_str()) != 0, "Could not remove settings directory");
    Check(RemoveDirectoryW(windowsTerminal.c_str()) != 0, "Could not remove Windows Terminal fixture");
    Check(RemoveDirectoryW(conemu.c_str()) != 0, "Could not remove ConEmu fixture");
    Check(RemoveDirectoryW(vendor.c_str()) != 0, "Could not remove vendor fixture");
    Check(RemoveDirectoryW(root.c_str()) != 0, "Could not remove fixture directory");
}

int wmain()
{
    try {
        TestPathBounds();
        TestArgumentParsing();
        std::cout << "Launcher regression tests passed.\n";
        return 0;
    }
    catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

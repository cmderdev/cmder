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

#define exit TestExit
#define GetCommandLineW TestGetCommandLineW
#define GetModuleFileNameW TestGetModuleFileNameW
#define MessageBoxW TestMessageBoxW
#define TaskDialogIndirect TestTaskDialogIndirect
#include "../src/CmderLauncher.cpp"
#undef exit
#undef GetCommandLineW
#undef GetModuleFileNameW
#undef MessageBoxW
#undef TaskDialogIndirect

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
}

int wmain()
{
    try {
        TestPathBounds();
        std::cout << "Launcher regression tests passed.\n";
        return 0;
    }
    catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}

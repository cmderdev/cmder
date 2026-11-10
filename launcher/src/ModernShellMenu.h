#pragma once
#include <string>
#include <vector>
#include <algorithm>
#include "../shell/WindowsArguments.h"

// Quote one argv element using the Windows backslash/quote rules, without cmd.exe.
inline std::wstring QuoteModernShellArgument(const std::wstring& value)
{
    return CmderShell::QuoteArgument(value);
}

inline int RunModernShellMenu(bool install, const std::wstring& configRoot, bool singleInstance)
{
    wchar_t executable[MAX_PATH] = {};
    GetExecutablePath(executable);
    PathRemoveFileSpecW(executable);
    const std::wstring directory(executable);
    const std::wstring script = directory + L"\\bin\\cmder-shell\\Register-CmderContextMenu.ps1";
    if (!PathFileExistsW(script.c_str())) {
        MessageBoxW(nullptr, L"The Windows 11 menu files are missing. Build the shell integration or extract a complete Cmder package.", MB_TITLE, MB_OK | MB_ICONERROR);
        return 1;
    }
    wchar_t windows[MAX_PATH] = {};
    const UINT windowsLength = GetWindowsDirectoryW(windows, _countof(windows));
    if (!windowsLength || windowsLength >= _countof(windows)) { return 1; }
    BOOL wow64 = FALSE;
    if (!IsWow64Process(GetCurrentProcess(), &wow64)) { return 1; }
    const std::wstring powershell = std::wstring(windows) +
        (wow64 ? L"\\Sysnative" : L"\\System32") + L"\\WindowsPowerShell\\v1.0\\powershell.exe";
    std::wstring command = QuoteModernShellArgument(powershell) +
        L" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File " + QuoteModernShellArgument(script) +
        (install ? L" -Action Register" : L" -Action Unregister");
    if (install && !configRoot.empty()) { command += L" -ConfigRoot " + QuoteModernShellArgument(configRoot); }
    if (install && singleInstance) { command += L" -SingleInstance"; }
    std::vector<wchar_t> arguments(command.begin(), command.end());
    arguments.push_back(L'\0');

    SECURITY_ATTRIBUTES security = {sizeof(security), nullptr, TRUE};
    HANDLE readPipe = nullptr, writePipe = nullptr;
    if (!CreatePipe(&readPipe, &writePipe, &security, 0)) { return 1; }
    if (!SetHandleInformation(readPipe, HANDLE_FLAG_INHERIT, 0)) {
        CloseHandle(readPipe); CloseHandle(writePipe); return 1;
    }
    HANDLE input = CreateFileW(L"NUL", GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, &security, OPEN_EXISTING, 0, nullptr);
    if (input == INVALID_HANDLE_VALUE) { CloseHandle(readPipe); CloseHandle(writePipe); return 1; }
    STARTUPINFOEXW startup = {};
    startup.StartupInfo.cb = sizeof(startup);
    startup.StartupInfo.dwFlags = STARTF_USESTDHANDLES;
    startup.StartupInfo.hStdOutput = writePipe;
    startup.StartupInfo.hStdError = writePipe;
    startup.StartupInfo.hStdInput = input;
    SIZE_T size = 0;
    InitializeProcThreadAttributeList(nullptr, 1, 0, &size);
    if (!size) { CloseHandle(input); CloseHandle(readPipe); CloseHandle(writePipe); return 1; }
    std::vector<unsigned char> attributes(size);
    startup.lpAttributeList = reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(attributes.data());
    HANDLE inherited[] = {input, writePipe};
    bool initialized = InitializeProcThreadAttributeList(startup.lpAttributeList, 1, 0, &size) != FALSE;
    bool configured = initialized && UpdateProcThreadAttribute(startup.lpAttributeList, 0,
        PROC_THREAD_ATTRIBUTE_HANDLE_LIST, inherited, sizeof(inherited), nullptr, nullptr);
    PROCESS_INFORMATION process = {};
    BOOL started = configured && CreateProcessW(powershell.c_str(), arguments.data(), nullptr, nullptr, TRUE,
        CREATE_NO_WINDOW | EXTENDED_STARTUPINFO_PRESENT, nullptr, directory.c_str(), &startup.StartupInfo, &process);
    if (initialized) { DeleteProcThreadAttributeList(startup.lpAttributeList); }
    CloseHandle(writePipe);
    if (input != INVALID_HANDLE_VALUE) { CloseHandle(input); }
    if (!started) {
        CloseHandle(readPipe);
        MessageBoxW(nullptr, L"Unable to start Windows PowerShell for shell registration.", MB_TITLE, MB_OK | MB_ICONERROR);
        return 1;
    }
    std::string output;
    char buffer[1024];
    DWORD count = 0;
    while (ReadFile(readPipe, buffer, sizeof(buffer), &count, nullptr) && count) {
        if (output.size() < 16384) { output.append(buffer, (std::min)(size_t(count), size_t(16384) - output.size())); }
    }
    CloseHandle(readPipe);
    WaitForSingleObject(process.hProcess, INFINITE);
    DWORD code = 1;
    GetExitCodeProcess(process.hProcess, &code);
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    if (code) {
        int length = MultiByteToWideChar(CP_UTF8, 0, output.data(), static_cast<int>(output.size()), nullptr, 0);
        std::wstring message(length, L'\0');
        if (length) { MultiByteToWideChar(CP_UTF8, 0, output.data(), static_cast<int>(output.size()), &message[0], length); }
        if (message.empty()) { message = L"Shell registration failed. See docs/WINDOWS-11-CONTEXT-MENU.md."; }
        MessageBoxW(nullptr, message.c_str(), MB_TITLE, MB_OK | MB_ICONERROR);
    }
    return code ? 1 : 0;
}

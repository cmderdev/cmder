#include <windows.h>
#include <tchar.h>
#include <Shlwapi.h>
#include "resource.h"
#include <vector>
#include <Shlobj.h>


#pragma comment(lib, "Shlwapi.lib")

#ifndef UNICODE
#error "Must be compiled with unicode support."
#endif

#define USE_TASKBAR_API (_WIN32_WINNT >= _WIN32_WINNT_WIN7)

#define XP (_WIN32_WINNT < _WIN32_WINNT_VISTA)

#define MB_TITLE L"Cmder Launcher"
#define SHELL_MENU_REGISTRY_PATH_BACKGROUND L"Directory\\Background\\shell\\Cmder"
#define SHELL_MENU_REGISTRY_PATH_LISTITEM L"Directory\\shell\\Cmder"

#define streqi(a, b) (_wcsicmp((a), (b)) == 0)

#define WIDEN2(x) L ## x
#define WIDEN(x) WIDEN2(x)
#define __WFUNCTION__ WIDEN(__FUNCTION__)

#define FAIL_ON_ERROR(x) { DWORD ec; if ((ec = (x)) != ERROR_SUCCESS) { ShowErrorAndExit(ec, __WFUNCTION__, __LINE__); } }

void ShowErrorAndExit(DWORD ec, const wchar_t * func, int line)
{
	wchar_t * buffer;
	if (FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
		NULL, ec, 0, (LPWSTR) &buffer, 0, NULL) == 0)
	{
		buffer = L"Unknown error. FormatMessage failed.";
	}

	wchar_t message[1024];
	swprintf_s(message, L"%s\nFunction: %s\nLine: %d", buffer, func, line);
	LocalFree(buffer);

	MessageBox(NULL, message, MB_TITLE, MB_OK | MB_ICONERROR);
	exit(1);
}

typedef struct _option
{
	std::wstring name;
	bool hasVal;
	std::wstring value;
	bool set;
} option;

typedef std::pair<std::wstring, std::wstring> optpair;


optpair GetOption()
{
	wchar_t * cmd = GetCommandLine();
	int argc;
	wchar_t ** argv = CommandLineToArgvW(cmd, &argc);
	optpair pair;

	if (argc == 1)
	{
		// no commandline argument...
		pair = optpair(L"/START", L"");
	}
	else if (argc == 2 && argv[1][0] != L'/')
	{
		// only a single argument: this should be a path...
		pair = optpair(L"/START", argv[1]);
	}
	else
	{
		pair = optpair(argv[1], argc > 2 ? argv[2] : L"");
	}

	LocalFree(argv);

	return pair;
}

bool FileExists(const wchar_t * filePath)
{
	HANDLE hFile = CreateFile(filePath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);

	if (hFile != INVALID_HANDLE_VALUE)
	{
		CloseHandle(hFile);
		return true;
	}

	return false;
}

void StartCmder(std::wstring path, bool is_single_mode)
{
#if USE_TASKBAR_API
	wchar_t appId[MAX_PATH] = { 0 };
#endif
	wchar_t exeDir[MAX_PATH] = { 0 };
	wchar_t icoPath[MAX_PATH] = { 0 };
	wchar_t cfgPath[MAX_PATH] = { 0 };
	wchar_t oldCfgPath[MAX_PATH] = { 0 };
	wchar_t conEmuPath[MAX_PATH] = { 0 };
	wchar_t args[MAX_PATH * 2 + 256] = { 0 };

	GetModuleFileName(NULL, exeDir, sizeof(exeDir));

#if USE_TASKBAR_API
	wcscpy_s(appId, exeDir);
#endif

	PathRemoveFileSpec(exeDir);

	PathCombine(icoPath, exeDir, L"icons\\cmder.ico");

	// Check for machine-specific config file.
	PathCombine(oldCfgPath, exeDir, L"config\\ConEmu-%COMPUTERNAME%.xml");
	ExpandEnvironmentStrings(oldCfgPath, oldCfgPath, sizeof(oldCfgPath) / sizeof(oldCfgPath[0]));
	if (!PathFileExists(oldCfgPath)) {
		PathCombine(oldCfgPath, exeDir, L"config\\ConEmu.xml");
	}

	// Check for machine-specific config file.
	PathCombine(cfgPath, exeDir, L"vendor\\conemu-maximus5\\ConEmu-%COMPUTERNAME%.xml");
	ExpandEnvironmentStrings(cfgPath, cfgPath, sizeof(cfgPath) / sizeof(cfgPath[0]));
	if (!PathFileExists(cfgPath)) {
		PathCombine(cfgPath, exeDir, L"vendor\\conemu-maximus5\\ConEmu.xml");
	}

	PathCombine(conEmuPath, exeDir, L"vendor\\conemu-maximus5\\ConEmu.exe");

	if (FileExists(oldCfgPath) && !FileExists(cfgPath))
	{
		if (!CopyFile(oldCfgPath, cfgPath, FALSE))
		{
			MessageBox(NULL,
				(GetLastError() == ERROR_ACCESS_DENIED)
				? L"Failed to copy ConEmu.xml file to new location! Restart cmder as administrator."
				: L"Failed to copy ConEmu.xml file to new location!", MB_TITLE, MB_ICONSTOP);
			exit(1);
		}
	}

	if (is_single_mode)
	{
		swprintf_s(args, L"/single /Icon \"%s\" /Title Cmder", icoPath);
	}
	else
	{
		swprintf_s(args, L"/Icon \"%s\" /Title Cmder", icoPath);
	}

	SetEnvironmentVariable(L"CMDER_ROOT", exeDir);
	if (streqi(path.c_str(), L""))
	{
		wchar_t* homeProfile = 0;
		SHGetKnownFolderPath(FOLDERID_Profile, 0, NULL, &homeProfile);
		if (!SetEnvironmentVariable(L"CMDER_START", homeProfile)) {
			MessageBox(NULL, _T("Error trying to set CMDER_START to given path!"), _T("Error"), MB_OK);
		}
		CoTaskMemFree(static_cast<void*>(homeProfile));
	}
	else
	{
		if (!SetEnvironmentVariable(L"CMDER_START", path.c_str())) {
			MessageBox(NULL, _T("Error trying to set CMDER_START to given path!"), _T("Error"), MB_OK);
		}
	}
	// Ensure EnvironmentVariables are propagated.
	SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM)"Environment", SMTO_ABORTIFHUNG, 5000, NULL);
	SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM) L"Environment", SMTO_ABORTIFHUNG, 5000, NULL); // For Windows >= 8

	STARTUPINFO si = { 0 };
	si.cb = sizeof(STARTUPINFO);
#if USE_TASKBAR_API
	si.lpTitle = appId;
	si.dwFlags = STARTF_TITLEISAPPID;
#endif

	PROCESS_INFORMATION pi;
	if (!CreateProcess(conEmuPath, args, NULL, NULL, false, 0, NULL, NULL, &si, &pi)) {
		MessageBox(NULL, _T("Unable to create the ConEmu Process!"), _T("Error"), MB_OK);
		return;
	}
}

bool IsUserOnly(std::wstring opt)
{
	bool userOnly;

	if (streqi(opt.c_str(), L"ALL"))
	{
		userOnly = false;
	}
	else if (streqi(opt.c_str(), L"USER"))
	{
		userOnly = true;
	}
	else
	{
		MessageBox(NULL, L"Unrecognized option for /REGISTER or /UNREGISTER. Must be either ALL or USER.", MB_TITLE, MB_OK);
		exit(1);
	}

	return userOnly;
}

HKEY GetRootKey(std::wstring opt)
{
	HKEY root;

	if (IsUserOnly(opt))
	{
		FAIL_ON_ERROR(RegCreateKeyEx(HKEY_CURRENT_USER, L"Software\\Classes", 0, NULL,
			REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &root, NULL));
	}
	else
	{
		root = HKEY_CLASSES_ROOT;
	}

	return root;
}

void RegisterShellMenu(std::wstring opt, wchar_t* keyBaseName)
{
	// First, get the paths we will use

	wchar_t exePath[MAX_PATH] = { 0 };
	wchar_t icoPath[MAX_PATH] = { 0 };

	GetModuleFileName(NULL, exePath, sizeof(exePath));

	wchar_t commandStr[MAX_PATH + 20] = { 0 };
	swprintf_s(commandStr, L"\"%s\" \"%%V\"", exePath);

	// Now that we have `commandStr`, it's OK to change `exePath`...
	PathRemoveFileSpec(exePath);

	PathCombine(icoPath, exePath, L"icons\\cmder.ico");

	// Now set the registry keys

	HKEY root = GetRootKey(opt);

	HKEY cmderKey;
	FAIL_ON_ERROR(
		RegCreateKeyEx(root, keyBaseName, 0, NULL,
		REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &cmderKey, NULL));

	FAIL_ON_ERROR(RegSetValue(cmderKey, L"", REG_SZ, L"Cmder Here", NULL));
	FAIL_ON_ERROR(RegSetValueEx(cmderKey, L"NoWorkingDirectory", 0, REG_SZ, (BYTE *)L"", 2));

	FAIL_ON_ERROR(RegSetValueEx(cmderKey, L"Icon", 0, REG_SZ, (BYTE *)icoPath, wcslen(icoPath) * sizeof(wchar_t)));

	HKEY command;
	FAIL_ON_ERROR(
		RegCreateKeyEx(cmderKey, L"command", 0, NULL,
		REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &command, NULL));

	FAIL_ON_ERROR(RegSetValue(command, L"", REG_SZ, commandStr, NULL));

	RegCloseKey(command);
	RegCloseKey(cmderKey);
	RegCloseKey(root);
}

void UnregisterShellMenu(std::wstring opt, wchar_t* keyBaseName)
{
	HKEY root = GetRootKey(opt);
	HKEY cmderKey;
	FAIL_ON_ERROR(
		RegCreateKeyEx(root, keyBaseName, 0, NULL,
		REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &cmderKey, NULL));
#if XP
	FAIL_ON_ERROR(SHDeleteKey(cmderKey, NULL));
#else
	FAIL_ON_ERROR(RegDeleteTree(cmderKey, NULL));
#endif
	RegCloseKey(cmderKey);
	RegCloseKey(root);
}

int APIENTRY _tWinMain(_In_ HINSTANCE hInstance,
	_In_opt_ HINSTANCE hPrevInstance,
	_In_ LPTSTR    lpCmdLine,
	_In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);
	UNREFERENCED_PARAMETER(nCmdShow);

	optpair opt = GetOption();

	if (streqi(opt.first.c_str(), L"/START"))
	{
		StartCmder(opt.second, false);
	}
	else if (streqi(opt.first.c_str(), L"/SINGLE"))
	{
		StartCmder(opt.second, true);
	}
	else if (streqi(opt.first.c_str(), L"/REGISTER"))
	{
		RegisterShellMenu(opt.second, SHELL_MENU_REGISTRY_PATH_BACKGROUND);
		RegisterShellMenu(opt.second, SHELL_MENU_REGISTRY_PATH_LISTITEM);
	}
	else if (streqi(opt.first.c_str(), L"/UNREGISTER"))
	{
		UnregisterShellMenu(opt.second, SHELL_MENU_REGISTRY_PATH_BACKGROUND);
		UnregisterShellMenu(opt.second, SHELL_MENU_REGISTRY_PATH_LISTITEM);
	}
	else
	{
		MessageBox(NULL, L"Unrecognized parameter.\n\nValid options:\n  /START <path>\n  /SINGLE <path>\n  /REGISTER [USER/ALL]\n  /UNREGISTER [USER/ALL]", MB_TITLE, MB_OK);
		return 1;
	}

	return 0;
}

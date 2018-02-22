#include <windows.h>
#include <tchar.h>
#include <Shlwapi.h>
#include "resource.h"
#include <vector>
#include <shlobj.h>

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
		NULL, ec, 0, (LPWSTR)&buffer, 0, NULL) == 0)
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

void StartCmder(std::wstring  path = L"", bool is_single_mode = false, std::wstring taskName = L"", std::wstring cfgRoot = L"")
{
#if USE_TASKBAR_API
	wchar_t appId[MAX_PATH] = { 0 };
#endif
	wchar_t exeDir[MAX_PATH] = { 0 };
	wchar_t icoPath[MAX_PATH] = { 0 };
	wchar_t cfgPath[MAX_PATH] = { 0 };
	wchar_t backupCfgPath[MAX_PATH] = { 0 };
	wchar_t cpuCfgPath[MAX_PATH] = { 0 };
	wchar_t userCfgPath[MAX_PATH] = { 0 };
	wchar_t oldCfgPath[MAX_PATH] = { 0 };
	wchar_t conEmuPath[MAX_PATH] = { 0 };
	wchar_t configDirPath[MAX_PATH] = { 0 };
	wchar_t userConfigDirPath[MAX_PATH] = { 0 };
	wchar_t userBinDirPath[MAX_PATH] = { 0 };
	wchar_t userProfiledDirPath[MAX_PATH] = { 0 };
	wchar_t args[MAX_PATH * 2 + 256] = { 0 };

	std::wstring cmderStart = path;
	std::wstring cmderTask = taskName;

	// size_t f;
	//mbstowcs_s(&f, userConfigDirPath, cfgRoot, sizeof(cfgRoot) + 1);
	std::copy(cfgRoot.begin(), cfgRoot.end(), userConfigDirPath);
	userConfigDirPath[cfgRoot.length()] = 0;

	GetModuleFileName(NULL, exeDir, sizeof(exeDir));

#if USE_TASKBAR_API
	wcscpy_s(appId, exeDir);
#endif

	PathRemoveFileSpec(exeDir);

	PathCombine(icoPath, exeDir, L"icons\\cmder.ico");

	PathCombine(configDirPath, exeDir, L"config");
	if (wcscmp(userConfigDirPath, L"") == 0)
	{
		PathCombine(userConfigDirPath, exeDir, L"config");
	}
	else
	{
		PathCombine(userBinDirPath, userConfigDirPath, L"bin");
		SHCreateDirectoryEx(0, userBinDirPath, 0);

		PathCombine(userConfigDirPath, userConfigDirPath, L"config");
		SHCreateDirectoryEx(0, userConfigDirPath, 0);

		PathCombine(userProfiledDirPath, userConfigDirPath, L"profile.d");
		SHCreateDirectoryEx(0, userProfiledDirPath, 0);
	}

	// Check for machine-specific then user config source file.
	PathCombine(cpuCfgPath, userConfigDirPath, L"ConEmu-%COMPUTERNAME%.xml");
	ExpandEnvironmentStrings(cpuCfgPath, cpuCfgPath, sizeof(cpuCfgPath) / sizeof(cpuCfgPath[0]));

	PathCombine(userCfgPath, userConfigDirPath, L"user-ConEmu.xml");

	if (PathFileExists(cpuCfgPath)) {
		wcsncpy_s(oldCfgPath, cpuCfgPath, sizeof(cpuCfgPath));
		wcsncpy_s(backupCfgPath, cpuCfgPath, sizeof(cpuCfgPath));
	}
	else if (PathFileExists(userCfgPath)) {
		wcsncpy_s(oldCfgPath, userCfgPath, sizeof(userCfgPath));
		wcsncpy_s(backupCfgPath, userCfgPath, sizeof(userCfgPath));
	}
	else {
		PathCombine(oldCfgPath, exeDir, L"config\\ConEmu.xml");
		wcsncpy_s(backupCfgPath, userCfgPath, sizeof(userCfgPath));
	}

	// Set path to vendored ConEmu config file
	PathCombine(cfgPath, exeDir, L"vendor\\conemu-maximus5\\ConEmu.xml");

	SYSTEM_INFO sysInfo;
	GetNativeSystemInfo(&sysInfo);
	if (sysInfo.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_AMD64) {
		PathCombine(conEmuPath, exeDir, L"vendor\\conemu-maximus5\\ConEmu64.exe");
	}
	else {
		PathCombine(conEmuPath, exeDir, L"vendor\\conemu-maximus5\\ConEmu.exe");
	}

	if (FileExists(oldCfgPath) && !FileExists(cfgPath))
	{
		if (!CopyFile(oldCfgPath, cfgPath, FALSE))
		{
			MessageBox(NULL,
				(GetLastError() == ERROR_ACCESS_DENIED)
				? L"Failed to copy ConEmu.xml file to new location! Restart Cmder as administrator."
				: L"Failed to copy ConEmu.xml file to new location!", MB_TITLE, MB_ICONSTOP);
			exit(1);
		}
	}
	else if (!CopyFile(cfgPath, backupCfgPath, FALSE))
	{
		MessageBox(NULL,
			(GetLastError() == ERROR_ACCESS_DENIED)
			? L"Failed to backup ConEmu.xml file to ./config folder!"
			: L"Failed to backup ConEmu.xml file to ./config folder!", MB_TITLE, MB_ICONSTOP);
		exit(1);
	}

	if (streqi(cmderStart.c_str(), L""))
	{
		TCHAR buff[MAX_PATH];
		const DWORD ret = GetEnvironmentVariable(L"USERPROFILE", buff, MAX_PATH);
		cmderStart = buff;
	}

	if (is_single_mode)
	{
		if (!streqi(cmderTask.c_str(), L"")) {
			swprintf_s(args, L"%s /single /Icon \"%s\" /Title Cmder /dir \"%s\" /run {%s}", args, icoPath, cmderStart.c_str(), cmderTask.c_str());
		}
		else {
			swprintf_s(args, L"%s /single /Icon \"%s\" /Title Cmder /dir \"%s\"", args, icoPath, cmderStart.c_str());
		}
	}
	else
	{
		if (!streqi(cmderTask.c_str(), L"")) {
			swprintf_s(args, L"/Icon \"%s\" /Title Cmder /dir \"%s\" /run {%s}", icoPath, cmderStart.c_str(), cmderTask.c_str());
		}
		else {
			swprintf_s(args, L"%s /Icon \"%s\" /Title Cmder /dir \"%s\"", args, icoPath, cmderStart.c_str());
		}
	}


	SetEnvironmentVariable(L"CMDER_ROOT", exeDir);
	if (wcscmp(userConfigDirPath, configDirPath) != 0)
	{
		SetEnvironmentVariable(L"CMDER_USER_CONFIG", userConfigDirPath);
		SetEnvironmentVariable(L"CMDER_USER_BIN", userBinDirPath);
	}

	// Ensure EnvironmentVariables are propagated.

	STARTUPINFO si = { 0 };

	si.cb = sizeof(STARTUPINFO);
#if USE_TASKBAR_API
	si.lpTitle = appId;
	si.dwFlags = STARTF_TITLEISAPPID;
#endif
	PROCESS_INFORMATION pi;
	if (!CreateProcess(conEmuPath, args, NULL, NULL, false, 0, NULL, NULL, &si, &pi)) {
		MessageBox(NULL, _T("Unable to create the ConEmu process!"), _T("Error"), MB_OK);
		return;
	}

	LRESULT lr = SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM)"Environment", SMTO_ABORTIFHUNG | SMTO_NOTIMEOUTIFNOTHUNG, 5000, NULL);
	lr = SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM)L"Environment", SMTO_ABORTIFHUNG | SMTO_NOTIMEOUTIFNOTHUNG, 5000, NULL); // For Windows >= 8
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
		FAIL_ON_ERROR(RegCreateKeyEx(HKEY_CURRENT_USER, L"Software\\Classes", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &root, NULL));
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
	// std::wstring reg_root(&opt[0], &opt[sizeof(opt)]);
	HKEY root = GetRootKey(opt);

	HKEY cmderKey;
	FAIL_ON_ERROR(RegCreateKeyEx(root, keyBaseName, 0, NULL, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &cmderKey, NULL));

	FAIL_ON_ERROR(RegSetValue(cmderKey, L"", REG_SZ, L"Cmder Here", NULL));
	FAIL_ON_ERROR(RegSetValueEx(cmderKey, L"NoWorkingDirectory", 0, REG_SZ, (BYTE *)L"", 2));

	FAIL_ON_ERROR(RegSetValueEx(cmderKey, L"Icon", 0, REG_SZ, (BYTE *)icoPath, wcslen(icoPath) * sizeof(wchar_t)));

	HKEY command;
	FAIL_ON_ERROR(RegCreateKeyEx(cmderKey, L"command", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &command, NULL));

	FAIL_ON_ERROR(RegSetValue(command, L"", REG_SZ, commandStr, NULL));

	RegCloseKey(command);
	RegCloseKey(cmderKey);
	RegCloseKey(root);
}

void UnregisterShellMenu(std::wstring opt, wchar_t* keyBaseName)
{
	// std::wstring reg_root(&opt[0], &opt[sizeof(opt)]);
	HKEY root = GetRootKey(opt);
	HKEY cmderKey;
	FAIL_ON_ERROR(RegCreateKeyEx(root, keyBaseName, 0, NULL, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &cmderKey, NULL));
#if XP
	FAIL_ON_ERROR(SHDeleteKey(cmderKey, NULL));
#else
	FAIL_ON_ERROR(RegDeleteTree(cmderKey, NULL));
#endif
	RegCloseKey(cmderKey);
	RegCloseKey(root);
}

char* getCmdOption(char ** begin, char ** end, const std::string & option)
{
	
	char ** itr = std::find(begin, end, option);
	if (itr != end && ++itr != end)
	{
		// std::wstring its (itr, itr + strlen(*itr));
		// return its;
		return *itr;
	}
	return 0;
}

bool cmdOptionExists(char** begin, char** end, const std::string& option)
{
	return std::find(begin, end, option) != end;
}

/*
*/
int APIENTRY _tWinMain(_In_ HINSTANCE hInstance,
	_In_opt_ HINSTANCE hPrevInstance,
	_In_ LPTSTR    lpCmdLine,
	_In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);
	UNREFERENCED_PARAMETER(nCmdShow);

	LPWSTR *szArgList;
	int argCount;

	szArgList = CommandLineToArgvW(GetCommandLine(), &argCount);
	if (szArgList == NULL)
	{
		MessageBox(NULL, L"Unable to parse command line", L"Error", MB_OK);
		return 10;
	}

	std::wstring  cmderCfgRoot = L"";
	std::wstring  cmderStart = L"";
	std::wstring cmderTask = L"";
	bool cmderSingle = false;
	std::wstring cmderRegScope = L"user";
	bool registerApp = false;
	bool unRegisterApp = false;

	for (int i = 0; i < argCount; i++)
	{
		// MessageBox(NULL, szArgList[i], L"Arglist contents", MB_OK);

		if (wcscmp(L"/C", (wchar_t *)szArgList[i]) == 0)
		{
			cmderCfgRoot = szArgList[i + 1];
			i++;
		}
		else if (wcscmp(L"/START", (wchar_t *)szArgList[i]) == 0)
		{
			cmderStart = szArgList[i + 1];
			i++;
		}
		else if (wcscmp(L"/TASK", (wchar_t *)szArgList[i]) == 0)
		{
			cmderTask = szArgList[i + 1];
			i++;
		}
		else if (wcscmp(L"/SINGLE", (wchar_t *)szArgList[i]) == 0)
		{
			cmderSingle = true;
		}
	}

	/*
		if (cmdOptionExists(&opts.argv, &opts.argv + opts.argc, "/REGISTER"))
		{
			cmderRegScope = getCmdOption(&opts.argv, &opts.argv + opts.argc, "/REGISTER");
			registerApp = true;
		}
		else if (cmdOptionExists(&opts.argv, &opts.argv + opts.argc, "/UNREGISTER"))
		{
			cmderRegScope = getCmdOption(&opts.argv, &opts.argv + opts.argc, "/UNREGISTER");
			unRegisterApp = true;
		}
	}
	*/
	
	if ( registerApp == true ) {
		RegisterShellMenu(cmderRegScope, SHELL_MENU_REGISTRY_PATH_BACKGROUND);
		RegisterShellMenu(cmderRegScope, SHELL_MENU_REGISTRY_PATH_LISTITEM);
	}
	else if ( unRegisterApp == true )
	{
		UnregisterShellMenu(cmderRegScope, SHELL_MENU_REGISTRY_PATH_BACKGROUND);
		UnregisterShellMenu(cmderRegScope, SHELL_MENU_REGISTRY_PATH_LISTITEM);
	}
	else
	{
		StartCmder(cmderStart, cmderSingle, cmderTask, cmderCfgRoot);
	}
	
	return 0;
}

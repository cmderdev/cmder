#include <windows.h>
#include <tchar.h>
#include <Shlwapi.h>
#include "resource.h"
#include <vector>
#include <shlobj.h>

#include <regex>
#include <iostream>

#pragma comment(lib, "Shlwapi.lib")
#pragma comment(lib, "comctl32.lib")
#pragma warning( disable : 4091 )

#ifndef UNICODE
#error "Must be compiled with unicode support."
#endif

#define USE_TASKBAR_API (_WIN32_WINNT >= _WIN32_WINNT_WIN7)

#define MB_TITLE L"Cmder Launcher"
#define SHELL_MENU_REGISTRY_PATH_BACKGROUND L"Directory\\Background\\shell\\Cmder"
#define SHELL_MENU_REGISTRY_PATH_LISTITEM L"Directory\\shell\\Cmder"
#define SHELL_MENU_REGISTRY_DRIVE_PATH_BACKGROUND L"Drive\\Background\\shell\\Cmder"
#define SHELL_MENU_REGISTRY_DRIVE_PATH_LISTITEM L"Drive\\shell\\Cmder"

#define streqi(a, b) (_wcsicmp((a), (b)) == 0)

#define WIDEN2(x) L ## x
#define WIDEN(x) WIDEN2(x)
#define __WFUNCTION__ WIDEN(__FUNCTION__)

#define FAIL_ON_ERROR(x) { DWORD ec; if ((ec = (x)) != ERROR_SUCCESS) { ShowErrorAndExit(ec, __WFUNCTION__, __LINE__); } }

void TaskDialogOpen( PCWSTR mainStr, PCWSTR contentStr )
{

	HRESULT hr = NULL;

	TASKDIALOGCONFIG tsk = {sizeof(tsk)};

	HWND hOwner = NULL;
	HINSTANCE hInstance = GetModuleHandle(NULL);
	PCWSTR tskTitle = MAKEINTRESOURCE(IDS_TITLE);

	tsk.hInstance = hInstance;
	tsk.pszMainIcon = MAKEINTRESOURCE(IDI_CMDER);
	tsk.pszWindowTitle = tskTitle;
	tsk.pszMainInstruction = mainStr;
	tsk.pszContent = contentStr;

	TASKDIALOG_BUTTON btns[1] = {
		{ IDOK,     L"OK" }
	};

	tsk.dwFlags        = TDF_ALLOW_DIALOG_CANCELLATION|TDF_ENABLE_HYPERLINKS;
	tsk.pButtons       = btns;
	tsk.cButtons       = _countof(btns);

	tsk.hwndParent     = hOwner;

	int selectedButtonId = IDOK;

	hr = TaskDialogIndirect( &tsk, &selectedButtonId, NULL, NULL );

}

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

void StartCmder(std::wstring  path = L"", bool is_single_mode = false, std::wstring taskName = L"", std::wstring title = L"", std::wstring iconPath = L"", std::wstring cfgRoot = L"", bool use_user_cfg = true, std::wstring conemu_args = L"", bool admin = false)
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
	wchar_t defaultCfgPath[MAX_PATH] = { 0 };
	wchar_t terminalPath[MAX_PATH] = { 0 };
	wchar_t configDirPath[MAX_PATH] = { 0 };
	wchar_t userConfigDirPath[MAX_PATH] = { 0 };
	wchar_t userBinDirPath[MAX_PATH] = { 0 };
	wchar_t userProfiledDirPath[MAX_PATH] = { 0 };
	wchar_t userProfilePath[MAX_PATH] = { 0 };
	wchar_t legacyUserProfilePath[MAX_PATH] = { 0 };
	wchar_t userAliasesPath[MAX_PATH] = { 0 };
	wchar_t legacyUserAliasesPath[MAX_PATH] = { 0 };
	wchar_t args[MAX_PATH * 2 + 256] = { 0 };
	wchar_t userConEmuCfgPath[MAX_PATH] = { 0 };
	wchar_t windowsTerminalDir[MAX_PATH] = { 0 };
	wchar_t conEmuDir[MAX_PATH] = { 0 };
	wchar_t winDir[MAX_PATH] = { 0 };
	wchar_t vendorDir[MAX_PATH] = { 0 };
	wchar_t initCmd[MAX_PATH] = { 0 };
	wchar_t initPowerShell[MAX_PATH] = { 0 };
	wchar_t initBash[MAX_PATH] = { 0 };
	wchar_t initMintty[MAX_PATH] = { 0 };
	wchar_t vendoredGit[MAX_PATH] = { 0 };
	wchar_t amdx64Git[MAX_PATH] = { 0 };
	wchar_t x86Git[MAX_PATH] = { 0 };
	wchar_t programFiles[MAX_PATH] = { 0 };
	wchar_t programFilesX86[MAX_PATH] = { 0 };
	wchar_t minTTYPath[MAX_PATH] = { 0 };

	std::wstring cmderStart = path;
	std::wstring cmderTask = taskName;
	std::wstring cmderTitle = title;
	std::wstring cmderTerminalArgs = conemu_args;

	std::copy(cfgRoot.begin(), cfgRoot.end(), userConfigDirPath);
	userConfigDirPath[cfgRoot.length()] = 0;

	GetModuleFileName(NULL, exeDir, sizeof(exeDir));

#if USE_TASKBAR_API
	wcscpy_s(appId, exeDir);
#endif

	PathRemoveFileSpec(exeDir);

	if (PathFileExists(iconPath.c_str()))
	{
		std::copy(iconPath.begin(), iconPath.end(), icoPath);
		icoPath[iconPath.length()] = 0;
	}
	else
	{
		PathCombine(icoPath, exeDir, L"icons\\cmder.ico");
	}

	PathCombine(configDirPath, exeDir, L"config");

	/*
	Convert legacy user-profile.cmd to new name user_profile.cmd
	*/
	PathCombine(legacyUserProfilePath, configDirPath, L"user-profile.cmd");
	if (PathFileExists(legacyUserProfilePath))
	{
		PathCombine(userProfilePath, configDirPath, L"user_profile.cmd");

		char* lPr = (char*)malloc(MAX_PATH);
		char* pR = (char*)malloc(MAX_PATH);
		size_t i;
		wcstombs_s(&i, lPr, (size_t)MAX_PATH,
			legacyUserProfilePath, (size_t)MAX_PATH);
		wcstombs_s(&i, pR, (size_t)MAX_PATH,
			userProfilePath, (size_t)MAX_PATH);
		rename(lPr, pR);
	}

	/*
	Convert legacy user-aliases.cmd to new name user_aliases.cmd
	*/
	PathCombine(legacyUserAliasesPath, configDirPath, L"user-aliases.cmd");
	if (PathFileExists(legacyUserAliasesPath))
	{
		PathCombine(userAliasesPath, configDirPath, L"user_aliases.cmd");

		char* lPr = (char*)malloc(MAX_PATH);
		char* pR = (char*)malloc(MAX_PATH);
		size_t i;
		wcstombs_s(&i, lPr, (size_t)MAX_PATH,
			legacyUserAliasesPath, (size_t)MAX_PATH);
		wcstombs_s(&i, pR, (size_t)MAX_PATH,
			userAliasesPath, (size_t)MAX_PATH);
		rename(lPr, pR);
	}

	/*
	Was /c [path] specified?
	*/
	if (wcscmp(userConfigDirPath, L"") == 0)
	{
		// No - It wasn't.
		PathCombine(userConfigDirPath, exeDir, L"config");
	}
	else
	{
		// Yes - It was.
		PathCombine(userBinDirPath, userConfigDirPath, L"bin");
		SHCreateDirectoryEx(0, userBinDirPath, 0);

		PathCombine(userConfigDirPath, userConfigDirPath, L"config");
		SHCreateDirectoryEx(0, userConfigDirPath, 0);

		PathCombine(userProfiledDirPath, userConfigDirPath, L"profile.d");
		SHCreateDirectoryEx(0, userProfiledDirPath, 0);

		/*
		Convert legacy user-profile.cmd to new name user_profile.cmd
		*/
		PathCombine(legacyUserProfilePath, userConfigDirPath, L"user-profile.cmd");
		if (PathFileExists(legacyUserProfilePath))
		{
			PathCombine(userProfilePath, userConfigDirPath, L"user_profile.cmd");

			char* lPr = (char*)malloc(MAX_PATH);
			char* pR = (char*)malloc(MAX_PATH);
			size_t i;
			wcstombs_s(&i, lPr, (size_t)MAX_PATH,
				legacyUserProfilePath, (size_t)MAX_PATH);
			wcstombs_s(&i, pR, (size_t)MAX_PATH,
				userProfilePath, (size_t)MAX_PATH);
			rename(lPr, pR);
		}

		/*
		Convert legacy user-aliases.cmd to new name user_aliases.cmd
		*/
		PathCombine(legacyUserAliasesPath, userConfigDirPath, L"user-aliases.cmd");
		if (PathFileExists(legacyUserAliasesPath))
		{
			PathCombine(userAliasesPath, userConfigDirPath, L"user_aliases.cmd");

			char* lPr = (char*)malloc(MAX_PATH);
			char* pR = (char*)malloc(MAX_PATH);
			size_t i;
			wcstombs_s(&i, lPr, (size_t)MAX_PATH,
				legacyUserAliasesPath, (size_t)MAX_PATH);
			wcstombs_s(&i, pR, (size_t)MAX_PATH,
				userAliasesPath, (size_t)MAX_PATH);
			rename(lPr, pR);
		}
	}

	PathCombine(vendorDir, exeDir, L"vendor");
	PathCombine(windowsTerminalDir, vendorDir, L"windows-terminal");
	PathCombine(conEmuDir, vendorDir, L"conemu-maximus5");
	GetEnvironmentVariable(L"WINDIR", winDir, MAX_PATH);

	if (PathFileExists(windowsTerminalDir))
	{
		// Set path to vendored ConEmu config file
		PathCombine(cfgPath, windowsTerminalDir, L"settings\\settings.json");

		// Set path to Cmder default ConEmu config file
		PathCombine(defaultCfgPath, exeDir, L"vendor\\windows_terminal_default_settings.json");

		// Check for machine-specific then user config source file.
		PathCombine(cpuCfgPath, userConfigDirPath, L"windows_terminal_%COMPUTERNAME%_settings.json");
		ExpandEnvironmentStrings(cpuCfgPath, cpuCfgPath, sizeof(cpuCfgPath) / sizeof(cpuCfgPath[0]));

		// Set path to Cmder user ConEmu config file
		PathCombine(userCfgPath, userConfigDirPath, L"user_windows_terminal_settings.json");
	}
	else if (PathFileExists(conEmuDir))
	{
		// Set path to vendored ConEmu config file
		PathCombine(cfgPath, conEmuDir, L"ConEmu.xml");

		// Set path to Cmder default ConEmu config file
		PathCombine(defaultCfgPath, exeDir, L"vendor\\ConEmu.xml.default");

		// Check for machine-specific then user config source file.
		PathCombine(cpuCfgPath, userConfigDirPath, L"ConEmu-%COMPUTERNAME%.xml");
		ExpandEnvironmentStrings(cpuCfgPath, cpuCfgPath, sizeof(cpuCfgPath) / sizeof(cpuCfgPath[0]));

		// Set path to Cmder user ConEmu config file
		PathCombine(userCfgPath, userConfigDirPath, L"user-ConEmu.xml");
	}

	if (wcscmp(cpuCfgPath, L"") == 0 && (PathFileExists(cpuCfgPath) || use_user_cfg == false)) // config/ConEmu-%COMPUTERNAME%.xml file exists or /m was specified on command line, use machine specific config.
	{
		if (cfgRoot.length() == 0) // '/c [path]' was NOT specified
		{
			if (!CopyFile(cfgPath, cpuCfgPath, FALSE))
			{
				if (PathFileExists(windowsTerminalDir)) {
					MessageBox(NULL,
						(GetLastError() == ERROR_ACCESS_DENIED)
						? L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/windows_terminal_%COMPUTERNAME%_settings.json! Access Denied."
						: L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/windows_teerminal_%COMPUTERNAME%_settigns.json!", MB_TITLE, MB_ICONSTOP);
					exit(1);
				}
				else if (PathFileExists(conEmuDir))
				{
					MessageBox(NULL,
						(GetLastError() == ERROR_ACCESS_DENIED)
						? L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/ConEmu-%COMPUTERNAME%.xml! Access Denied."
						: L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/ConEmu-%COMPUTERNAME%.xml!", MB_TITLE, MB_ICONSTOP);
					exit(1);
				}
			}
		}
		else // vendor/conemu-maximus5/ConEmu.xml config file does not exist, copy config/ConEmu-%COMPUTERNAME%.xml to vendor/conemu-maximus5/ConEmu.xml file
		{
			if (!CopyFile(cpuCfgPath, cfgPath, FALSE))
			{
				if (PathFileExists(windowsTerminalDir))
				{
					MessageBox(NULL,
						(GetLastError() == ERROR_ACCESS_DENIED)
						? L"Failed to copy config/windows_terminal_%COMPUTERNAME%_settings.json file to vendor/windows-terminal/settings/settings.json! Access Denied."
						: L"Failed to copy config/windows_terminal_%COMPUTERNAME%_settings.json file to vendor/windows-terminal/settings/settings.json!", MB_TITLE, MB_ICONSTOP);
					exit(1);
				}
				else if (PathFileExists(conEmuDir))
				{
					MessageBox(NULL,
						(GetLastError() == ERROR_ACCESS_DENIED)
						? L"Failed to copy config/ConEmu-%COMPUTERNAME%.xml file to vendor/conemu-maximus5/ConEmu.xml! Access Denied."
						: L"Failed to copy config/ConEmu-%COMPUTERNAME%.xml file to vendor/conemu-maximus5/ConEmu.xml!", MB_TITLE, MB_ICONSTOP);
					exit(1);
				}
			}
		}
	}
	else if (wcscmp(userCfgPath, L"") == 0 && PathFileExists(userCfgPath)) // config/user_conemu.xml exists, use it.
	{
		if (cfgRoot.length() == 0) // '/c [path]' was NOT specified
		{
			if (PathFileExists(cfgPath)) // vendor/conemu-maximus5/ConEmu.xml exists, copy vendor/conemu-maximus5/ConEmu.xml to config/user_conemu.xml.
			{
				if (!CopyFile(cfgPath, userCfgPath, FALSE))
				{
					if (PathFileExists(windowsTerminalDir))
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/windows_terminal_settings.json! Access Denied."
							: L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/windows_teerminal_settigns.json!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
					else if (PathFileExists(conEmuDir))
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/user-conemu.xml! Access Denied."
							: L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/user-conemu.xml!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
				}
			}
			else // vendor/conemu-maximus5/ConEmu.xml does not exist, copy config/user-conemu.xml to vendor/conemu-maximus5/ConEmu.xml
			{
				if (!CopyFile(userCfgPath, cfgPath, FALSE))
				{
					if (PathFileExists(windowsTerminalDir))
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy config/user_windows_terminal_settings.json file to vendor/windows-terminal/settings/settings.json! Access Denied."
							: L"Failed to copy config/user_windows_terminal_settings.json file to vendor/windows-terminal/settings/settings.json!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
					else if (PathFileExists(conEmuDir))
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy config/user-conemu.xml file to vendor/conemu-maximus5/ConEmu.xml! Access Denied."
							: L"Failed to copy config/user-conemu.xml file to vendor/conemu-maximus5/ConEmu.xml!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
				}
			}
		}
		else if (!PathFileExists(windowsTerminalDir)) { // '/c [path]' was specified, don't copy anything and use existing user_conemu.xml to start comemu.
			PathCombine(userConEmuCfgPath, userConfigDirPath, L"user-ConEmu.xml");
		}
	}
	else if (cfgRoot.length() == 0) // '/c [path]' was NOT specified
	{
		if (PathFileExists(cfgPath)) // vendor/conemu-maximus5/ConEmu.xml exists, copy vendor/conemu-maximus5/ConEmu.xml to config/user_conemu.xml
		{
			if (!CopyFile(cfgPath, userCfgPath, FALSE))
			{
				if (PathFileExists(windowsTerminalDir))
				{
					MessageBox(NULL,
						(GetLastError() == ERROR_ACCESS_DENIED)
						? L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/user_windows_terminal_settings.json! Access Denied."
						: L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/user_windows_terminal_settigns.json!", MB_TITLE, MB_ICONSTOP);
					exit(1);
				}
				else if (PathFileExists(conEmuDir))
				{
					MessageBox(NULL,
						(GetLastError() == ERROR_ACCESS_DENIED)
						? L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/user-conemu.xml! Access Denied."
						: L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/user-conemu.xml!", MB_TITLE, MB_ICONSTOP);
					exit(1);
				}
			}
			else // vendor/ConEmu.xml.default config exists, copy Cmder vendor/ConEmu.xml.default file to vendor/conemu-maximus5/ConEmu.xml.
			{
				if (!CopyFile(defaultCfgPath, cfgPath, FALSE))
				{
					if (PathFileExists(windowsTerminalDir))
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy vendor/windows-terminal_default_settings_settings.json file to vendor/windows-terminal/settings/settings.json! Access Denied."
							: L"Failed to copy vendor/windows-terminal_default_settings_settings.json file to vendor/windows-terminal/settings/settigns.json!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
					else if (PathFileExists(conEmuDir))
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy vendor/ConEmu.xml.default file to vendor/conemu-maximus5/ConEmu.xml! Access Denied."
							: L"Failed to copy vendor/ConEmu.xml.default file to vendor/conemu-maximus5/ConEmu.xml!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
				}
			}
		}
		else if (!CopyFile(defaultCfgPath, cfgPath, FALSE) && PathFileExists(conEmuDir))
		{
			MessageBox(NULL,
				(GetLastError() == ERROR_ACCESS_DENIED)
				? L"Failed to copy vendor/ConEmu.xml.default file to vendor/conemu-maximus5/ConEmu.xml! Access Denied."
				: L"Failed to copy vendor/ConEmu.xml.default file to vendor/conemu-maximus5/ConEmu.xml!", MB_TITLE, MB_ICONSTOP);
			exit(1);
		}
	}
	else if (wcscmp(cfgPath, L"") == 0 && PathFileExists(cfgPath)) // vendor/conemu-maximus5/ConEmu.xml exists, copy vendor/conemu-maximus5/ConEmu.xml to config/user_conemu.xml
	{
		if (!CopyFile(cfgPath, userCfgPath, FALSE))
		{
			if (PathFileExists(windowsTerminalDir))
			{
				MessageBox(NULL,
					(GetLastError() == ERROR_ACCESS_DENIED)
					? L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/user_windows_terminal_settings_settings.json! Access Denied."
					: L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/user_windows_terminal_settings_settigns.json!", MB_TITLE, MB_ICONSTOP);
				exit(1);
			}
			else
			{
				MessageBox(NULL,
					(GetLastError() == ERROR_ACCESS_DENIED)
					? L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/user-conemu.xml! Access Denied."
					: L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/user-conemu.xml!", MB_TITLE, MB_ICONSTOP);
				exit(1);
			}
		}

		PathCombine(userConEmuCfgPath, userConfigDirPath, L"user-ConEmu.xml");
	}
	else if (wcscmp(defaultCfgPath, L"") == 0) // '/c [path]' was specified and 'vendor/ConEmu.xml.default' config exists, copy Cmder 'vendor/ConEmu.xml.default' file to '[user specified path]/config/user_ConEmu.xml'.
	{
		if (!CopyFile(defaultCfgPath, userCfgPath, FALSE))
		{
			if (PathFileExists(windowsTerminalDir))
			{
				MessageBox(NULL,
					(GetLastError() == ERROR_ACCESS_DENIED)
					? L"Failed to copy vendor/windows-terminal_default_settings_settings.json file to [user specified path]/config/user_windows_terminal_settings.json! Access Denied."
					: L"Failed to copy vendor/windows-terminal_default_settings_settings.json file to [user specified path]/config/user_windows_terminal_settings.json!", MB_TITLE, MB_ICONSTOP);
				exit(1);
			}
			else
			{
				MessageBox(NULL,
					(GetLastError() == ERROR_ACCESS_DENIED)
					? L"Failed to copy vendor/ConEmu.xml.default file to [user specified path]/config/user_ConEmu.xml! Access Denied."
					: L"Failed to copy vendor/ConEmu.xml.default file to [user specified path]/config/user_ConEmu.xml!", MB_TITLE, MB_ICONSTOP);
				exit(1);
			}
		}
		PathCombine(userConEmuCfgPath, userConfigDirPath, L"user-ConEmu.xml");
	}

	GetEnvironmentVariable(L"ProgramFiles", programFiles, MAX_PATH);
	GetEnvironmentVariable(L"ProgramFiles(x86)", programFilesX86, MAX_PATH);

	PathCombine(vendoredGit, vendorDir, L"git-for-windows");
	PathCombine(amdx64Git, programFiles, L"Git");
	PathCombine(x86Git, programFilesX86, L"Git");

	SYSTEM_INFO sysInfo;
	GetNativeSystemInfo(&sysInfo);
	if (PathFileExists(windowsTerminalDir))
	{
		PathCombine(terminalPath, exeDir, L"vendor\\windows-terminal\\WindowsTerminal.exe");
	}
	else if (PathFileExists(conEmuDir))
	{
		swprintf_s(args, L"%s /Icon \"%s\"", args, icoPath);
		swprintf_s(args, L"%s /title \"%s\"", args, cmderTitle.c_str());
		PathCombine(terminalPath, exeDir, L"vendor\\conemu-maximus5\\ConEmu64.exe");
	}
	else
	{
		PathCombine(terminalPath, winDir, L"system32\\cmd.exe");

		if (streqi(cmderTask.c_str(), L"powershell"))
		{
			PathCombine(terminalPath, winDir, L"System32\\WindowsPowerShell\\v1.0\\powershell.exe");
		}
		/*
		else if (streqi(cmderTask.c_str(), L"mintty"))
		{
			if (PathFileExists(vendoredGit))
			{
				PathCombine(terminalPath, vendoredGit, L"git-bash.exe");
			}
			else if (PathFileExists(amdx64Git))
			{
				PathCombine(terminalPath, amdx64Git, L"git-bash.exe");
			}
			else if (PathFileExists(x86Git))
			{
				PathCombine(terminalPath, x86Git, L"git-bash.exe");
			}
		}
		*/
	}

	if (!streqi(cmderStart.c_str(), L""))
	{
		if (PathFileExists(windowsTerminalDir)) {
			swprintf_s(args, L"%s -d \"%s\"", args, cmderStart.c_str());
		}
		else
		{
			swprintf_s(args, L"%s /dir \"%s\"", args, cmderStart.c_str());
		}
	}

	if (is_single_mode)
	{
		if (!PathFileExists(windowsTerminalDir)) {
			swprintf_s(args, L"%s /single", args);
		}
	}

	if (cfgRoot.length() != 0)
	{
		if (!PathFileExists(windowsTerminalDir)) {
			swprintf_s(args, L"%s  -loadcfgfile \"%s\"", args, userConEmuCfgPath);
		}
	}

	if (!streqi(cmderTerminalArgs.c_str(), L""))
	{
		swprintf_s(args, L"%s %s", args, cmderTerminalArgs.c_str());
	}

	// The `/run` arg and its value MUST be the last arg of ConEmu
	// see : https://conemu.github.io/en/ConEmuArgs.html
	// > This must be the last used switch (excepting -new_console and -cur_console)
	PathCombine(initCmd, vendorDir, L"init.bat");
	PathCombine(initPowerShell, vendorDir, L"profile.ps1");
	PathCombine(initBash, vendorDir, L"start_git_bash.cmd");
	PathCombine(initMintty, vendorDir, L"start_git_mintty.cmd");

	if (!streqi(cmderTask.c_str(), L""))
	{
		if (PathFileExists(windowsTerminalDir)) {
			swprintf_s(args, L"%s -p \"%s\"", args, cmderTask.c_str());
		}
		else if (PathFileExists(conEmuDir))
		{
			swprintf_s(args, L"%s /run {%s}", args, cmderTask.c_str());
		}
		else
		{
			if (streqi(cmderTask.c_str(), L"powershell"))
			{
				swprintf_s(args, L"%s -ExecutionPolicy Bypass -NoLogo -NoProfile -NoExit -Command \"Invoke-Expression 'Import-Module ''%s'''\"", args, initPowerShell);
			}
			else if (streqi(cmderTask.c_str(), L"bash"))
			{
				swprintf_s(args, L"%s /c \"%s\"", args, initBash);
			}
			else if (streqi(cmderTask.c_str(), L"mintty"))
			{
				swprintf_s(args, L"%s /c \"%s\"", args, initMintty);
			}
			else if (streqi(cmderTask.c_str(), L"cmder"))
			{
				swprintf_s(args, L"%s /k \"%s\"", args, initCmd);
			}
		}
	}

	SetEnvironmentVariable(L"CMDER_ROOT", exeDir);
	if (wcscmp(userConfigDirPath, configDirPath) != 0)
	{
		SetEnvironmentVariable(L"CMDER_USER_CONFIG", userConfigDirPath);
		SetEnvironmentVariable(L"CMDER_USER_BIN", userBinDirPath);
	}

	// Try to find m'intty.exe' so ConEmu can launch using %MINTTY_EXE% in external Git for Cmder Mini.
	// See: https://github.com/Maximus5/ConEmu/issues/2559 for why this is commented.

	/* 
	if (PathFileExists(vendoredGit))
	{
		PathCombine(minTTYPath, vendoredGit, L"usr\\bin\\mintty.exe");
		SetEnvironmentVariable(L"MINTTY_EXE", minTTYPath);
	}
	else if (PathFileExists(amdx64Git))
	{
		PathCombine(minTTYPath, amdx64Git, L"usr\\bin\\mintty.exe");
		SetEnvironmentVariable(L"MINTTY_EXE", minTTYPath);
	}
	else if (PathFileExists(x86Git))
	{
		PathCombine(minTTYPath, x86Git, L"usr\\bin\\mintty.exe");
		SetEnvironmentVariable(L"MINTTY_EXE", minTTYPath);
	}
	*/

	// Ensure EnvironmentVariables are propagated.

	STARTUPINFO si = { 0 };

	si.cb = sizeof(STARTUPINFO);
#if USE_TASKBAR_API
	si.lpTitle = appId;
	si.dwFlags = STARTF_TITLEISAPPID;
#endif
	PROCESS_INFORMATION pi;

	// MessageBox(NULL, terminalPath, _T("Error"), MB_OK);
	// MessageBox(NULL, args, _T("Error"), MB_OK);
	// Let's try to rerun as Administrator
	SHELLEXECUTEINFO sei = { sizeof(sei) };
	sei.fMask = SEE_MASK_NOASYNC | SEE_MASK_NOCLOSEPROCESS;
	sei.lpVerb = L"runas";
	sei.lpFile = terminalPath;
	sei.lpParameters = args;
	sei.nShow = SW_SHOWNORMAL;
	
	if (admin && ShellExecuteEx(&sei))
	{
		if (!sei.hProcess)
		{
			Sleep(500);
			_ASSERTE(sei.hProcess != nullptr);
		}

		if (sei.hProcess)
		{
			WaitForSingleObject(sei.hProcess, INFINITE);
		}

		// int nZone = 0;
		// if (!HasZoneIdentifier(lsFile, nZone)
		// 	|| (nZone != 0 /*LocalComputer*/))
		// {
		// 	// Assuming that elevated copy has fixed all zone problems
		// 	break;
		// }
	}
	else if (!CreateProcess(terminalPath, args, NULL, NULL, false, 0, NULL, NULL, &si, &pi))
	{
		if (PathFileExists(windowsTerminalDir))
		{
			MessageBox(NULL, _T("Unable to create the Windows Terminal process!"), _T("Error"), MB_OK);
		}
		else if (PathFileExists(conEmuDir))
		{
			MessageBox(NULL, _T("Unable to create the ConEmu process!"), _T("Error"), MB_OK);
		}
		else
		{
			MessageBox(NULL, _T("Unable to create the Cmd process!"), _T("Error"), MB_OK);
		}
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
		FAIL_ON_ERROR(RegCreateKeyEx(HKEY_CURRENT_USER, L"Software\\Classes", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &root, NULL));
	}
	else
	{
		root = HKEY_CLASSES_ROOT;
	}

	return root;
}

void RegisterShellMenu(std::wstring opt, wchar_t* keyBaseName, std::wstring cfgRoot, bool single)
{
	wchar_t userConfigDirPath[MAX_PATH] = { 0 };

	// First, get the paths we will use

	wchar_t exePath[MAX_PATH] = { 0 };
	wchar_t icoPath[MAX_PATH] = { 0 };

	GetModuleFileName(NULL, exePath, sizeof(exePath));

	wchar_t commandStr[MAX_PATH + 20] = { 0 };
	wchar_t baseCommandStr[MAX_PATH + 20] = { 0 };
	if (single) {
		swprintf_s(baseCommandStr, L"\"%s\" /single", exePath);
	}
	else {
		swprintf_s(baseCommandStr, L"\"%s\"", exePath);
	}

	if (cfgRoot.length() == 0) // '/c [path]' was NOT specified
	{
		swprintf_s(commandStr, L"%s \"%%V\"", baseCommandStr);
	}
	else {
		std::copy(cfgRoot.begin(), cfgRoot.end(), userConfigDirPath);
		userConfigDirPath[cfgRoot.length()] = 0;
		swprintf_s(commandStr, L"%s /c \"%s\" \"%%V\"", baseCommandStr, userConfigDirPath);
	}

	// Now that we have `commandStr`, it's OK to change `exePath`...
	PathRemoveFileSpec(exePath);

	PathCombine(icoPath, exePath, L"icons\\cmder.ico");

	// Now set the registry keys
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
	HKEY root = GetRootKey(opt);
	HKEY cmderKey;
	FAIL_ON_ERROR(RegCreateKeyEx(root, keyBaseName, 0, NULL, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, NULL, &cmderKey, NULL));
	FAIL_ON_ERROR(RegDeleteTree(cmderKey, NULL));
	RegDeleteKeyEx(root, keyBaseName, KEY_ALL_ACCESS, NULL);
	RegCloseKey(cmderKey);
	RegCloseKey(root);
}

struct cmderOptions
{
	std::wstring cmderCfgRoot = L"";
	std::wstring cmderStart = L"";
	std::wstring cmderTask = L"";
	std::wstring cmderTitle = L"Cmder";
	std::wstring cmderIcon = L"";
	std::wstring cmderRegScope = L"USER";
	std::wstring cmderTerminalArgs = L"";
	bool cmderAdmin = false;
	bool cmderSingle = false;
	bool cmderUserCfg = true;
	bool registerApp = false;
	bool unRegisterApp = false;
	bool error = false;
};

cmderOptions GetOption()
{
	cmderOptions cmderOptions;
	LPWSTR *szArgList;
	int argCount;

	wchar_t windowsTerminalDir[MAX_PATH] = { 0 };
	wchar_t conEmuDir[MAX_PATH] = { 0 };
	wchar_t vendorDir[MAX_PATH] = { 0 };
	wchar_t exeDir[MAX_PATH] = { 0 };

	GetModuleFileName(NULL, exeDir, sizeof(exeDir));
	PathRemoveFileSpec(exeDir);

	PathCombine(vendorDir, exeDir, L"vendor");
	PathCombine(windowsTerminalDir, vendorDir, L"windows-terminal");
	PathCombine(conEmuDir, vendorDir, L"ConEmu-Maximus5");

	szArgList = CommandLineToArgvW(GetCommandLine(), &argCount);

	for (int i = 1; i < argCount; i++)
	{
		// MessageBox(NULL, szArgList[i], L"Arglist contents", MB_OK);
		if (cmderOptions.error == false) {
			if (_wcsicmp(L"/c", szArgList[i]) == 0)
			{
				TCHAR userProfile[MAX_PATH];
				const DWORD ret = GetEnvironmentVariable(L"USERPROFILE", userProfile, MAX_PATH);

				wchar_t cmderCfgRoot[MAX_PATH] = { 0 };
				PathCombine(cmderCfgRoot, userProfile, L"cmder_cfg");

				cmderOptions.cmderCfgRoot = cmderCfgRoot;

				if (szArgList[i + 1] != NULL && szArgList[i + 1][0] != '/')
				{
					cmderOptions.cmderCfgRoot = szArgList[i + 1];
					i++;
				}
			}
			else if (_wcsicmp(L"/start", szArgList[i]) == 0)
			{
				int len = wcslen(szArgList[i + 1]);
				if (wcscmp(&szArgList[i + 1][len - 1], L"\"") == 0)
				{
					szArgList[i + 1][len - 1] = '\0';
				}

				if (PathFileExists(szArgList[i + 1]))
				{
					cmderOptions.cmderStart = szArgList[i + 1];
					i++;
				}
				else
				{
					MessageBox(NULL, szArgList[i + 1], L"/START - Folder does not exist!", MB_OK);
				}
			}
			else if (_wcsicmp(L"/task", szArgList[i]) == 0 || PathFileExists(windowsTerminalDir) || PathFileExists(conEmuDir))
			{
				cmderOptions.cmderTask = szArgList[i + 1];
				i++;
			}
			else if (_wcsicmp(L"/title", szArgList[i]) == 0 && !PathFileExists(windowsTerminalDir) && PathFileExists(conEmuDir))
			{
				cmderOptions.cmderTitle = szArgList[i + 1];
				i++;
			}
			else if (_wcsicmp(L"/icon", szArgList[i]) == 0 && !PathFileExists(windowsTerminalDir) && PathFileExists(conEmuDir))
			{
				cmderOptions.cmderIcon = szArgList[i + 1];
				i++;
			}
			else if (_wcsicmp(L"/single", szArgList[i]) == 0 && !PathFileExists(windowsTerminalDir) && PathFileExists(conEmuDir))
			{
				cmderOptions.cmderSingle = true;
			}
			else if (_wcsicmp(L"/m", szArgList[i]) == 0 && !PathFileExists(windowsTerminalDir) && PathFileExists(conEmuDir))
			{
				cmderOptions.cmderUserCfg = false;
			}
			else if (_wcsicmp(L"/a", szArgList[i]) == 0 && !PathFileExists(windowsTerminalDir) && !PathFileExists(conEmuDir))
			{
				cmderOptions.cmderAdmin = true;
			}
			else if (_wcsicmp(L"/register", szArgList[i]) == 0)
			{
				cmderOptions.registerApp = true;
				cmderOptions.unRegisterApp = false;
				if (szArgList[i + 1] != NULL)
				{
					if (_wcsicmp(L"all", szArgList[i + 1]) == 0 || _wcsicmp(L"user", szArgList[i + 1]) == 0)
					{
						cmderOptions.cmderRegScope = szArgList[i + 1];
						i++;
					}
				}
			}
			else if (_wcsicmp(L"/unregister", szArgList[i]) == 0)
			{
				cmderOptions.unRegisterApp = true;
				cmderOptions.registerApp = false;
				if (szArgList[i + 1] != NULL)
				{
					if (_wcsicmp(L"all", szArgList[i + 1]) == 0 || _wcsicmp(L"user", szArgList[i + 1]) == 0)
					{
						cmderOptions.cmderRegScope = szArgList[i + 1];
						i++;
					}
				}
			}
			/* Used for passing arguments to conemu prog */
			else if (_wcsicmp(L"/x", szArgList[i]) == 0)
			{
				cmderOptions.cmderTerminalArgs = szArgList[i + 1];
				i++;
			}
			/* Bare double dash, remaining commandline is for conemu */
			else if (_wcsicmp(L"--", szArgList[i]) == 0)
			{
				std::wstring cmdline = std::wstring(GetCommandLineW());
				auto doubledash = cmdline.find(L" -- ");
				if (doubledash != std::string::npos)
				{
					cmderOptions.cmderTerminalArgs = cmdline.substr(doubledash + 4);
				}
				break;
			}
			else if (cmderOptions.cmderStart == L"")
			{
				int len = wcslen(szArgList[i]);
				if (wcscmp(&szArgList[i][len - 1], L"\"") == 0)
				{
					szArgList[i][len - 1] = '\0';
				}

				if (PathFileExists(szArgList[i]))
				{
					cmderOptions.cmderStart = szArgList[i];
					i++;
				}
				else
				{
					cmderOptions.error = true;
				}
			}
			else
			{
				cmderOptions.error = true;
			}
		}
	}

	if (!PathFileExists(windowsTerminalDir) && !PathFileExists(conEmuDir) && streqi(cmderOptions.cmderTask.c_str(), L""))
	{
		cmderOptions.cmderTask = L"cmder";
	}

	if (cmderOptions.error == true)
	{
		wchar_t validOptions[512];
		HMODULE hMod = GetModuleHandle(NULL);
		LoadString(hMod, IDS_SWITCHES, validOptions, 512);

		// display list of valid options on unrecognized parameter
		TaskDialogOpen( L"Unrecognized parameter.", validOptions );
	}

	LocalFree(szArgList);

	return cmderOptions;
}

int APIENTRY _tWinMain(_In_ HINSTANCE hInstance,
	_In_opt_ HINSTANCE hPrevInstance,
	_In_ LPTSTR    lpCmdLine,
	_In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);
	UNREFERENCED_PARAMETER(nCmdShow);

	cmderOptions cmderOptions = GetOption();

	wchar_t windowsTerminalDir[MAX_PATH] = { 0 };
	wchar_t exeDir[MAX_PATH] = { 0 };

	GetModuleFileName(NULL, exeDir, sizeof(exeDir));
	PathRemoveFileSpec(exeDir);
	PathCombine(windowsTerminalDir, exeDir, L"vendor\\windows-terminal");

	if (cmderOptions.registerApp == true)
	{
		if (PathFileExists(windowsTerminalDir))
		{
			RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_PATH_BACKGROUND, cmderOptions.cmderCfgRoot, cmderOptions.cmderSingle);
			RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_PATH_LISTITEM, cmderOptions.cmderCfgRoot, cmderOptions.cmderSingle);
			RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_DRIVE_PATH_BACKGROUND, cmderOptions.cmderCfgRoot, cmderOptions.cmderSingle);
			RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_DRIVE_PATH_LISTITEM, cmderOptions.cmderCfgRoot, cmderOptions.cmderSingle);
		}
		else
		{
			RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_PATH_BACKGROUND, cmderOptions.cmderCfgRoot, false);
			RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_PATH_LISTITEM, cmderOptions.cmderCfgRoot, false);
			RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_DRIVE_PATH_BACKGROUND, cmderOptions.cmderCfgRoot, false);
			RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_DRIVE_PATH_LISTITEM, cmderOptions.cmderCfgRoot, false);
		}
	}
	else if (cmderOptions.unRegisterApp == true)
	{
		UnregisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_PATH_BACKGROUND);
		UnregisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_PATH_LISTITEM);
		UnregisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_DRIVE_PATH_BACKGROUND);
		UnregisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_DRIVE_PATH_LISTITEM);
	}
	else if (cmderOptions.error == true)
	{
		return 1;
	}
	else
	{
		StartCmder(cmderOptions.cmderStart, cmderOptions.cmderSingle, cmderOptions.cmderTask, cmderOptions.cmderTitle, cmderOptions.cmderIcon, cmderOptions.cmderCfgRoot, cmderOptions.cmderUserCfg, cmderOptions.cmderTerminalArgs, cmderOptions.cmderAdmin);	}

	return 0;
}
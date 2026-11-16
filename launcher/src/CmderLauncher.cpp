#include <windows.h>
#include <tchar.h>
#include <Shlwapi.h>
#include "resource.h"
#include <string>
#include <utility>
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
	wchar_t * buffer = NULL;
	if (FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
		NULL, ec, 0, (LPWSTR)&buffer, 0, NULL) == 0)
	{
		buffer = NULL;
	}

	wchar_t message[1024];
	swprintf_s(message, L"%s\nFunction: %s\nLine: %d", buffer ? buffer : L"Unknown error. FormatMessage failed.", func, line);
	if (buffer != NULL)
	{
		LocalFree(buffer);
	}

	MessageBox(NULL, message, MB_TITLE, MB_OK | MB_ICONERROR);
	exit(1);
}

template <size_t N>
void CopyPathOrExit(const std::wstring& source, wchar_t (&destination)[N])
{
	if (source.length() >= N)
	{
		ShowErrorAndExit(ERROR_FILENAME_EXCED_RANGE, __WFUNCTION__, __LINE__);
	}
	wcscpy_s(destination, source.c_str());
}

template <size_t N>
void GetExecutablePath(wchar_t (&path)[N])
{
	const DWORD length = GetModuleFileName(NULL, path, static_cast<DWORD>(N));
	if (length == 0 || length >= N)
	{
		ShowErrorAndExit(length == 0 ? GetLastError() : ERROR_FILENAME_EXCED_RANGE, __WFUNCTION__, __LINE__);
	}
}

template <size_t N>
void ExpandPathEnvironmentStrings(wchar_t (&path)[N])
{
	wchar_t expandedPath[N] = { 0 };
	const DWORD length = ExpandEnvironmentStrings(path, expandedPath, static_cast<DWORD>(N));
	if (length == 0 || length > N)
	{
		ShowErrorAndExit(length == 0 ? GetLastError() : ERROR_FILENAME_EXCED_RANGE, __WFUNCTION__, __LINE__);
	}
	wcscpy_s(path, expandedPath);
}

enum class TerminalKind
{
	WindowsTerminal,
	ConEmu,
	Console
};

enum class TerminalSelection
{
	Auto,
	WindowsTerminal,
	ConEmu
};

TerminalKind DetectTerminal(const wchar_t * exeDir, TerminalSelection selection = TerminalSelection::Auto)
{
	wchar_t terminalPath[MAX_PATH] = { 0 };

	// Preserve Cmder's Windows Terminal-first preference when both emulators are bundled.
	PathCombine(terminalPath, exeDir, L"vendor\\windows-terminal\\WindowsTerminal.exe");
	if (selection != TerminalSelection::ConEmu && PathFileExists(terminalPath))
	{
		return TerminalKind::WindowsTerminal;
	}

	SYSTEM_INFO sysInfo;
	GetNativeSystemInfo(&sysInfo);
	PathCombine(terminalPath, exeDir,
		sysInfo.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_AMD64
			? L"vendor\\conemu-maximus5\\ConEmu64.exe"
			: L"vendor\\conemu-maximus5\\ConEmu.exe");
	if (selection != TerminalSelection::WindowsTerminal && PathFileExists(terminalPath))
	{
		return TerminalKind::ConEmu;
	}

	return TerminalKind::Console;
}

void MigrateLegacyConfigFile(const wchar_t * configDir, const wchar_t * legacyName, const wchar_t * currentName)
{
	wchar_t legacyPath[MAX_PATH] = { 0 };
	wchar_t currentPath[MAX_PATH] = { 0 };
	PathCombine(legacyPath, configDir, legacyName);
	PathCombine(currentPath, configDir, currentName);

	if (PathFileExists(legacyPath))
	{
		// MoveFile does not overwrite currentPath, preserving a file already migrated by the user.
		MoveFile(legacyPath, currentPath);
	}
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

std::wstring NormalizeTaskName(std::wstring taskName)
{
	// ConEmu task labels are commonly passed as "{task}" on the command line.
	// Strip the outer braces so we do not add a second pair later when building /run.
	if (taskName.length() > 1 && taskName.front() == L'{' && taskName.back() == L'}')
	{
		return taskName.substr(1, taskName.length() - 2);
	}

	return taskName;
}

void StartCmder(std::wstring  path = L"", bool is_single_mode = false, std::wstring taskName = L"", std::wstring title = L"", std::wstring iconPath = L"", std::wstring cfgRoot = L"", bool use_user_cfg = true, std::wstring conemu_args = L"", TerminalSelection terminalSelection = TerminalSelection::Auto)
{
	#if USE_TASKBAR_API
		wchar_t appId[MAX_PATH] = { 0 };
	#endif
	wchar_t exeDir[MAX_PATH] = { 0 };
	wchar_t icoPath[MAX_PATH] = { 0 };
	wchar_t cfgPath[MAX_PATH] = { 0 };
	wchar_t cpuCfgPath[MAX_PATH] = { 0 };
	wchar_t userCfgPath[MAX_PATH] = { 0 };
	wchar_t defaultCfgPath[MAX_PATH] = { 0 };
	wchar_t terminalPath[MAX_PATH] = { 0 };
	wchar_t configDirPath[MAX_PATH] = { 0 };
	wchar_t userConfigRootPath[MAX_PATH] = { 0 };
	wchar_t userConfigDirPath[MAX_PATH] = { 0 };
	wchar_t userBinDirPath[MAX_PATH] = { 0 };
	wchar_t userProfiledDirPath[MAX_PATH] = { 0 };
	// Avoid overlapping source/destination calls such as swprintf_s(args, L"%s ...", args).
	// std::wstring grows for long paths and terminal arguments instead of silently failing at a fixed buffer size.
	std::wstring args;
	wchar_t selectedTerminalConfigPath[MAX_PATH] = { 0 };
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
	cmderTask = NormalizeTaskName(cmderTask);
	std::wstring cmderTitle = title;
	std::wstring cmderTerminalArgs = conemu_args;

	CopyPathOrExit(cfgRoot, userConfigRootPath);
	CopyPathOrExit(cfgRoot, userConfigDirPath);

	GetExecutablePath(exeDir);

	#if USE_TASKBAR_API
		wcscpy_s(appId, exeDir);
	#endif

	PathRemoveFileSpec(exeDir);

	if (PathFileExists(iconPath.c_str()))
	{
		CopyPathOrExit(iconPath, icoPath);
	}
	else
	{
		PathCombine(icoPath, exeDir, L"icons\\cmder.ico");
	}

	PathCombine(configDirPath, exeDir, L"config");

	MigrateLegacyConfigFile(configDirPath, L"user-profile.cmd", L"user_profile.cmd");
	MigrateLegacyConfigFile(configDirPath, L"user-aliases.cmd", L"user_aliases.cmd");

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
		// Yes - cfgRoot is the `/c` root; Cmder configuration remains in its `config` child directory.
		PathCombine(userBinDirPath, userConfigRootPath, L"bin");
		SHCreateDirectoryEx(0, userBinDirPath, 0);

		PathCombine(userConfigDirPath, userConfigRootPath, L"config");
		SHCreateDirectoryEx(0, userConfigDirPath, 0);

		PathCombine(userProfiledDirPath, userConfigDirPath, L"profile.d");
		SHCreateDirectoryEx(0, userProfiledDirPath, 0);

		MigrateLegacyConfigFile(userConfigDirPath, L"user-profile.cmd", L"user_profile.cmd");
		MigrateLegacyConfigFile(userConfigDirPath, L"user-aliases.cmd", L"user_aliases.cmd");
	}

	PathCombine(vendorDir, exeDir, L"vendor");
	PathCombine(windowsTerminalDir, vendorDir, L"windows-terminal");
	PathCombine(conEmuDir, vendorDir, L"conemu-maximus5");
	GetEnvironmentVariable(L"WINDIR", winDir, MAX_PATH);
	const TerminalKind terminal = DetectTerminal(exeDir, terminalSelection);
	const bool isWindowsTerminal = terminal == TerminalKind::WindowsTerminal;
	const bool isConEmu = terminal == TerminalKind::ConEmu;
	// Windows Terminal cannot select a settings file per launch, so `/c` roots
	// must not enter the user-root terminal settings flows below.
	const bool useSharedWindowsTerminalSettings = isWindowsTerminal && cfgRoot.length() != 0;

	if (isWindowsTerminal)
	{
		// Set path to vendored ConEmu config file
		PathCombine(cfgPath, windowsTerminalDir, L"settings\\settings.json");

		// Set path to Cmder default ConEmu config file
		PathCombine(defaultCfgPath, exeDir, L"vendor\\windows_terminal_default_settings.json");

		// Check for machine-specific then user config source file.
		PathCombine(cpuCfgPath, userConfigDirPath, L"windows_terminal_%COMPUTERNAME%_settings.json");
		ExpandPathEnvironmentStrings(cpuCfgPath);

		// Set path to Cmder user ConEmu config file
		PathCombine(userCfgPath, userConfigDirPath, L"user_windows_terminal_settings.json");
	}
	else if (isConEmu)
	{
		// Set path to vendored ConEmu config file
		PathCombine(cfgPath, conEmuDir, L"ConEmu.xml");

		// Set path to Cmder default ConEmu config file
		PathCombine(defaultCfgPath, exeDir, L"vendor\\ConEmu.xml.default");

		// Check for machine-specific then user config source file.
		PathCombine(cpuCfgPath, userConfigDirPath, L"ConEmu-%COMPUTERNAME%.xml");
		ExpandPathEnvironmentStrings(cpuCfgPath);

		// Set path to Cmder user ConEmu config file
		PathCombine(userCfgPath, userConfigDirPath, L"user-ConEmu.xml");
	}

	// A first launch with `/c` still needs the installation's default profiles.
	// Never overwrite shared settings or import settings from the `/c` user root.
	if (useSharedWindowsTerminalSettings && !PathFileExists(cfgPath))
	{
		if (!CopyFile(defaultCfgPath, cfgPath, TRUE) && GetLastError() != ERROR_FILE_EXISTS)
		{
			ShowErrorAndExit(GetLastError(), __WFUNCTION__, __LINE__);
		}
	}

	if (!useSharedWindowsTerminalSettings && wcscmp(cpuCfgPath, L"") != 0 && (PathFileExists(cpuCfgPath) || use_user_cfg == false)) // Skip machine-specific terminal settings for `/c` Windows Terminal launches.
	{
		if (cfgRoot.length() == 0) // '/c [path]' was NOT specified
		{
			if (PathFileExists(cfgPath)) // [terminal emulator config] file exists, copy [terminal emulator config] to config/user_[terminal emulator config] file to backup any settings changes from previous sessions.
			{
				if (!CopyFile(cfgPath, cpuCfgPath, FALSE))
				{
				if (isWindowsTerminal) {
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/windows_terminal_%COMPUTERNAME%_settings.json! Access Denied."
							: L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/windows_terminal_%COMPUTERNAME%_settigns.json!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
					else if (isConEmu)
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/ConEmu-%COMPUTERNAME%.xml! Access Denied."
							: L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/ConEmu-%COMPUTERNAME%.xml!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
				}
			}
			else // [terminal emulator config] file does not exist, copy config/[host specific terminal emulator config] file to [terminal emulator config] file
			{
				if (!CopyFile(cpuCfgPath, cfgPath, FALSE))
				{
					if (isWindowsTerminal) {
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy config/windows_terminal_%COMPUTERNAME%_settings.json file to vendor/windows-terminal/settings/settings.json! Access Denied."
							: L"Failed to copy config/windows_terminal_%COMPUTERNAME%_settings.json file to vendor/windows-terminal/settings/settings.json!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
					else if (isConEmu)
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
	}
	else if (!useSharedWindowsTerminalSettings && wcscmp(userCfgPath, L"") != 0 && PathFileExists(userCfgPath)) // Skip user terminal settings for `/c` Windows Terminal launches.
	{
		if (cfgRoot.length() == 0) // '/c [path]' was NOT specified
		{
			if (PathFileExists(cfgPath)) // [terminal emulator config] file exists, copy [terminal emulator config] to config/user_[terminal emulator config] file to backup any settings changes from previous sessions.
			{
				if (!CopyFile(cfgPath, userCfgPath, FALSE))
				{
					if (isWindowsTerminal)
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/windows_terminal_settings.json! Access Denied."
							: L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/windows_terminal_settigns.json!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
					else if (isConEmu)
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/user-conemu.xml! Access Denied."
							: L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/user-conemu.xml!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
				}
			}
			else // [terminal emulator config] file does not exist, copy config/user_[terminal emulator config] file to [terminal emulator config] file
			{
				if (!CopyFile(userCfgPath, cfgPath, FALSE))
				{
					if (isWindowsTerminal)
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy config/user_windows_terminal_settings.json file to vendor/windows-terminal/settings/settings.json! Access Denied."
							: L"Failed to copy config/user_windows_terminal_settings.json file to vendor/windows-terminal/settings/settings.json!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
					else if (isConEmu)
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
	}
	else if (!useSharedWindowsTerminalSettings && cfgRoot.length() == 0) // Do not initialize user-root terminal settings for `/c` Windows Terminal launches.
	{
		if (PathFileExists(cfgPath)) // [terminal emulator config] file exists, copy [terminal emulator config] file to config/user_[terminal emulator config] file.
		{
			if (!CopyFile(cfgPath, userCfgPath, FALSE))
			{
				if (isWindowsTerminal)
				{
					MessageBox(NULL,
						(GetLastError() == ERROR_ACCESS_DENIED)
						? L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/user_windows_terminal_settings.json! Access Denied."
						: L"Failed to copy vendor/windows-terminal/settings/settings.json file to config/user_windows_terminal_settigns.json!", MB_TITLE, MB_ICONSTOP);
					exit(1);
				}
				else if (isConEmu)
				{
					MessageBox(NULL,
						(GetLastError() == ERROR_ACCESS_DENIED)
						? L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/user-conemu.xml! Access Denied."
						: L"Failed to copy vendor/conemu-maximus5/ConEmu.xml file to config/user-conemu.xml!", MB_TITLE, MB_ICONSTOP);
					exit(1);
				}
			}
			else // vendor/[terminal emulator config].default config exists, copy Cmder vendor/[terminal emulator config].default file to [terminal emulator config] file.
			{
				if (!CopyFile(defaultCfgPath, cfgPath, FALSE))
				{
					if (isWindowsTerminal)
					{
						MessageBox(NULL,
							(GetLastError() == ERROR_ACCESS_DENIED)
							? L"Failed to copy vendor/windows-terminal_default_settings_settings.json file to vendor/windows-terminal/settings/settings.json! Access Denied."
							: L"Failed to copy vendor/windows-terminal_default_settings_settings.json file to vendor/windows-terminal/settings/settigns.json!", MB_TITLE, MB_ICONSTOP);
						exit(1);
					}
					else if (isConEmu)
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
		else if (!CopyFile(defaultCfgPath, cfgPath, FALSE) && isConEmu)
		{
			MessageBox(NULL,
				(GetLastError() == ERROR_ACCESS_DENIED)
				? L"Failed to copy vendor/ConEmu.xml.default file to vendor/conemu-maximus5/ConEmu.xml! Access Denied."
				: L"Failed to copy vendor/ConEmu.xml.default file to vendor/conemu-maximus5/ConEmu.xml!", MB_TITLE, MB_ICONSTOP);
			exit(1);
		}
	}
	else if (!useSharedWindowsTerminalSettings && wcscmp(cfgPath, L"") != 0 && PathFileExists(cfgPath)) // Do not create user-root terminal settings for `/c` Windows Terminal launches.
	{
		if (!CopyFile(cfgPath, userCfgPath, FALSE))
		{
			if (isWindowsTerminal)
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

	}
	else if (!useSharedWindowsTerminalSettings && wcscmp(defaultCfgPath, L"") != 0) // Do not copy default terminal settings into `/c` Windows Terminal roots.
	{
		if ( ! CopyFile(defaultCfgPath, userCfgPath, FALSE))
		{
			if (isWindowsTerminal)
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
	}

	GetEnvironmentVariable(L"ProgramFiles", programFiles, MAX_PATH);
	GetEnvironmentVariable(L"ProgramFiles(x86)", programFilesX86, MAX_PATH);

	PathCombine(vendoredGit, vendorDir, L"git-for-windows");
	PathCombine(amdx64Git, programFiles, L"Git");
	PathCombine(x86Git, programFilesX86, L"Git");

	SYSTEM_INFO sysInfo;
	GetNativeSystemInfo(&sysInfo);
	if (isWindowsTerminal)
	{
		PathCombine(terminalPath, exeDir, L"vendor\\windows-terminal\\WindowsTerminal.exe");
	}
	else if (isConEmu)
	{
		args += L" /Icon \"";
		args += icoPath;
		args += L"\" /title \"";
		args += cmderTitle;
		args += L"\"";
		PathCombine(terminalPath, exeDir,
			sysInfo.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_AMD64
				? L"vendor\\conemu-maximus5\\ConEmu64.exe"
				: L"vendor\\conemu-maximus5\\ConEmu.exe");
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
		if (isWindowsTerminal) {
			args += L" -d \"";
			args += cmderStart;
			args += L"\"";
		}
		else
		{
			args += L" /dir \"";
			args += cmderStart;
			args += L"\"";
		}
	}

	if (is_single_mode)
	{
		if (!isWindowsTerminal) {
			args += L" /single";
		}
	}

	if (cfgRoot.length() != 0)
	{
		if (isConEmu)
		{
			// ConEmu can load a settings file per launch. Prefer the most specific
			// existing file, then fall back to the bundled configuration.
			if (PathFileExists(cpuCfgPath))
			{
				wcscpy_s(selectedTerminalConfigPath, cpuCfgPath);
			}
			else if (use_user_cfg && PathFileExists(userCfgPath))
			{
				wcscpy_s(selectedTerminalConfigPath, userCfgPath);
			}
			else
			{
				wcscpy_s(selectedTerminalConfigPath, cfgPath);
			}

			args += L"  -loadcfgfile \"";
			args += selectedTerminalConfigPath;
			args += L"\"";
		}
	}

	if (!streqi(cmderTerminalArgs.c_str(), L""))
	{
		args += L" ";
		args += cmderTerminalArgs;
	}

	// The `/run` arg and its value MUST be the last arg of ConEmu
	// see : https://conemu.github.io/en/ConEmuArgs.html
	// > This must be the last used switch (excepting -new_console and -cur_console)
	PathCombine(initCmd, vendorDir, L"init.cmd");
	PathCombine(initPowerShell, vendorDir, L"profile.ps1");
	PathCombine(initBash, vendorDir, L"start_git_bash.cmd");
	PathCombine(initMintty, vendorDir, L"start_git_mintty.cmd");

	if (!streqi(cmderTask.c_str(), L""))
	{
		if (isWindowsTerminal) {
			args += L" -p \"";
			args += cmderTask;
			args += L"\"";
		}
		else if (isConEmu)
		{
			args += L" /run {";
			args += cmderTask;
			args += L"}";
		}
		else
		{
			if (streqi(cmderTask.c_str(), L"powershell"))
			{
				args += L" -ExecutionPolicy Bypass -NoLogo -NoProfile -NoExit -Command \"Invoke-Expression 'Import-Module ''";
				args += initPowerShell;
				args += L"'''\"";
			}
			else if (streqi(cmderTask.c_str(), L"bash"))
			{
				args += L" /c \"";
				args += initBash;
				args += L"\"";
			}
			else if (streqi(cmderTask.c_str(), L"mintty"))
			{
				args += L" /c \"";
				args += initMintty;
				args += L"\"";
			}
			else if (streqi(cmderTask.c_str(), L"cmder"))
			{
				args += L" /k \"";
				args += initCmd;
				args += L"\"";
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

	STARTUPINFO si = { 0 };

	si.cb = sizeof(STARTUPINFO);
	#if USE_TASKBAR_API
		si.lpTitle = appId;
		si.dwFlags = STARTF_TITLEISAPPID;
	#endif
	PROCESS_INFORMATION pi;
	// CreateProcess may write into its command-line argument. A vector supplies mutable,
	// NUL-terminated storage without relying on the C++ standard-library version for mutable string data.
	std::vector<wchar_t> commandLine(args.begin(), args.end());
	commandLine.push_back(L'\0');

	if (!CreateProcess(terminalPath, commandLine.data(), NULL, NULL, false, 0, NULL, NULL, &si, &pi))
	{
		if (isWindowsTerminal)
		{
			MessageBox(NULL, _T("Unable to create the Windows Terminal process!"), _T("Error"), MB_OK);
		}
		else if (isConEmu)
		{
			MessageBox(NULL, _T("Unable to create the ConEmu process!"), _T("Error"), MB_OK);
		}
		else
		{
			MessageBox(NULL, _T("Unable to create the Cmd process!"), _T("Error"), MB_OK);
		}
		return;
	}

	// CreateProcess returns handles even when Cmder does not need to wait for the child.
	// Close them after launch so repeated invocations do not leak operating-system handles.
	CloseHandle(pi.hThread);
	CloseHandle(pi.hProcess);
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

void RegisterShellMenu(std::wstring opt, wchar_t* keyBaseName, std::wstring cfgRoot, bool single, TerminalSelection terminalSelection = TerminalSelection::Auto)
{
	wchar_t userConfigDirPath[MAX_PATH] = { 0 };

	// First, get the paths we will use

	wchar_t exePath[MAX_PATH] = { 0 };
	wchar_t icoPath[MAX_PATH] = { 0 };

	GetExecutablePath(exePath);

	std::wstring commandStr = L"\"";
	commandStr += exePath;
	commandStr += L"\"";
	if (terminalSelection == TerminalSelection::ConEmu) {
		commandStr += L" conemu";
	}
	else if (terminalSelection == TerminalSelection::WindowsTerminal) {
		commandStr += L" windows-terminal";
	}
	if (single) {
		commandStr += L" /single";
	}
	if (!cfgRoot.empty()) {
		CopyPathOrExit(cfgRoot, userConfigDirPath);
		commandStr += L" /c \"";
		commandStr += userConfigDirPath;
		commandStr += L"\"";
	}
	commandStr += L" \"%V\"";

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

	FAIL_ON_ERROR(RegSetValue(command, L"", REG_SZ, commandStr.c_str(), NULL));

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
	TerminalSelection terminalSelection = TerminalSelection::Auto;
	bool cmderSingle = false;
	bool cmderUserCfg = true;
	bool registerApp = false;
	bool unRegisterApp = false;
	bool error = false;
	std::wstring errorMessage = L"";
};

cmderOptions GetOption()
{
	cmderOptions cmderOptions;
	LPWSTR *szArgList;
	int argCount;

	wchar_t exeDir[MAX_PATH] = { 0 };

	GetExecutablePath(exeDir);
	PathRemoveFileSpec(exeDir);

	szArgList = CommandLineToArgvW(GetCommandLine(), &argCount);
	if (szArgList == NULL)
	{
		cmderOptions.error = true;
		return cmderOptions;
	}

	// Match Cmder.bat: terminal selectors are recognized only as the first argument.
	int firstOptionIndex = 1;
	if (argCount > 1 && _wcsicmp(L"conemu", szArgList[1]) == 0)
	{
		cmderOptions.terminalSelection = TerminalSelection::ConEmu;
		firstOptionIndex++;
	}
	else if (argCount > 1 && _wcsicmp(L"windows-terminal", szArgList[1]) == 0)
	{
		cmderOptions.terminalSelection = TerminalSelection::WindowsTerminal;
		firstOptionIndex++;
	}

	const TerminalKind terminal = DetectTerminal(exeDir, cmderOptions.terminalSelection);
	const bool isConEmu = terminal == TerminalKind::ConEmu;
	if (cmderOptions.terminalSelection != TerminalSelection::Auto && terminal == TerminalKind::Console)
	{
		cmderOptions.error = true;
		cmderOptions.errorMessage = cmderOptions.terminalSelection == TerminalSelection::ConEmu
			? L"The requested bundled ConEmu terminal is not available."
			: L"The requested bundled Windows Terminal is not available.";
	}

	for (int i = firstOptionIndex; i < argCount; i++)
	{
		// MessageBox(NULL, szArgList[i], L"Arglist contents", MB_OK);
		if (cmderOptions.error == false) {
			// A value-taking option can consume the next argument only when it exists and is not another slash-prefixed launcher option.
			const bool hasFollowingNonOptionArgument = i + 1 < argCount && szArgList[i + 1][0] != '/' &&
				szArgList[i + 1][0] != L'\0' && wcscmp(szArgList[i + 1], L"--") != 0;
			const bool needsValue = streqi(szArgList[i], L"/start") || streqi(szArgList[i], L"/task") ||
				streqi(szArgList[i], L"/x") || (isConEmu &&
				(streqi(szArgList[i], L"/title") || streqi(szArgList[i], L"/icon")));
			if (szArgList[i][0] == L'\0' ||
				(needsValue && (i + 1 >= argCount || szArgList[i + 1][0] == L'\0')))
			{
				cmderOptions.error = true;
				break;
			}

			if (_wcsicmp(L"/c", szArgList[i]) == 0)
			{
				if (hasFollowingNonOptionArgument)
				{
					cmderOptions.cmderCfgRoot = szArgList[i + 1];
					i++;
				}
				else
				{
					TCHAR userProfile[MAX_PATH] = { 0 };
					const DWORD ret = GetEnvironmentVariable(L"USERPROFILE", userProfile, _countof(userProfile));
					wchar_t cmderCfgRoot[MAX_PATH] = { 0 };
					if (ret == 0 || ret >= _countof(userProfile) || PathCombine(cmderCfgRoot, userProfile, L"cmder_cfg") == NULL)
					{
						cmderOptions.error = true;
						break;
					}
					cmderOptions.cmderCfgRoot = cmderCfgRoot;
				}
			}
			else if (_wcsicmp(L"/start", szArgList[i]) == 0)
			{
				size_t len = wcslen(szArgList[i + 1]);
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
					cmderOptions.error = true;
					MessageBox(NULL, szArgList[i + 1], L"/START - Folder does not exist!", MB_OK);
				}
			}
			else if (_wcsicmp(L"/task", szArgList[i]) == 0)
			{
				if (hasFollowingNonOptionArgument)
				{
					cmderOptions.cmderTask = szArgList[i + 1];
					i++;
				}
				else
				{
					cmderOptions.error = true;
				}
			}
			else if (_wcsicmp(L"bash", szArgList[i]) == 0 || _wcsicmp(L"powershell", szArgList[i]) == 0 ||
				(terminal == TerminalKind::WindowsTerminal && _wcsicmp(L"cmd", szArgList[i]) == 0))
			{
				cmderOptions.cmderTask = szArgList[i];
				if (terminal == TerminalKind::WindowsTerminal)
				{
					cmderOptions.cmderTask = streqi(szArgList[i], L"bash") ? L"Cmder - Bash" :
						streqi(szArgList[i], L"powershell") ? L"Cmder - PowerShell" : L"Cmder";
				}
			}
			else if (_wcsicmp(L"/title", szArgList[i]) == 0 || _wcsicmp(L"/icon", szArgList[i]) == 0 ||
				_wcsicmp(L"/single", szArgList[i]) == 0 || _wcsicmp(L"/m", szArgList[i]) == 0)
			{
				if (!isConEmu)
				{
					cmderOptions.error = true;
					cmderOptions.errorMessage = std::wstring(szArgList[i]) +
						L" is supported only when Cmder launches ConEmu. " +
						(terminal == TerminalKind::WindowsTerminal ? L"Windows Terminal" : L"the console") +
						L" is currently selected.";
					break;
				}

				if (_wcsicmp(L"/title", szArgList[i]) == 0)
				{
					cmderOptions.cmderTitle = szArgList[i + 1];
					i++;
				}
				else if (_wcsicmp(L"/icon", szArgList[i]) == 0)
				{
					cmderOptions.cmderIcon = szArgList[i + 1];
					i++;
				}
				else if (_wcsicmp(L"/single", szArgList[i]) == 0)
				{
					cmderOptions.cmderSingle = true;
				}
				else
				{
					cmderOptions.cmderUserCfg = false;
				}
			}
			else if (_wcsicmp(L"/register", szArgList[i]) == 0)
			{
				cmderOptions.registerApp = true;
				cmderOptions.unRegisterApp = false;
				if (i + 1 < argCount)
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
				if (i + 1 < argCount)
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
				size_t len = wcslen(szArgList[i]);
				if (wcscmp(&szArgList[i][len - 1], L"\"") == 0)
				{
					szArgList[i][len - 1] = '\0';
				}

				if (PathFileExists(szArgList[i]))
				{
					cmderOptions.cmderStart = szArgList[i];
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

	if (streqi(cmderOptions.cmderTask.c_str(), L""))
	{
		if (terminal == TerminalKind::Console)
		{
			cmderOptions.cmderTask = L"cmder";
		}
	}

	if (cmderOptions.error == true)
	{
		if (!cmderOptions.errorMessage.empty())
		{
			MessageBox(NULL, cmderOptions.errorMessage.c_str(), MB_TITLE, MB_OK | MB_ICONERROR);
		}
		else
		{
			wchar_t validOptions[512];
			HMODULE hMod = GetModuleHandle(NULL);
			LoadString(hMod, IDS_SWITCHES, validOptions, 512);

			// display list of valid options on unrecognized parameter
			TaskDialogOpen( L"Unrecognized parameter.", validOptions );
		}
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
	if (cmderOptions.error)
	{
		return 1;
	}

	wchar_t exeDir[MAX_PATH] = { 0 };

	GetExecutablePath(exeDir);
	PathRemoveFileSpec(exeDir);
	const TerminalKind terminal = DetectTerminal(exeDir, cmderOptions.terminalSelection);

	if (cmderOptions.registerApp == true)
	{
		const bool single = terminal == TerminalKind::ConEmu && cmderOptions.cmderSingle;
		RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_PATH_BACKGROUND, cmderOptions.cmderCfgRoot, single, cmderOptions.terminalSelection);
		RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_PATH_LISTITEM, cmderOptions.cmderCfgRoot, single, cmderOptions.terminalSelection);
		RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_DRIVE_PATH_BACKGROUND, cmderOptions.cmderCfgRoot, single, cmderOptions.terminalSelection);
		RegisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_DRIVE_PATH_LISTITEM, cmderOptions.cmderCfgRoot, single, cmderOptions.terminalSelection);
	}
	else if (cmderOptions.unRegisterApp == true)
	{
		UnregisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_PATH_BACKGROUND);
		UnregisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_PATH_LISTITEM);
		UnregisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_DRIVE_PATH_BACKGROUND);
		UnregisterShellMenu(cmderOptions.cmderRegScope, SHELL_MENU_REGISTRY_DRIVE_PATH_LISTITEM);
	}
	else
	{
		StartCmder(cmderOptions.cmderStart, cmderOptions.cmderSingle, cmderOptions.cmderTask, cmderOptions.cmderTitle, cmderOptions.cmderIcon, cmderOptions.cmderCfgRoot, cmderOptions.cmderUserCfg, cmderOptions.cmderTerminalArgs, cmderOptions.terminalSelection);
	}

	return 0;
}

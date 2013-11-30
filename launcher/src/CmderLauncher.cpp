#include <windows.h>
#include <tchar.h>
#include <Shlwapi.h>
#include "resource.h"

#pragma comment(lib, "Shlwapi.lib")

#define USE_TASKBAR_API (UNICODE && _WIN32_WINNT >= _WIN32_WINNT_WIN7)

int APIENTRY _tWinMain(_In_ HINSTANCE hInstance,
	_In_opt_ HINSTANCE hPrevInstance,
	_In_ LPTSTR    lpCmdLine,
	_In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);
	UNREFERENCED_PARAMETER(nCmdShow);

#if USE_TASKBAR_API
	TCHAR appId[MAX_PATH] = { 0 };
#endif
	TCHAR exeDir[MAX_PATH] = { 0 };
	TCHAR icoPath[MAX_PATH] = { 0 };
	TCHAR cfgPath[MAX_PATH] = { 0 };
	TCHAR conEmuPath[MAX_PATH] = { 0 };
	TCHAR args[MAX_PATH * 2 + 256] = { 0 };

	GetModuleFileName(NULL, exeDir, sizeof(exeDir));

#if USE_TASKBAR_API
	_tcscpy_s(appId, exeDir);
#endif

	PathRemoveFileSpec(exeDir);

	PathCombine(icoPath, exeDir, _T("icons\\cmder.ico"));
	PathCombine(cfgPath, exeDir, _T("config\\ConEmu.xml"));
	PathCombine(conEmuPath, exeDir, _T("vendor\\conemu-maximus5\\ConEmu.exe"));

	_tcscat_s(args, _T("/Icon \""));
	_tcscat_s(args, icoPath);
	_tcscat_s(args, _T("\" /Title Cmder /LoadCfgFile \""));
	_tcscat_s(args, cfgPath);
	_tcscat_s(args, _T("\""));

	SetEnvironmentVariable(_T("CMDER_ROOT"), exeDir);

	STARTUPINFO si = { 0 };
	si.cb = sizeof(STARTUPINFO);
#if USE_TASKBAR_API
	si.lpTitle = appId;
	si.dwFlags = STARTF_TITLEISAPPID;
#endif

	PROCESS_INFORMATION pi;

	CreateProcess(conEmuPath, args, NULL, NULL, false, 0, NULL, NULL, &si, &pi);

	return 0;
}
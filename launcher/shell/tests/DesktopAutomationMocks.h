// SPDX-License-Identifier: MIT
#pragma once

// Direct COM test doubles: every automation step is local and no desktop call
// or process launch reaches the host. Unused SDK methods fail explicitly.
namespace Test
{
    template <typename T>
    class DispatchStub : public Microsoft::WRL::RuntimeClass<Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>, T>
    {
    public:
        IFACEMETHODIMP GetTypeInfoCount(UINT*) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetTypeInfo(UINT, LCID, ITypeInfo**) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetIDsOfNames(REFIID, LPOLESTR*, UINT, LCID, DISPID*) override { return E_NOTIMPL; }
        IFACEMETHODIMP Invoke(DISPID, REFIID, LCID, WORD, DISPPARAMS*, VARIANT*, EXCEPINFO*, UINT*) override { return E_NOTIMPL; }
    };

    template <typename T>
    HRESULT CopyDispatch(const Microsoft::WRL::ComPtr<T>& object, IDispatch** output)
    {
        *output = static_cast<IDispatch*>(object.Get());
        (*output)->AddRef();
        return S_OK;
    }

    bool StopAutomation(unsigned stage, HRESULT& result)
    {
        if (native.automationStage != stage) { return false; }
        result = native.automationResult;
        return true;
    }

    class ShellApplication final : public DispatchStub<IShellDispatch2>
    {
    public:
        IFACEMETHODIMP ShellExecute(BSTR file, VARIANT args, VARIANT directory, VARIANT verb, VARIANT show) override
        {
            ++native.processCalls;
            Check(file && args.vt == VT_BSTR && directory.vt == VT_BSTR && verb.vt == VT_BSTR && show.vt == VT_I4 &&
                wcscmp(verb.bstrVal, L"open") == 0 && show.lVal == SW_SHOWNORMAL, "typed desktop ShellExecute arguments");
            native.application = file;
            native.commandLine = CmderShell::QuoteArgument(file) + L" " + args.bstrVal;
            native.arguments = Parse(native.commandLine);
            native.directory = directory.bstrVal;
            return native.automationStage == 7 ? native.automationResult : S_OK;
        }

        IFACEMETHODIMP get_Application(IDispatch **) override { return E_NOTIMPL; }
        IFACEMETHODIMP get_Parent(IDispatch **) override { return E_NOTIMPL; }
        IFACEMETHODIMP NameSpace(VARIANT, Folder **) override { return E_NOTIMPL; }
        IFACEMETHODIMP BrowseForFolder(long, BSTR, long, VARIANT, Folder **) override { return E_NOTIMPL; }
        IFACEMETHODIMP Windows(IDispatch **) override { return E_NOTIMPL; }
        IFACEMETHODIMP Open(VARIANT) override { return E_NOTIMPL; }
        IFACEMETHODIMP Explore(VARIANT) override { return E_NOTIMPL; }
        IFACEMETHODIMP MinimizeAll() override { return E_NOTIMPL; }
        IFACEMETHODIMP UndoMinimizeALL() override { return E_NOTIMPL; }
        IFACEMETHODIMP FileRun() override { return E_NOTIMPL; }
        IFACEMETHODIMP CascadeWindows() override { return E_NOTIMPL; }
        IFACEMETHODIMP TileVertically() override { return E_NOTIMPL; }
        IFACEMETHODIMP TileHorizontally() override { return E_NOTIMPL; }
        IFACEMETHODIMP ShutdownWindows() override { return E_NOTIMPL; }
        IFACEMETHODIMP Suspend() override { return E_NOTIMPL; }
        IFACEMETHODIMP EjectPC() override { return E_NOTIMPL; }
        IFACEMETHODIMP SetTime() override { return E_NOTIMPL; }
        IFACEMETHODIMP TrayProperties() override { return E_NOTIMPL; }
        IFACEMETHODIMP Help() override { return E_NOTIMPL; }
        IFACEMETHODIMP FindFiles() override { return E_NOTIMPL; }
        IFACEMETHODIMP FindComputer() override { return E_NOTIMPL; }
        IFACEMETHODIMP RefreshMenu() override { return E_NOTIMPL; }
        IFACEMETHODIMP ControlPanelItem(BSTR) override { return E_NOTIMPL; }
        IFACEMETHODIMP IsRestricted(BSTR, BSTR, long *) override { return E_NOTIMPL; }
        IFACEMETHODIMP FindPrinter(BSTR, BSTR, BSTR) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetSystemInformation(BSTR, VARIANT *) override { return E_NOTIMPL; }
        IFACEMETHODIMP ServiceStart(BSTR, VARIANT, VARIANT *) override { return E_NOTIMPL; }
        IFACEMETHODIMP ServiceStop(BSTR, VARIANT, VARIANT *) override { return E_NOTIMPL; }
        IFACEMETHODIMP IsServiceRunning(BSTR, VARIANT *) override { return E_NOTIMPL; }
        IFACEMETHODIMP CanStartStopService(BSTR, VARIANT *) override { return E_NOTIMPL; }
        IFACEMETHODIMP ShowBrowserBar(BSTR, VARIANT, VARIANT *) override { return E_NOTIMPL; }

    };

    class FolderAutomation final : public DispatchStub<IShellFolderViewDual>
    {
    public:
        IFACEMETHODIMP get_Application(IDispatch** output) override
        {
            *output = nullptr;
            HRESULT result;
            if (StopAutomation(6, result)) { return result; }
            if (native.badApplicationInterface) { return CopyDispatch(Microsoft::WRL::Make<DispatchStub<IDispatch>>(), output); }
            return CopyDispatch(Microsoft::WRL::Make<ShellApplication>(), output);
        }

        IFACEMETHODIMP get_Parent(IDispatch **) override { return E_NOTIMPL; }
        IFACEMETHODIMP get_Folder(Folder **) override { return E_NOTIMPL; }
        IFACEMETHODIMP SelectedItems(FolderItems **) override { return E_NOTIMPL; }
        IFACEMETHODIMP get_FocusedItem(FolderItem **) override { return E_NOTIMPL; }
        IFACEMETHODIMP SelectItem(VARIANT *, int) override { return E_NOTIMPL; }
        IFACEMETHODIMP PopupItemMenu(FolderItem *, VARIANT, VARIANT, BSTR *) override { return E_NOTIMPL; }
        IFACEMETHODIMP get_Script(IDispatch **) override { return E_NOTIMPL; }
        IFACEMETHODIMP get_ViewOptions(long *) override { return E_NOTIMPL; }

    };

    class DesktopView final : public Microsoft::WRL::RuntimeClass<Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>, IShellView>
    {
    public:
        IFACEMETHODIMP GetItemObject(UINT kind, REFIID iid, void** output) override
        {
            *output = nullptr;
            Check(kind == SVGIO_BACKGROUND && iid == __uuidof(IDispatch), "documented desktop background dispatch interface requested");
            HRESULT result;
            if (StopAutomation(5, result)) { return result; }
            if (native.badFolderInterface) { return CopyDispatch(Microsoft::WRL::Make<DispatchStub<IDispatch>>(), reinterpret_cast<IDispatch**>(output)); }
            return CopyDispatch(Microsoft::WRL::Make<FolderAutomation>(), reinterpret_cast<IDispatch**>(output));
        }
        IFACEMETHODIMP GetWindow(HWND*) override { return E_NOTIMPL; }
        IFACEMETHODIMP ContextSensitiveHelp(BOOL) override { return E_NOTIMPL; }

        IFACEMETHODIMP TranslateAccelerator(MSG *) override { return E_NOTIMPL; }
        IFACEMETHODIMP EnableModeless(BOOL) override { return E_NOTIMPL; }
        IFACEMETHODIMP UIActivate(UINT) override { return E_NOTIMPL; }
        IFACEMETHODIMP Refresh() override { return E_NOTIMPL; }
        IFACEMETHODIMP CreateViewWindow(IShellView *, LPCFOLDERSETTINGS, IShellBrowser *, RECT *, HWND *) override { return E_NOTIMPL; }
        IFACEMETHODIMP DestroyViewWindow() override { return E_NOTIMPL; }
        IFACEMETHODIMP GetCurrentInfo(LPFOLDERSETTINGS) override { return E_NOTIMPL; }
        IFACEMETHODIMP AddPropertySheetPages(_In_ DWORD, _In_ LPFNSVADDPROPSHEETPAGE, _In_ LPARAM) override { return E_NOTIMPL; }
        IFACEMETHODIMP SaveViewState() override { return E_NOTIMPL; }
        IFACEMETHODIMP SelectItem(PCUITEMID_CHILD, SVSIF) override { return E_NOTIMPL; }

    };

    class DesktopBrowser final : public Microsoft::WRL::RuntimeClass<Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>, IShellBrowser>
    {
    public:
        IFACEMETHODIMP QueryActiveShellView(IShellView** output) override
        {
            *output = nullptr;
            HRESULT result;
            if (StopAutomation(4, result)) { return result; }
            return Microsoft::WRL::Make<DesktopView>().CopyTo(output);
        }
        IFACEMETHODIMP GetWindow(HWND*) override { return E_NOTIMPL; }
        IFACEMETHODIMP ContextSensitiveHelp(BOOL) override { return E_NOTIMPL; }

        IFACEMETHODIMP InsertMenusSB(HMENU, LPOLEMENUGROUPWIDTHS) override { return E_NOTIMPL; }
        IFACEMETHODIMP SetMenuSB(HMENU, HOLEMENU, HWND) override { return E_NOTIMPL; }
        IFACEMETHODIMP RemoveMenusSB(HMENU) override { return E_NOTIMPL; }
        IFACEMETHODIMP SetStatusTextSB(LPCWSTR) override { return E_NOTIMPL; }
        IFACEMETHODIMP EnableModelessSB(BOOL) override { return E_NOTIMPL; }
        IFACEMETHODIMP TranslateAcceleratorSB(MSG *, WORD) override { return E_NOTIMPL; }
        IFACEMETHODIMP BrowseObject(PCUIDLIST_RELATIVE, UINT) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetViewStateStream(DWORD, IStream **) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetControlWindow(UINT, HWND *) override { return E_NOTIMPL; }
        IFACEMETHODIMP SendControlMsg(_In_ UINT, _In_ UINT, _In_ WPARAM, _In_ LPARAM, _Out_opt_ LRESULT *) override { return E_NOTIMPL; }
        IFACEMETHODIMP OnViewWindowActive(IShellView *) override { return E_NOTIMPL; }
        IFACEMETHODIMP SetToolbarItems(_In_reads_opt_(nButtons) LPTBBUTTONSB, _In_ UINT, _In_ UINT) override { return E_NOTIMPL; }

    };

    class DesktopWindow final : public Microsoft::WRL::RuntimeClass<Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::ClassicCom>, IDispatch, IServiceProvider>
    {
    public:
        IFACEMETHODIMP GetTypeInfoCount(UINT*) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetTypeInfo(UINT, LCID, ITypeInfo**) override { return E_NOTIMPL; }
        IFACEMETHODIMP GetIDsOfNames(REFIID, LPOLESTR*, UINT, LCID, DISPID*) override { return E_NOTIMPL; }
        IFACEMETHODIMP Invoke(DISPID, REFIID, LCID, WORD, DISPPARAMS*, VARIANT*, EXCEPINFO*, UINT*) override { return E_NOTIMPL; }
        IFACEMETHODIMP QueryService(REFGUID service, REFIID iid, void** output) override
        {
            *output = nullptr;
            Check(service == SID_STopLevelBrowser && iid == __uuidof(IShellBrowser), "desktop browser service requested");
            HRESULT result;
            if (StopAutomation(3, result)) { return result; }
            return Microsoft::WRL::Make<DesktopBrowser>().CopyTo(iid, output);
        }
    };

    class DesktopWindows final : public DispatchStub<IShellWindows>
    {
    public:
        IFACEMETHODIMP FindWindowSW(VARIANT* location, VARIANT* root, int kind, long* window, int options, IDispatch** output) override
        {
            *output = nullptr;
            Check(location && location->vt == VT_I4 && location->lVal == CSIDL_DESKTOP && root && root->vt == VT_EMPTY &&
                kind == SWC_DESKTOP && options == SWFO_NEEDDISPATCH, "existing desktop window requested without creation");
            *window = 1;
            HRESULT result;
            if (StopAutomation(2, result)) { return result; }
            if (native.badDesktopInterface) { return CopyDispatch(Microsoft::WRL::Make<DispatchStub<IDispatch>>(), output); }
            return CopyDispatch(Microsoft::WRL::Make<DesktopWindow>(), output);
        }

        IFACEMETHODIMP get_Count(long *) override { return E_NOTIMPL; }
        IFACEMETHODIMP Item(VARIANT, IDispatch **) override { return E_NOTIMPL; }
        IFACEMETHODIMP _NewEnum(IUnknown **) override { return E_NOTIMPL; }
        IFACEMETHODIMP Register(IDispatch *, long, int, long *) override { return E_NOTIMPL; }
        IFACEMETHODIMP RegisterPending(long, VARIANT *, VARIANT *, int, long *) override { return E_NOTIMPL; }
        IFACEMETHODIMP Revoke(long) override { return E_NOTIMPL; }
        IFACEMETHODIMP OnNavigate(long, VARIANT *) override { return E_NOTIMPL; }
        IFACEMETHODIMP OnActivated(long, VARIANT_BOOL) override { return E_NOTIMPL; }
        IFACEMETHODIMP OnCreated(long, IUnknown *) override { return E_NOTIMPL; }
        IFACEMETHODIMP ProcessAttachDetach(VARIANT_BOOL) override { return E_NOTIMPL; }

    };

    HRESULT WINAPI DesktopCreate(REFCLSID clsid, LPUNKNOWN outer, DWORD context, REFIID iid, LPVOID* output)
    {
        ++native.desktopResolutions;
        *output = nullptr;
        Check(clsid == CLSID_ShellWindows && !outer && context == CLSCTX_LOCAL_SERVER && iid == __uuidof(IShellWindows),
            "only existing desktop ShellWindows automation resolved");
        HRESULT result;
        if (StopAutomation(1, result)) { return result; }
        return Microsoft::WRL::Make<DesktopWindows>().CopyTo(iid, output);
    }
}

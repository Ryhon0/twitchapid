module gui.tabcontrols;

import core.sys.windows.windows;
import core.sys.windows.commctrl;

import std.utf;

static HWND hwndTab;
static HWND* currentTabView;
static HWND[] tabs;

void addTabControl(HWND hwndParent, HINSTANCE hInst)
{
    RECT rcClient; 
    INITCOMMONCONTROLSEX icex;

    int i; 
    TCHAR[256] achTemp;  // Temporary buffer for strings.
 
    // Initialize common controls.
    icex.dwSize = INITCOMMONCONTROLSEX.sizeof;
    icex.dwICC = ICC_TAB_CLASSES;
    InitCommonControlsEx(&icex);

    // Get the dimensions of the parent window's client area, and 
    // create a tab control child window of that size.
    GetClientRect(hwndParent, &rcClient); 

    hwndTab = CreateWindow( WC_TABCONTROL.toUTF16z,
                            null,
                            WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS,
                            0,
                            0,
                            rcClient.right,
                            rcClient.bottom,
                            hwndParent,
                            null,
                            hInst,
                            null);

    if (hwndTab == NULL)
    { 
        return; 
    }

    CreateDialog(hInst, 
                 null,  //make a template for this?
                 hwndTab,
                 null);
}
void addTab(string name)
{
    TCITEM tie;
    tie.mask = TCIF_TEXT | TCIF_IMAGE; 
    tie.iImage = -1; 
    tie.pszText = cast(wchar*)name.toUTF16z; 
 
    if (TabCtrl_InsertItem(hwndTab, 0, &tie) == -1) 
    { 
        DestroyWindow(hwndTab); 
        return; 
    }
    


}

void CreateTabView(HWND parent, HINSTANCE inst)
{
    RECT rect = {0};  // rect structure to hold tab size

    // get the tab size info so
    // we can place the view window
    // in the right place
    TabCtrl_GetItemRect(parent, 0, &rect);

    // create second Static control for our view window.
    // this control is hidden, so we do NOT include
    // the WS_VISIBLE control style on this control
    HWND tabview = CreateWindowEx(
        0,                  // no extended style
        WC_EDIT.toUTF16z,   // Static class name
        "chatview",         // Static control's text
        WS_CHILD | WS_BORDER | SS_CENTER | SS_CENTERIMAGE,  // control style - NOT WS_VISIBLE!!!
        rect.left,          // x position
        rect.top,           // y position
        200,                // control width
        60,                 // control height
        parent,             // parent control
        NULL,               // no menu/ID info
        inst,               // instance handler
        NULL                // no extra creation data
    );


}

// HWND CreateRichEdit(HWND hwndOwner,        // Dialog box handle.
//                     int x, int y,          // Location.
//                     int width, int height, // Dimensions.
//                     HINSTANCE hinst)       // Application or DLL instance.
// {
//     LoadLibrary(TEXT("Msftedit.dll"));
    
//     HWND hwndEdit= CreateWindowEx(0, 
//                                   MSFTEDIT_CLASS, TEXT("Type here"),
//                                   ES_MULTILINE | WS_VISIBLE | WS_CHILD | WS_BORDER | WS_TABSTOP, 
//                                   x, y, width, height, 
//                                   hwndOwner,
//                                   NULL,
//                                   hinst,
//                                   NULL);
        
//     return hwndEdit;
// }
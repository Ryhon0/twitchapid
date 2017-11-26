module gui.tabcontrols;

import core.sys.windows.windows;
import core.sys.windows.commctrl;

import std.utf;

void addTabControl(HWND hwndParent, HINSTANCE hInst)
{
    RECT rcClient; 
    INITCOMMONCONTROLSEX icex;
    HWND hwndTab; 
    TCITEM tie; 
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

    tie.mask = TCIF_TEXT | TCIF_IMAGE; 
    tie.iImage = -1; 
    tie.pszText = cast(wchar*)"tab"; 
 
    if (TabCtrl_InsertItem(hwndTab, 0, &tie) == -1) 
    { 
        DestroyWindow(hwndTab); 
        return; 
    } 

}
module gui.menus;

import core.sys.windows.windows;
import gui.resources;


void addMenus(HWND hwnd) {

    HMENU hMenubar;
    HMENU hMenu;
    
    hMenubar = CreateMenu();
    hMenu = CreateMenu();

    AppendMenuW(hMenu, MF_STRING, IDM_FILE_NEW, "&New");
    AppendMenuW(hMenu, MF_STRING, IDM_FILE_OPEN, "&Open");
    AppendMenuW(hMenu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(hMenu, MF_STRING, IDM_FILE_QUIT, "&Quit");

    AppendMenuW(hMenubar, MF_POPUP, cast(UINT_PTR) hMenu, "&File");
    SetMenu(hwnd, hMenubar);
}
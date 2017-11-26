module main;

import core.runtime;
import core.sys.windows.windows;
import ircbod.client, ircbod.message;
import std.utf, std.conv;
import dyaml;
import gui.menus, gui.tabcontrols;

static IRCClient bot;
static bool running = false;

string appName = "HarshStorm";
HINSTANCE hInst;

int myWinMain(HINSTANCE instance, HINSTANCE prevInstance, LPSTR cmdLine, int iCmdShow)
{
    //set the window settings
    MSG msg;
    HWND window;
    WNDCLASS windowClass = {};

    windowClass.lpszClassName = appName.toUTF16z;
    windowClass.style         = CS_HREDRAW | CS_VREDRAW;
    windowClass.lpfnWndProc   =  cast(WNDPROC)&mainWindowCallback;
    windowClass.hInstance     = instance;
    windowClass.hbrBackground = cast(HBRUSH)GetStockObject(BLACK_BRUSH);
    windowClass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    windowClass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);

    if(!RegisterClass(&windowClass))
    {
        MessageBox(NULL, "This program requires Windows NT or later!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    window = CreateWindow(appName.toUTF16z,    // window class name
                         "Harsh Storm",        // window caption
                         WS_OVERLAPPEDWINDOW | WS_VISIBLE,  // window style
                         CW_USEDEFAULT,        // initial x position
                         CW_USEDEFAULT,        // initial y position
                         1280,                 // initial x size
                         720,                  // initial y size
                         NULL,                 // parent window handle
                         NULL,                 // window menu handle
                         instance,             // program instance handle
                         NULL);                // creation parameters

    ShowWindow(window, iCmdShow);
    UpdateWindow(window);

    //setup UI?
    startbot();

    // run message loop
    running = true;
    while (running)
    {   
        bot.readLine();
        //action all the windows messages
        while (PeekMessage(&msg, NULL,0 , 0, PM_REMOVE))
        {
            if(msg.message == WM_QUIT || msg.message == WM_CLOSE)
            {
                running = FALSE;
            }else
            {
                TranslateMessage(&msg);
                DispatchMessage(&msg);
            }
        }
    }
    
    return cast(int) msg.wParam;
}

void startbot()
{

    //Read the config.
    Node root = Loader("config.yaml").load();

    string username = root["username"].as!string;
    string oauth = root["oauth-token"].as!string;

    string[] channels;
    //Display the data read.
    foreach(string channel; root["channels"])
    {
        channels ~= channel;
    }

    bot = new IRCClient("irc.chat.twitch.tv", 6667, username, oauth, ["#philderbeast"]);

    bot.connect();

    bot.on(IRCMessage.Type.MESSAGE, r"^!hearts$", (msg, args) {
        msg.reply("dPhildH");
    });
}

/**
 * the process that deals with the windows calls
 */
extern(Windows)
LRESULT mainWindowCallback(HWND window, UINT message, WPARAM wParam, LPARAM lParam)
{
    LRESULT result = 0;
    static HMENU hMenu;

    POINT point;

    switch (message)
    {
        case WM_CREATE:
        {
            addMenus(window);
            addTabControl(window, hInst);
        } break;
        case WM_CLOSE:
        case WM_DESTROY:
        {
            PostQuitMessage(0);
        } break;
        default:
        {
             result = DefWindowProc(window, message, wParam, lParam);
        }
    }
    return result;
}
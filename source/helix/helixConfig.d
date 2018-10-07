module helix.helixconfig;

import std.stdio;
import std.net.curl;
import core.stdc.time;
import std.datetime;
import std.conv;

public class HelixConfig{

    private static string clientid;
    private static HTTP http;
    private static string jsonData;
    private static time_t timeout = 0;

    public static void setClientId(string cid)
    {
        clientid = cid;
        http = HTTP();
        http.addRequestHeader("Client-Id", clientid);
        http.method = HTTP.Method.get;

        http.onReceive = (ubyte[] data ) {
            jsonData ~= cast(string)data;
            return data.length;
        };
    }

    public static auto getClientId()
    {
        return clientid;
    }

    /**
     * returns the current timeout status
     * True if we need to wait for the timeout to expiore
     */
    public static bool isRateLimited()
    {
        time_t now = Clock.currTime().toUnixTime();

        if (timeout >= now)
        {
            debug(ConsoleSpam)
            {
                if (printTimeout)
                {
                    writeln("ratelimit timeout: " ~ timeout.to!string);
                    writeln("now: " ~ now.to!string);
                    printTimeout = false;
                }
            }
            return false;
        }
        return true;
    }

    public static void setRateLimitTimout(int timeout)
    {
        this.timeout = timeout;
    }

    public static string doRequest(string url)
    {
        jsonData = "";
        http.url = url;
        try{
            http.perform();
        } catch (CurlException e)
        {
            writeln ("api lookup failed");
            writeln(url);
            return null;
        }

        string[string] headers = http.responseHeaders();
        debug(ConsoleSpam)
        {
            writeln(headers);
        }

        if ("ratelimit-remaining" in headers){
            if (headers["ratelimit-remaining"].to!int == 0)
            {
                if ("ratelimit-reset" in headers){
                    setRateLimitTimout(headers["ratelimit-reset"].to!int);
                }
            }
        }
        
        return jsonData;

    }
    
    
}
module helix.getusers;

import core.stdc.time;
import core.thread;
import std.net.curl;
import std.concurrency;
import std.json;
import std.conv;
import std.string;
import std.datetime;
import helix.h_helix;

// debug(ConsoleSpam)
// {
    import std.stdio;
// }

static time_t timeout = 0;

user[] getHostIds(user[] hostsToAction)
{
    time_t now = Clock.currTime().toUnixTime();

    if (hostsToAction.length >= 100)
    {
        writeln("hosts in queue: " ~ hostsToAction.length.to!string);
    }
    if (timeout > now)
    {
        writeln("ratelimit timeout: " ~ timeout.to!string);
        writeln("now: " ~ now.to!string);

        return hostsToAction;
    }

    string request = "https://api.twitch.tv/helix/users?login="~ hostsToAction[0].login ;

    for (int i = 1; i < hostsToAction.length && i <= 100 ; i++)
    {
        request ~= "&login="~ hostsToAction[i].login;
    }

    auto http = HTTP();
    http.url = request;
    http.addRequestHeader("Client-Id", "ved7yonqaz6vopc761g3h2zocb9ej0");
    http.method = HTTP.Method.get;

    string jsonData;

    http.onReceive = (ubyte[] data ) {
        jsonData = cast(string)data;
        return data.length;
    };
    

    try{
        http.perform();
    } catch (CurlException e)
    {
        return hostsToAction;
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
                timeout = headers["ratelimit-reset"].to!int;
            }
        }
    }

    debug(ConsoleSpam)
    {
        writeln(jsonData);
    }
    
    try{

        JSONValue json = parseJSON(jsonData);

        int j = 0;

        for (int i = 0; i < hostsToAction.length && i <= 100; i++)
        {
            if ("id" in json["data"][i])
            {
                int id = to!int(json["data"][i]["id"].str);
                hostsToAction[i].id = id;
            }else 
            {
                hostsToAction[i].id = -1;
            }
        }

        debug(ConsoleSpam)
        {
            writeln(id);
        }
    } catch (JSONException e)
    {
    }

    return hostsToAction;

}

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
import std.stdio;

private static time_t timeout = 0;
private static string clientid;
private static HTTP http;
private static string jsonData;

debug(ConsoleSpam)
{
    static printTimeout = true;
}

public void setClientId(string cid)
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

void getHostIds(ref user[] hostsToAction)
{

    if (clientid == null)
    {
        writeln("You must set the client id using setClientid(string clientid); before making requests");
        return;
    }

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
        return;
    }
    debug(ConsoleSpam)
    {
        printTimeout = true;
    }

    string request = "https://api.twitch.tv/helix/users?login="~ hostsToAction[0].login ;

    for (int i = 1; i < hostsToAction.length && i < 100; i++)
    {
        request ~= "&login="~ hostsToAction[i].login;
    }

    http.url = request;
    
    try{
        http.perform();
    } catch (CurlException e)
    {
        writeln ("api lookup failed");
        writeln(request);
        return;
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
        debug(ConsoleSpam)
        {
            writeln(hostsToAction.length.to!string ~ " users inqueue");
        }
        if ("data" in json)
        {
            debug(ConsoleSpam)
            {
                writeln(json["data"].array.length.to!string ~ " users fetched");
            }

            for (int i = 0; i < hostsToAction.length && i < 100; i++)
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

        } else
        {
            writeln(jsonData);
            writeln(request);
            writeln("unexpected response");

        }
        
    } catch (JSONException e)
    {
        writeln(jsonData);
        writeln("unable to read Json");
    }

    jsonData = "";
    return;

}

module kraken.getuseremotes;

import core.stdc.time;
import std.net.curl;
import std.json;
import std.conv;
import std.stdio;
import std.string;

private static string clientid;
private static string oauth;
static time_t timeout = 0;

public static void setKrakenClientId(string cid)
{
    clientid = cid;
}

public static void setKrakenOauth(string apioauth)
{
    if(oauth.startsWith("oauth:"))
    {
        oauth = apioauth.chompPrefix("oauth:");
    }else{
        oauth = apioauth;
    }
       
}

string[] emotecodes(string userid)
{
    string[] codes;
    string jsonData = "";
    string request = "https://api.twitch.tv/kraken/users/" ~ userid ~ "/emotes";

    auto http = HTTP();
    http.url = request;
    http.addRequestHeader("Accept", "application/vnd.twitchtv.v5+json");
    http.addRequestHeader("Client-Id", clientid);
    http.addRequestHeader("Authorization", "OAuth " ~ oauth);
    http.method = HTTP.Method.get;
    http.onReceive = (ubyte[] data ) {
        jsonData ~= cast(string)data;
        return data.length;
    };
    
    try{
        http.perform();
    } catch (CurlException e)
    {
        writeln ("api lookup failed");
        writeln(request);
        writeln(oauth);
        return null;
    }

    string[string] headers = http.responseHeaders();
    if ("ratelimit-remaining" in headers){
        if (headers["ratelimit-remaining"].to!int == 0)
        {
            if ("ratelimit-reset" in headers){
                timeout = headers["ratelimit-reset"].to!int;
            }
        }
    }

    try{
        JSONValue json = parseJSON(jsonData);

        if ("emoticon_sets" in json)
        {
            foreach(JSONValue emoteset; json["emoticon_sets"].object)
            {
                foreach(JSONValue emote; emoteset.array)
                {
                    if ("code" in emote)
                    {
                        string code= emote["code"].str;
                        codes ~= code;
                    }
                }
            }

        } else
        {
            writeln(jsonData);
            writeln(request);
            writeln(oauth);
            writeln(clientid);
            writeln("unexpected response");
        }
    } catch (JSONException e)
    {
        writeln(jsonData);
        writeln("unable to read Json");
        writeln(e.message);
    }
    return codes;
}

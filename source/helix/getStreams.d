module helix.getstreams;

import core.stdc.time;
import core.thread;

import std.net.curl;
import std.concurrency;
import std.json;
import std.conv;
import std.string;
import std.datetime;
import std.stdio;

import helix.helixconfig;
import helix.returnstructs;
import helix.h_helix;

void getUserId(user u)
{
    user[] userarray;
    userarray ~= u;
    getUserIds(userarray);
    u = userarray[0];
}

StreamInfo[] getUserIds(user[] users)
{

    if (HelixConfig.getClientId() == null)
    {
        writeln("You must set the client id using HelixConfig.setClientid(string clientid); before making requests");
        return null;
    }

    if (HelixConfig.isRateLimited())
    {
        return null;
    }

    string request = "https://api.twitch.tv/streams/users?";
    
    if (users[0].id)
    {
        request ~= "user_id=" ~ users[0].id.to!string;
    } else
    {
        request ~= "user_login=" ~ users[0].login;
    }
    
    for (int i = 1; i < users.length && i < 100; i++)
    {
        if (users[i].id)
        {
            request ~= "user_id=" ~ users[i].id.to!string;
        } else
        {
            request ~= "user_login=" ~ users[i].login;
        }
    }

    string jsonData = HelixConfig.doRequest(request);
    if (jsonData == null)
    {
        return null;
    }

    StreamInfo[] rxedInfo;
    try{
        debug(ConsoleSpam)
        {
            writeln(jsonData);
        }
        JSONValue json = parseJSON(jsonData);

        debug(ConsoleSpam)
        {
            writeln(users.length.to!string ~ " users inqueue");
        }
        if ("data" in json)
        {
            for (int i = 0; i < users.length && i < 100; i++)
            {
                StreamInfo s;
                s.id = to!int(json["data"][i]["id"].str);
                s.userId = to!int(json["data"][i]["user_id"].str);
                s.gameId = to!int(json["data"][i]["game_id"].str);

                //TODO: iterate over community id's
                s.communityIds = [];

                s.type = json["data"][i]["type"].str;
                s.title = json["data"][i]["title"].str;
                s.viewerCount = to!int(json["data"][i]["viewer_count"].str);
                s.startedAt = SysTime.fromISOExtString(json["data"][i]["started_at"].str);
                s.language = json["data"][i]["language"].str;
                s.thumbnailUrl = json["data"][i]["thumbnail_url"].str;
                rxedInfo ~= s;
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
    return rxedInfo;

}

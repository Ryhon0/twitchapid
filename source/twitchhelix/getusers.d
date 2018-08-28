module twitchhelix.getusers;

import core.stdc.time;
import core.thread;
import std.net.curl;
import std.json;
import std.stdio;
import std.conv;
import std.string;
import std.datetime;
import persistance.sqllite;

struct User{
    int id;
    string login;
    string display_name;
    string type;
    string broadcaster_type;
    string description;
    string profile_image_url;
    string offline_image_url;
    int viewcount;
    string email;
}

static time_t timeout = 0;

int getUserId(string username)
{

    time_t now = Clock.currTime().toUnixTime();
    if (timeout > now)
    {
        //sleep untill we can make the next request
        long sleeptime = timeout - now;
        Thread.sleep(dur!"seconds"(sleeptime));
    }

    string request = "https://api.twitch.tv/helix/users?login="~ username;

    auto http = HTTP();
    http.url = request;
    http.addRequestHeader("Client-Id", "ved7yonqaz6vopc761g3h2zocb9ej0");
    http.method = HTTP.Method.get;

    string jsonData;

    http.onReceive = (ubyte[] data ) {

        jsonData = cast(string)data;
        return data.length;
    };
    
    http.perform();

    string[string] headers = http.responseHeaders();

    writeln(headers);

    try {
        if (headers["ratelimit-remaining"].to!int == 0)
        {
            timeout = headers["ratelimit-reset"].to!int;
        }
    } catch (Exception e)
    {
    }

    debug(ConsoleSpam)
    {
        writeln(jsonData);
    }
    JSONValue json = parseJSON(jsonData);

    try{
        int id = to!int(json["data"][0]["id"].str);
        addChannel(username, id);
        debug(ConsoleSpam)
        {
            writeln(id);
        }
        return id;
    } catch (JSONException e)
    {
        return -1;
    }

}
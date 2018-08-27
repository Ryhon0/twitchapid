module twitchhelix.getusers;

import std.net.curl;
import std.json;
import std.stdio;
import std.conv;
import std.string;
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


int getUserId(string username)
{
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
    debug(ConsoleSpam)
    {
        writeln(jsonData);
    }
    JSONValue json = parseJSON(jsonData);

    int id = to!int(json["data"][0]["id"].str);

    addChannel(username, id);

    debug(ConsoleSpam)
    {
        writeln(id);
    }
    return id;
}

int[] getUserId(string[] usernames)
{
    string request = "https://api.twitch.tv/helix/users?login=";

    foreach (string username; usernames)
    {
        request ~= "login=" ~ username ~ "&";
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
    
    http.perform();
    debug(ConsoleSpam)
    {
        writeln(jsonData);
    }
    JSONValue json = parseJSON(jsonData);

    int[] results;
    int i = 0;
    JSONValue users = json["data"];
    foreach(user; users.array)
    {
        int id = to!int(user["id"].str);
        results ~= id;
        addChannel(usernames[i], id);
        i++;
    }

    debug(ConsoleSpam)
    {
        writeln(id);
    }

    return results;
}
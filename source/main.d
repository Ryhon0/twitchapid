module main;

import twitchbot;
import dyaml;

void main()
{
    Node root = Loader("config.yaml").load();

    string username = root["username"].as!string;
    string oauthtoken = root["oauth-token"].as!string;

    string[] channels;

    //Display the data read.
    int i = 0;
    foreach(string channel; root["channels"])
    {
        channels.length = i +1;
        channels[i++] = channel;
    }

    TwitchBot bot = new TwitchBot(username, oauthtoken, channels);
    bot.registercommands();
    bot.run();
}

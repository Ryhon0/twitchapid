module bot;

import core.runtime;
import ircbod.client, ircbod.message;
import std.utf, std.conv;
import dyaml;

static IRCClient bot;
static bool running = false;

string appName = "HarshStorm";

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
        //addTab(channel);
    }

    bot = new IRCClient("irc.chat.twitch.tv", 6667, username, oauth, channels);
    
    bot.connect();

    bot.on(IRCMessage.Type.MESSAGE, r"^!hearts$", (msg, args) {
        msg.reply("fakeLove fairLove sketchTink sketchT snowyLove snowyHug phildeH ladyve2Love gooderHeart gooderLove cherry4Love");
    });

    bot.run();
}


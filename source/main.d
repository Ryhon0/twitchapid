module main;

import ircbod.client, ircbod.message;
import dyaml;

IRCClient bot;

void main(string[] args)
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

    bot = new IRCClient("irc.chat.twitch.tv", 6667, username, oauthtoken, channels);
    bot.connect();
    bot.sendRawMessage("CAP REQ :twitch.tv/membership");
    bot.sendRawMessage("CAP REQ :twitch.tv/tags");
    bot.sendRawMessage("CAP REQ :twitch.tv/commands");
    registercommands();

    while (true)
    {
        bot.readMessage();
    }
}

void registercommands()
{
    bot.on(IRCMessage.Type.MESSAGE, r"^!bnet$", (msg, args) 
    {
        if(msg.channel == "#philderbeast")
        {
            msg.reply("if you want to play with me add me on battle net Philderbeast#6549");
        }
    });

    bot.on(IRCMessage.Type.MESSAGE, r"^!ctt$", (msg, args) 
    {
        if(msg.channel == "#philderbeast")
        {
            msg.reply("If you are enjoying the stream, feel free to click the following link to tweet out the stream and share it with your friends! http://ctt.ec/0aeNa");
        }
    });

    bot.on(IRCMessage.Type.MESSAGE, r"^!bso7$", (msg, args) 
    {
        if(msg.channel == "#philderbeast")
        {
            msg.reply("#BSo7 - The Broadcaster's Salute was conceptualized in Jax_Macky's Twitch Channel April 28,2016 (https://www.twitch.tv/jax_macky). It creates awareness for, and helps promote other broadcasters, and is meant to be a respectful, organized way, to allow other broadcasters the privilege, of advertising their channel, in yours. It is a fantastic Twitch Networking Tool, that also helps you get new followers and viewers");
        }
    });
}
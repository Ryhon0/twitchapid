module main;

import core.runtime;
import ircbod.client, ircbod.message;
import std.utf, std.conv, std.string, std.algorithm, std.stdio;
import dyaml;

static IRCClient bot;
static bool running = false;

void main(string[] args)
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
    foreach (string channel; channels)
    {
        bot.join(channel);
    }
     
    bot.on(IRCMessage.Type.HOSTTARGET, (msg, args) {
        writeln(msg.text);
        writeln("attempting to join " ~ msg.text.split(" ")[0]);
        bot.join( msg.text.split(" ")[0]);

    });

    bot.on(IRCMessage.Type.MESSAGE, r"^!channelcount$", (msg, args) {
            msg.reply("I am in " ~ bot.getChannelCount().to!string ~ " Channels");
    });

    // bot.on(IRCMessage.Type.MESSAGE, r"^!hearts$", (msg, args) {
    //     if( msg.getTagValue("badges").canFind("moderator") || 
    //         msg.getTagValue("badges").canFind("broadcaster") || 
    //         msg.nickname.startsWith("philderbeast") )
    //     {
    //         msg.reply("GenderFluidPride NonBinaryPride IntersexPride PansexualPride AsexualPride TransgenderPride GayPride LesbianPride BisexualPride TwitchUnity fairLove nrcHeart2 sketchT nrcLove sketchTink lewHeart sketchLew lewSketch x47ymcLove nrcGH nrcDH phildeH ladyve2Love djstriLove");
    //     }
    // });

    bot.run();
}



module main;

import core.runtime;
import core.thread;
import ircbod.client, ircbod.message;
import twitchhelix.getusers;
import persistance.sqllite;
import std.utf, std.conv, std.string, std.algorithm, std.stdio;
import dyaml;

static IRCClient bot;
static bool running = false;

void main(string[] args)
{

    setupDb();

    // Read the config.
    Node root = Loader("config.yaml").load();

    string username = root["username"].as!string;
    string oauth = root["oauth-token"].as!string;

    string[] channels;
    foreach(string channel; root["channels"])
    {
        channels ~= channel;
    }

    bot = new IRCClient("irc.chat.twitch.tv", 6667, username, oauth, channels);

    bot.connect();
    channels ~= getChannels();
    foreach (string channel; channels)
    {
        bot.join(channel);
        // Thread.sleep(dur!("msecs")(10));
    }
    
    // bot.on(IRCMessage.Type.HOSTTARGET, (msg, args) {
    //     string target = msg.text.split(" ")[0].chompPrefix("#");
    //     string channel = msg.channel.chompPrefix("#");

    //     int tid = findID(target);
    //     int cid = findID(channel);

    //     addHost(cid, tid);

    //     bot.join(target);

    // });

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

int findID(string channel) {
    int id = checkForChannel(channel);
    if (id > 0)
    {
        return id;
    } else
    {
        return getUserId(channel);
    }
}

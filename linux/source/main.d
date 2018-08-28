module main;

import core.runtime;
import core.thread;
import ircbod.client, ircbod.message;
import twitchhelix.getusers, twitchhelix.h_helix;
import persistance.sqllite;
import std.utf, std.conv, std.string, std.algorithm, std.stdio;
import dyaml;

static IRCClient bot;
static bool running = false;

void main(string[] args)
{
    user[] hosts;
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
    }
    
    bot.on(IRCMessage.Type.HOSTTARGET, (msg, args) {
        try{
            string target = msg.text.split(" ")[0].chompPrefix("#");
            string channel = msg.channel.chompPrefix("#");
            user host = {};
            host.login = target;
            hosts ~= host;
            actionHosts(hosts);
        }catch (Exception e)
        {}
        
    });

    bot.on(IRCMessage.Type.MESSAGE, r"^!channelcount$", (msg, args) {
            msg.reply("I am in " ~ bot.getChannelCount().to!string ~ " Channels");
    });

    // bot.on(IRCMessage.Type.MESSAGE, r"^!hearts$", (msg, args) {
    //     if( msg.getTagValue("badges").canFind("moderator") || 
    //         msg.getTagValue("badges").canFind("broadcaster") || 
    //         msg.nickname.startsWith("philderbeast") )
    //     {
    //         loveSpam(msg);
    //     }
    // });

    // bot.on(IRCMessage.Type.MESSAGE, r"^!ladyve2love ladyve2love ladyve2love ladyve2love ladyve2love ladyve2love.*$", (msg, args) {
    //     if( msg.getTagValue("badges").canFind("moderator") || 
    //         msg.getTagValue("badges").canFind("broadcaster") || 
    //         msg.nickname.startsWith("ladyvertical") )
    //     {
    //         loveSpam(msg);
    //     }
    // });

    bot.run();
}

void loveSpam(IRCMessage msg)
{
    Thread.sleep(dur!"msecs"(1000));
    msg.reply("skiwiLove rocksLOVE ricketLove bldfLOVE ladyve2Love happycLove nrcGH nrcDH learnt1Heart tovgLove vandyLove djstriLove nrcHeart2 sketchTink lewSketch sketchLew autmLove techLove nettyHeart minmoLOVE sutoLove bittieLove gandsLessthanthree gandsGameEngine gandsTWC aaronLOVE ktrHug bggLove fairLove matxHeart lillexiLove lewHeart phildeH oroLove ogaHeart ariaHeart tokyLuv vixenLOVE");
}

void actionHosts(user[] hosts)
{
    if(!hosts.empty)
    {
    hosts = getHostIds(hosts[]);
    }

    //remove hosts that were found    
    bool running = true;
    while (running && !hosts.empty)
    {
        if (hosts[0].id != 0 )
        {
            if (hosts[0].id != -1 )
            {
                bot.join(hosts[0].login);
            }
            hosts = hosts.remove(0);
        } else
        {
            running = false;
        }
    }
       
}

// int findID(string channel) {
//     int id = checkForChannel(channel);
//     if (id > 0)
//     {
//         return id;
//     } else
//     {
//         //TODO: this needs to be fixed
//         return -1;//getUserId(channel);
//     }
// }

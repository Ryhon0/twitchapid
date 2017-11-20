module twitchbot;

import std.stdio;
import ircbod.client, ircbod.message;

class TwitchBot
{

private:
    IRCClient bot;

public:
    this(string username, string oauth, string[] channels)
    {
        bot = new IRCClient("irc.chat.twitch.tv", 6667, username, oauth, channels);
        bot.connect();
        bot.sendRawMessage("CAP REQ :twitch.tv/membership");
        bot.sendRawMessage("CAP REQ :twitch.tv/tags");
        bot.sendRawMessage("CAP REQ :twitch.tv/commands");
    }

    void run()
    {
        bot.run();
    }

    void registercommands()
    {
        bot.on(IRCMessage.Type.MESSAGE, r"^hello (\S+)$", (msg, args) 
        {
            msg.reply("Hello to you, too " ~ msg.nickname);
        });
    }

}

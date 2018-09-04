module irc.message;

import std.datetime, std.string;
import irc.client;

struct IRCMessage
{
    enum Type {
        PRIVMSG,
        JOIN,
        PART,
        QUIT,
        HOSTTARGET,
        NOTICE,
        OTHER
    }

    Type        type;
    string      tags;
    string      text;
    string      nickname;
    string      channel;
    DateTime    time;
    IRCClient   client;
    string      rawMessage;

    /**
     * builds a message from a raw string
     */
    this(string rawMessage, IRCClient client)
    {
        this.client = client;
        this.rawMessage = rawMessage;
        //check for tags and split them out;
        if (rawMessage.startsWith("@"))
        {
            this.tags = rawMessage.split(" ")[0].chompPrefix("@").strip();
            rawMessage = rawMessage[tags.length + 1 .. $].strip();
        } else
        {
            tags = "";
        }

        this.nickname = rawMessage.split(" ")[0].split("!")[0].chompPrefix(":");
        rawMessage = rawMessage[(rawMessage.split(" ")[0].length) .. $].strip();

        string typestring = rawMessage.split(" ")[0].strip();
        switch (typestring)
        {
            case "PRIVMSG":
                type = Type.PRIVMSG;
                break;
            case "JOIN":
                type = Type.JOIN;
                break;
            case "PART":
                type = Type.PART;
                break;
            case "QUIT":
                type = Type.QUIT;
                break;
            case "HOSTTARGET":
                type = Type.HOSTTARGET;
                break;
            case "NOTICE":
                type = Type.NOTICE;
                break;
            default:
                type = Type.OTHER;
                break;
        }
            
        rawMessage = rawMessage[(typestring.length) .. $].strip();

        this.channel = rawMessage.split(" ")[0].strip();
        rawMessage = rawMessage[(channel.length) .. $].strip();
        text = rawMessage.chompPrefix(":").strip();
        this.time = cast(DateTime) Clock.currTime();
    }

    string getTagValue(string tagName)
    {
        string[string] tagValues;
        auto tagpairs = tags.split(";");
        foreach (string tag; tagpairs)
        {
            auto tagnamevalue = tag.split("=");
            tagValues[tagnamevalue[0]] = tagnamevalue[1];
        }

        if (tagName in tagValues)
        {
            return tagValues[tagName];
        } else
        return "";

    }

    void reply(string message)
    {
        client.sendMessageToChannel(message, channel);
    }
}
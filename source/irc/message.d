module irc.message;

import std.datetime, std.string;
import irc.client;

struct IRCMessage
{
    enum Type {
        PRIVMSG,            // default irc types
        JOIN,               // default irc types
        PART,               // default irc types
        QUIT,               // default irc types
        HOSTTARGET,         // default irc types
        NOTICE,             // default irc types
        RECONNECT,          // default irc types
        CLEARCHAT,         // twitch message type
        CLEARMSG,           // twitch message type
        GLOABLUSERSTATE,    // twitch message type
        ROOMSTATE,          // twitch message type
        USERNOTICE,         // twitch message type
        USERSTATE,          // twitch message type
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
            case "RECONNECT":
                type = Type.RECONNECT;
                break;
            case "CLEARCHAT":
                type= Type.CLEARCHAT;
                break;
            case "CLEARMSG":
                type= Type.CLEARMSG;
                break;
            case "GLOABLUSERSTATE":
                type= Type.GLOABLUSERSTATE;
                break;
            case "ROOMSTATE":
                type= Type.ROOMSTATE;
                break;
            case "USERNOTICE":
                type= Type.USERNOTICE;
                break;
            case "USERSTATE":
                type= Type.USERSTATE;
                break;
            default:
                type = Type.OTHER;
                break;
        }

        if (type != Type.RECONNECT || Type.OTHER)
        {
            rawMessage = rawMessage[(typestring.length) .. $].strip();
            this.channel = rawMessage.split(" ")[0].strip();
            rawMessage = rawMessage[(channel.length) .. $].strip();
            text = rawMessage.chompPrefix(":").strip();
        }
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

    /**
     *  sends a reply to a specific message
     */
    void reply(string message)
    {
        client.sendMessageToChannel(message, channel);
    }
}

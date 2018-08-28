module irc.message;

import std.datetime, std.string;
import irc.client;

struct IRCMessage
{
    enum Type {
        MESSAGE,      // includes CHAN_MESSAGE & PIV_MESSAGE
        CHAN_MESSAGE,
        PRIV_MESSAGE,
        JOIN,
        PART,
        QUIT,
        HOSTTARGET
    }

    Type        type;
    string      tags;
    string      text;
    string      nickname;
    string      channel;
    DateTime    time;
    IRCClient   client;

    string getTagValue(string tagName)
    {
        string[string] tagValues;
        auto tagpairs = tags.split(";");
        foreach (string tag; tagpairs)
        {
            auto tagnamevalue = tag.split("=");
            tagValues[tagnamevalue[0]] = tagnamevalue[1];
        }

        return tagValues[tagName];
    }

    void reply(string message)
    {
        if(type == Type.PRIV_MESSAGE) {
            client.sendMessageToUser(message, nickname);
        } else {
            client.sendMessageToChannel(message, channel);
        }
    }
}
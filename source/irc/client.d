module irc.client;

import irc.socket, irc.message;
import std.regex, std.container, std.datetime, std.conv, std.string, std.algorithm, std.array;
debug(console) {
    import std.stdio;
}

alias MessageHandler = void delegate(IRCMessage message);
alias MessageHandlerWithArgs = void delegate(IRCMessage message, string[] args);

class IRCClient
{
private:
    struct PatternMessageHandler {
        MessageHandler          callback;
        MessageHandlerWithArgs  callbackWithArgs;
        Regex!char              pattern;
    }

    alias HandlerList = DList!PatternMessageHandler;

    IRCSocket                    sock;
    string                       nickname;
    string                       password;
    string[]                     channels;
    HandlerList[IRCMessage.Type] handlers;
    bool                         running;

    static MATCHHOSTTARGET = ctRegex!r"^:(\S+) HOSTTARGET (\S+) :(.*)$";
    static MATCHPRIV       = ctRegex!r"^@(\S+) :(\S+)\!\S+ PRIVMSG (\S+) :(.*)$";
    static MATCHCONN       = ctRegex!r"^:(\S+)\!\S+ (JOIN|PART|QUIT) :?(\S+).*";
    static MATCHPING       = ctRegex!r"^PING (.+)$";
    static MATCHALL        = ctRegex!r".*";

public:

    this(string server, ushort port, string nickname, string password = null)
    {
        this.sock     = new IRCSocket(server.dup, port);
        this.nickname = nickname;
        this.password = password;
        this.running  = true;
    }

    string name() {
        return this.nickname;
    }

    void connect()
    {
        this.sock.connect();

        if (!this.sock.connected()) {
            throw new Exception("Could not connect to irc server!");
        }

        if (this.password) {
            this.sock.pass(this.password);
        }

        this.sock.nick(this.nickname);
        this.sock.user(this.nickname, 0, "*", "ircbod");

        this.sock.capreq("twitch.tv/tags");
        this.sock.capreq("twitch.tv/commands");

    }

    void join(string channel)
    {
        if(!channel.startsWith("#"))
            channel = "#"~channel;

        if(this.channels.find(channel).empty())
        {
            this.sock.join(channel);
            this.channels.length++;
            this.channels[$-1] = channel;
        }
    }

    bool connected()
    {
        return this.sock.connected();
    }

    void disconnect()
    {
        this.sock.disconnect();
    }

    void reconnect()
    {
        disconnect();
        connect();
    }

    void on(IRCMessage.Type type, MessageHandler callback)
    {
        on(type, MATCHALL, callback);
    }

    void on(IRCMessage.Type type, MessageHandlerWithArgs callback)
    {
        on(type, MATCHALL, callback);
    }

    void on(IRCMessage.Type type, string pattern, MessageHandler callback)
    {
        on(type, regex(pattern), callback);
    }

    void on(IRCMessage.Type type, string pattern, MessageHandlerWithArgs callback)
    {
        on(type, regex(pattern), callback);
    }

    void on(IRCMessage.Type type, Regex!char regex, MessageHandler callback)
    {
        if(type == IRCMessage.Type.MESSAGE) {
            on(IRCMessage.Type.CHAN_MESSAGE, regex, callback);
            on(IRCMessage.Type.PRIV_MESSAGE, regex, callback);
            return;
        }

        PatternMessageHandler handler = { callback, null, regex };
        if(type !in this.handlers) {
            this.handlers[type] = HandlerList([handler]);
        } else {
            this.handlers[type].insertBack(handler);
        }
    }

    void on(IRCMessage.Type type, Regex!char regex, MessageHandlerWithArgs callback)
    {
        if(type == IRCMessage.Type.MESSAGE) {
            on(IRCMessage.Type.CHAN_MESSAGE, regex, callback);
            on(IRCMessage.Type.PRIV_MESSAGE, regex, callback);
            return;
        }

        PatternMessageHandler handler = { null, callback, regex };
        if(type !in this.handlers) {
            this.handlers[type] = HandlerList([handler]);
        } else {
            this.handlers[type].insertBack(handler);
        }
    }

    void run()
    {
        if(!connected())
            connect();

        scope(exit) disconnect();

        while (running)
        {
            readLine();
        }
        
    }

    void readLine()
    {
        string line = this.sock.readln();
        debug(ConsoleSpam)
        {
            writeln("<< " ~ line);
        }
        processLine(line);
    }

    bool isRunning()
    {
        return this.running;
    }

    void quit()
    {
        this.running = false;
    }

    void sendMessageToChannel(string message, string channel)
    {
        this.sock.privmsg(channel, message);
    }

    void sendMessageToUser(string message, string nickname)
    {
        this.sock.privmsg(nickname, message);
    }

    void broadcast(string message)
    {
        foreach(c; this.channels) {
            sendMessageToChannel(message, c);
        }
    }

    bool inChannel(string c) 
    {
        return this.channels.find(c).empty;
    }

    ulong getChannelCount()
    {
        return this.channels.length;
    }

private:

    static struct TypeForString
    {
    private:

        /*
            rendered on 2017-Nov-08 15:10:44.5612847 by IsItThere.
             - PRNG seed: 7931
             - map length: 8
             - case sensitive: true
        */

        static const string[8] _words = ["PART", "", "", "", "", "QUIT", "JOIN", ""];

        static const IRCMessage.Type[8] _filled = [IRCMessage.Type.PART, IRCMessage.Type.MESSAGE, IRCMessage.Type.MESSAGE, IRCMessage.Type.MESSAGE, IRCMessage.Type.MESSAGE, IRCMessage.Type.QUIT, IRCMessage.Type.JOIN, IRCMessage.Type.MESSAGE];

        static const ubyte[256] _coefficients = [230, 3, 191, 24, 104, 192, 64, 157, 218, 34, 173, 68, 216, 208, 167, 199, 0, 151, 122, 27, 169, 124, 64, 6, 96, 101, 183, 149, 228, 174, 221, 9, 193, 56, 159, 78, 163, 47, 26, 20, 117, 200, 46, 227, 66, 240, 128, 254, 95, 136, 20, 116, 36, 46, 24, 88, 34, 76, 97, 91, 187, 94, 206, 176, 74, 143, 225, 14, 57, 20, 157, 29, 49, 92, 189, 65, 135, 3, 148, 145, 118, 34, 72, 138, 75, 92, 140, 41, 131, 212, 2, 144, 109, 100, 140, 2, 249, 120, 175, 144, 224, 95, 66, 106, 184, 32, 47, 110, 89, 19, 85, 131, 84, 254, 118, 244, 167, 44, 45, 108, 141, 89, 41, 157, 247, 253, 138, 153, 174, 108, 21, 158, 9, 253, 47, 182, 95, 66, 204, 200, 205, 203, 241, 21, 38, 90, 239, 48, 218, 253, 48, 34, 195, 83, 167, 239, 157, 97, 164, 77, 43, 200, 201, 18, 154, 253, 228, 164, 53, 86, 228, 138, 14, 200, 192, 0, 53, 57, 164, 107, 163, 41, 176, 32, 62, 78, 56, 220, 209, 228, 158, 30, 208, 89, 197, 24, 186, 210, 11, 143, 71, 246, 178, 157, 133, 127, 200, 102, 114, 220, 232, 46, 104, 236, 240, 24, 122, 243, 75, 157, 47, 212, 47, 223, 212, 7, 100, 100, 243, 63, 199, 236, 107, 136, 218, 174, 93, 136, 25, 17, 100, 233, 94, 144, 90, 51, 116, 51, 232, 208, 254, 173, 207, 209, 49, 70];

        static ushort hash(const char[] word) nothrow pure @safe @nogc
        {
            ushort result;
            foreach(i; 0..word.length)
            {
                result += _coefficients[word[i]];
            }
            return result % 8;
        }

    public:

        static IRCMessage.Type opCall(const(char)[] word)
        {
            IRCMessage.Type result;
            const ushort h = hash(word);
            if (_filled[h])
                result = _filled[h];
            return result;
        }
    }

    alias typeForString = TypeForString;

    void processLine(string message)
    {
        try 
        {
            //we cant garentee what the server sends so silently ignore errors

            if (auto matcher = matchFirst(message, MATCHCONN)) {
                const user    = matcher.captures[1];
                const typeStr = matcher.captures[2];
                const channel = matcher.captures[3];
                const time    = to!DateTime(Clock.currTime());
                const type    = typeForString(typeStr);
                IRCMessage ircMessage = {
                    type,
                    "",
                    typeStr,
                    user,
                    channel,
                    time,
                    this
                };
                handleMessage(ircMessage);
            }
            else if (auto matcher = matchFirst(message, MATCHPRIV)) {
                auto tags    = matcher.captures[1];
                auto user    = matcher.captures[2];
                auto channel = matcher.captures[3];
                auto text    = matcher.captures[4];
                auto time    = to!DateTime(Clock.currTime());
                auto type    = channel[0] == '#' ? IRCMessage.Type.CHAN_MESSAGE : IRCMessage.Type.PRIV_MESSAGE;
                IRCMessage ircMessage = {
                    type,
                    tags,
                    text,
                    user,
                    channel,
                    time,
                    this
                };

                handleMessage(ircMessage);
            }
            else if (auto matcher = matchFirst(message, MATCHHOSTTARGET)) {
                auto user    = matcher.captures[1];
                auto channel = matcher.captures[2];
                auto text    = matcher.captures[3];
                auto time    = to!DateTime(Clock.currTime());
                auto type    = IRCMessage.Type.HOSTTARGET;

                if (text.empty)
                {
                    writeln("empty text match" ~ message);
                    return;
                }

                IRCMessage ircMessage = {
                    type,
                    "",
                    text,
                    user,
                    channel,
                    time,
                    this
                };

                handleMessage(ircMessage);
            }
            else if (auto matcher = matchFirst(message, MATCHPING)) {
                auto server = matcher.captures[1];
                this.sock.pong(server);
            }

        } catch (Exception e)
        {
            //silently ignore the error
            writeln("Error in line: " ~ message);
        }
    }

    void handleMessage(IRCMessage message)
    {
        if(message.type in this.handlers) {
            foreach(PatternMessageHandler h; this.handlers[message.type]) {
                if(auto matcher = matchFirst(message.text, h.pattern)) {
                    string[] args;
                    foreach(string m; matcher.captures) {
                        args ~= m;
                    }
                    if(h.callback)
                        h.callback(message);
                    if(h.callbackWithArgs)
                        h.callbackWithArgs(message, args[1..$]);
                }
            }
        }
    }
}

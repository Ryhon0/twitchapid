module irc.client;

import irc.socket, irc.message;
import std.regex, std.container, std.datetime, std.conv, std.string, std.algorithm, std.array, std.stdio;


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
    char[]                       line;

public:

    this(string server, ushort port, string nickname, string password = null)
    {
        this.sock     = new IRCSocket(server.dup, port);
        this.nickname = nickname;
        this.password = password;
        this.running  = true;

        this.on(IRCMessage.Type.JOIN, (msg)
        {
            channels ~= msg.channel.chompPrefix("#").chomp().to!string;
        });
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
        }
    }

    bool connected()
    {
        this.running = true;
        return this.sock.connected();
    }

    void disconnect()
    {
        this.running = false;
        this.sock.disconnect();
    }

    void reconnect()
    {
        disconnect();
        connect();
    }

    void on(IRCMessage.Type type, MessageHandler callback)
    {
        on(type, r".*", callback);
    }

    void on(IRCMessage.Type type, MessageHandlerWithArgs callback)
    {
        on(type, r".*", callback);
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
        PatternMessageHandler handler = { callback, null, regex };
        if(type !in this.handlers) {
            this.handlers[type] = HandlerList([handler]);
        } else {
            this.handlers[type].insertBack(handler);
        }
    }

    void on(IRCMessage.Type type, Regex!char regex, MessageHandlerWithArgs callback)
    {
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
            if (!this.sock.connected()) {
                reconnect();
            }
            readLine();
        }
    }

    void readLine()
    {
        line = this.sock.readln();
        debug(ConsoleSpam)
        {
            writeln("<< " ~ line);
        }
        processLine();
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

    bool inChannel(string channel) 
    {
        if(!channel.startsWith("#"))
            channel = "#"~channel;
            
        return !(this.channels.find(channel).empty);
    }

    ulong getChannelCount()
    {
        return this.channels.length;
    }

private:
    void processLine()
    {
        if (line.split(" ")[0] == "PING")
        {
            this.sock.pong(line.split(" ")[1]);
        } else
        {
            IRCMessage message = IRCMessage(line.to!string, this);
            if(message.type in this.handlers) {
                foreach(PatternMessageHandler h; this.handlers[message.type]) {
                    if(auto matcher = matchFirst(message.text, h.pattern)) {
                        string[] args;
                        foreach(string m; matcher.captures) {
                            args ~= m.to!string;
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
}

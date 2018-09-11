module irc.socket;

import std.socket, std.conv, std.string, std.algorithm, std.array;
import std.stdio : writeln;

class IRCSocket
{
private:

    char[]         host;
    ushort         port;
    TcpSocket      sock;
    char[]         rxbuffer;

    private void write(string message)
    {
        debug(ConsoleSpam)
        {
            writeln(">> " , message);
        }
        sock.send(message ~ "\r\n");
    }

    private void writeOptional(string command, string[] optional = [])
    {
        if(optional.length > 0) {
            command ~= " " ~ optional.join(" ");
        }
        
        write(command.strip());
    }

public:

    this(char[] host, ushort port = 6667)
    {
        this.host = host;
        this.port = port;
        this.sock = null;
    }

    bool connected() {
        return this.sock !is null;
    }

    bool connect()
    {
        this.sock = new TcpSocket();
        assert(this.sock.isAlive);
        this.sock.connect(new InternetAddress(this.host, this.port));

        return true;
    }

    bool disconnect()
    {
        if (connected()) {
            this.sock.close();
            this.sock = null;
            return true;
        }
        return false;
    }

    void close()
    {
        disconnect();
    }

    bool reconnect()
    {
        disconnect();
        return connect();
    }

    char[] read()
    {
        char[] buf = new char[](4096);

        auto datLength = this.sock.receive(buf[]);
        if (datLength == Socket.ERROR || datLength == 0)
        {
            // writeln("Connection error. reconnecting");
            // reconnect();
            return null;
        } else
        if (datLength > 0)
        {
            char[] line = buf[0 .. datLength];
            return line;
        }
        return null;
    }

    char[] readln()
    {
        char[] line;

        if (!rxbuffer.empty)
        {
            auto lines = splitLines(rxbuffer);

            if (lines.length > 1)
            {
                line = lines[0];
                //RFC1493 lines will always end with CR/LF
                rxbuffer = rxbuffer[line.length+2 .. $];
            } else if(endsWith(rxbuffer, "\r\n"))
            {
                line = rxbuffer.chomp();
                rxbuffer = null;
            } else 
            {
                rxbuffer ~= read();
                return readln();
            }
            return line;
        } else
        {
            rxbuffer ~= read();
            return readln();
        }
    }

    void raw(string[] args)
    {
        auto last = args[$ - 1];
        if (last) {
            args[$ - 1] = ":" ~ last;
        }
        write(args.join(" "));
    }

    void pass(string password)
    {
        write("PASS " ~ password);
    }

    void nick(string nickname)
    {
        write("NICK " ~ nickname);
    }

    void user(string username, uint mode, string unused, string realname)
    {
        write("USER " ~ [username, to!string(mode), unused, ":" ~ realname].join(" "));
    }

    void oper(string name, string password)
    {
        write("OPER " ~ name ~ " " ~ password);
    }

    void mode(string channel, string[] modes)
    {
        write("MODE " ~ channel ~ " " ~ modes.join(" "));
    }

    void quit(string message = null)
    {
        raw(["QUIT", message]);
    }

    void join(string channel, string password = "")
    {
        if(!channel.startsWith("#"))
            channel = "#"~channel;

        writeOptional("JOIN " ~ channel, [password]);
    }

    void part(string channel, string message = "")
    {
        raw(["PART", channel, message]);
    }

    void capreq(string cap)
    {
        raw(["CAP", "REQ", cap]);
    }

    void topic(string channel, string topic = "")
    {
        raw(["TOPIC", channel, topic]);
    }

    void names(string[] channels)
    {
        if(channels.length > 0)
            write("NAMES " ~ channels.join(","));
        else
            write("NAMES");
    }

    void list(string[] channels)
    {
        if(channels.length > 0)
            write("LIST " ~ channels.join(","));
        else
            write("LIST");
    }

    void invite(string nickname, string channel)
    {
        write("INVITE " ~ nickname ~ " " ~ channel);
    }

    void kick(string channel, string nickname, string comment = null)
    {
        raw(["KICK", channel, nickname, comment]);
    }

    void privmsg(string target, string message)
    {
        write("PRIVMSG " ~ target ~ " :" ~ message);
    }

    void notice(string target, string message)
    {
        write("NOTICE " ~ target ~ " :" ~ message);
    }

    void motd(string target = null)
    {
        writeOptional("MOTD", [target]);
    }

    void stats(string[] params)
    {
        writeOptional("STATS", params);
    }

    void time(string target = null)
    {
        writeOptional("TIME", [target]);
    }

    void info(string target = null)
    {
        writeOptional("INFO", [target]);
    }

    void squery(string target, string message)
    {
        write("SQUERY " ~ target ~ " :" ~ message);
    }

    void who(string[] params)
    {
        writeOptional("WHO", params);
    }

    void whois(string[] params)
    {
        writeOptional("WHOIS", params);
    }

    void whowas(string[] params)
    {
        writeOptional("WHOWAS", params);
    }

    void kill(string user, string message)
    {
        write("KILL " ~ user ~ " :" ~ message);
    }

    void ping(string server)
    {
        write("PING " ~ server);
    }

    void pong(char[] server)
    {
        write("PONG " ~ server.to!string);
    }

    void away(string message = null)
    {
        raw(["AWAY", message]);
    }

    void users(string target = null)
    {
        writeOptional("USERS", [target]);
    }

    void userhost(string[] users)
    {
        write("USERHOST" ~ users.join(" "));
    }
}

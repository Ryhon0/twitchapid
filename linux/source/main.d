module main;

import std.stdio;
import ircbod.client, ircbod.message;
import bot;

void main(string[] args){

    IRCClient bot = startbot();
    //
    //bot.on(IRCMessage.Type.MESSAGE, ".", (msg, args)
    //{
    //    writefln(msg.text);
    //});

    // run message loop
    running = true;
    while (running)
    {
        writefln("monitoring chat");
        bot.readLine();
    }
}

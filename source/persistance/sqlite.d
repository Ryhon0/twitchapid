module persistance.sqlite;

// Note: exception handling is left aside for clarity.
import d2sqlite3;
import std.typecons : Nullable;

private Database db;

void setupDb()
{
    // Open a databaseon disk
    db = Database("spider.sqlite");

    db.run("CREATE TABLE IF NOT EXISTS channels (channel_id INTEGER PRIMARY KEY, channel_name TEXT NOT NULL)");
    db.run("CREATE TABLE IF NOT EXISTS hosts (hoster_id INTEGER, hosted_id INTEGER, times INTEGER DEFAULT 1, PRIMARY KEY (hoster_id, hosted_id))");
}

void addHost(int hoster, int hosted) {
    auto result = db.execute("SELECT * FROM hosts WHERE hosted_id = '" ~ to!string(hosted) ~ "' AND hoster_id = '" ~ to!string(hoster) ~ "'");

    if (result.empty)
    {
        db.run("UPDATE hosts SET times = times + 1 WHERE hosted_id = '" ~ to!string(hosted) ~ "' AND hoster_id = '" ~ to!string(hoster) ~ "'");
    }else 
    {
        db.run("INSERT OR IGNORE INTO hosts (hoster_id, hosted_id, times) VALUES ('" ~ to!string(hoster) ~ "', '" ~ to!string(hosted) ~ "', 1)");
    }
}

void addChannel(string channel,  int id) {
    auto result = db.execute("SELECT channel_id FROM channels WHERE channel_id = " ~ to!string(id));

    if (!result.empty)
    {
        db.run("UPDATE channels SET channel_name = '${channel}' WHERE channel_id = " ~ to!string(id));
    }
    else
    {
        db.run("INSERT OR IGNORE INTO channels (channel_id, channel_name) VALUES (" ~ to!string(id) ~ ",'" ~ channel ~ "')");
    }
}

string[] getChannels() {
    auto result = db.execute("SELECT channel_name FROM channels");
    string[] channels;
    foreach (Row row; result)
    {
        channels ~= row.opIndex(0).as!string;
    }
    return channels;
}

int checkForChannel(string channel) {
    auto result = db.execute("SELECT channel_id FROM channels WHERE channel_name = '" ~ channel ~ "'");
    if(!result.empty)
    {
        Row r = result.front();
        int id = r.opIndex(0).as!int;
        return id;
    }else
    {
        return -1;
    }

}


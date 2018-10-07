module helix.returnstructs;

import std.uuid;
import std.datetime.systime;

struct StreamInfo
{
    int id;
    int userId;
    int gameId;
    UUID[] communityIds;
    string type;
    string title;
    int viewerCount;
    SysTime startedAt;
    string language;
    string thumbnailUrl;
}

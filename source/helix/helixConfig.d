module helix.getusers;


public class HelixConfig{

    private static string clientid;
    private static HTTP http;
    private static string jsonData;

    public static void setClientId(string cid)
    {
        clientid = cid;
        http = HTTP();
        http.addRequestHeader("Client-Id", clientid);
        http.method = HTTP.Method.get;

        http.onReceive = (ubyte[] data ) {
            jsonData ~= cast(string)data;
            return data.length;
        };
    }

    public static auto getClientId()
    {
        return clientid;
    }
    
}
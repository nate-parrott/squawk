package us.squawkwith.android;

import com.loopj.android.http.JsonHttpResponseHandler;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Date;

/**
 * Created by nateparrott on 6/30/14.
 */
public class Message {
    public Message(JSONObject json) {
        try {
            sender = json.getString("sender");
            id = json.getString("_id");
            long timestamp = json.getLong("date");
            date = new Date(timestamp * 1000);
            listened = json.getBoolean("listened");
        } catch (JSONException e) {
            throw new RuntimeException();
        }
    }

    public String sender, id;
    public Date date;
    public boolean listened;

    public void markListened() {
        listened = true;
        try {
            JSONObject args = new JSONObject();
            args.put("id", id);
            Squawk.post("/squawks/listened", args, new byte[]{}, "application/octet-strea", new JsonHttpResponseHandler() {

            });
        } catch (JSONException e) {
            throw new RuntimeException();
        }
    }

    public String getFilenameForCache() {
        return id + ".m4a";
    }
}

package com.parrott.squawk.squawk;

import android.content.SharedPreferences;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.*;
import java.net.*;

/**
 * Created by Will on 3/24/2014.
 */
public class SquawkMain {
    final static String DEBUG = "Comments";
    /**
     * Make a get request to the Squawk server
     * @param urlString, the url extension (ie: "squawks/recent")
     * @param args the json you want to pass in the request
     */
    public static JSONObject getJSON(String urlString, JSONObject args) throws IOException {
        URL url = new URL("http://api.squawkwith.us" + urlString + "?args=" + URLEncoder.encode(args.toString(), "UTF-8"));
        Log.d(DEBUG, url.getPath());
        HttpURLConnection verify = (HttpURLConnection) url.openConnection();
        JSONObject responseJSON = null;
        try {
            BufferedReader inputReader = new BufferedReader(new InputStreamReader(verify.getInputStream()));
            StringBuilder sb = new StringBuilder();
            String line = inputReader.readLine();
            /*while (line != null) {
                sb.append(line + "\n");
                Log.d("Comments", "The current sb is: " + sb.toString());
            }*/
            responseJSON = new JSONObject(line);
        } catch (JSONException e) {
            Log.d("login", "json error: " + e);
        } finally {
            verify.disconnect();
        }

        if (responseJSON == null) {
            Log.d(DEBUG, "GET failed");
            return null;
        } else {
            Log.d(DEBUG, "GET success: " + responseJSON.toString());
            return responseJSON;
        }

    }
}

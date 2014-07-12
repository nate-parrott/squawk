package us.squawkwith.android;

import android.content.Context;
import android.content.SharedPreferences;
import com.loopj.android.http.*;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.entity.ByteArrayEntity;
import org.apache.http.entity.FileEntity;
import org.apache.http.entity.StringEntity;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;

/**
 * Created by nateparrott on 6/29/14.
 */

public class Squawk {
    public static String TAG = "Squawk"; // for logging

    public static String kLoginTokenSettingsKey = "LoginToken";
    public static String kUserPhoneSettingsKey = "PhoneNumber";
    public static String kApiRoot = "http://api.squawkwith.us";

    private static AsyncHttpClient client = new AsyncHttpClient();
    public static AsyncHttpClient getClient() {return client;}

    public static SharedPreferences preferences() {
        return SquawkApp.getAppContext().getSharedPreferences("Squawk", Context.MODE_PRIVATE);
    }

    public static String loginToken() {
        return preferences().getString(kLoginTokenSettingsKey, null);
    }

    public static String phone() {
        return preferences().getString(kUserPhoneSettingsKey, null);
    }

    public static String makeUrl(String endpoint, JSONObject args) {
        try {
            if (args == null) {
                args = new JSONObject();
            }
            if (loginToken() != null) {
                args.put("token", loginToken());
            }
            String url = kApiRoot + endpoint + "?args=" + URLEncoder.encode(args.toString(), "utf-8");
            return url;
        } catch (JSONException e) {
            throw new RuntimeException();
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException();
        }
    }

    public static void get(String endpoint, JSONObject args, JsonHttpResponseHandler handler) {
        try {
            if (args == null) {
                args = new JSONObject();
            }
            if (loginToken() != null) {
                args.put("token", loginToken());
            }
            RequestParams params = new RequestParams();
            params.put("args", args.toString());
            client.get(kApiRoot + endpoint, params, handler);
        } catch (JSONException e) {
            throw new RuntimeException("Invalid JSON");
        }
    }

    public static void post(String endpoint, JSONObject args, byte[] data, String contentType, JsonHttpResponseHandler handler) {
        try {
            String url = makeUrl(endpoint, args);
            ByteArrayEntity entity = new ByteArrayEntity(data);
            Context ctx = SquawkApp.getAppContext();
            client.post(ctx, url, entity, contentType, handler);
        } catch (Exception e) {
            // fuck checked exceptions
            throw new RuntimeException("");
        }
    }

    public static void uploadMedia(String endpoint, JSONObject args, String filePath, String contentType, AsyncHttpResponseHandler handler) {
        File f = new File(filePath);
        try {
            String url = makeUrl(endpoint, args);
            FileEntity entity = new FileEntity(f, contentType);

            Context ctx = SquawkApp.getAppContext();
            client.post(ctx, url, entity, contentType, handler);
        } catch (Exception e) {
            throw new RuntimeException("");
        }
    }

    public static String createPlaybackUrl(Message message) {
        try {
            JSONObject args = new JSONObject();
            args.put("token", loginToken());
            args.put("id", message.id);
            String url = kApiRoot + "/squawks/serve?args=" + URLEncoder.encode(args.toString(), "utf-8");
            return url;
        } catch (Exception e) {
            throw new RuntimeException("");
        }
    }

    public static DownloadCache squawkDownloadCache = new DownloadCache("PreloadedSquawks");
}

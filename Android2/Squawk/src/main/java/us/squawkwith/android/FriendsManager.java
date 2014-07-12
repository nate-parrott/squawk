package us.squawkwith.android;

import android.content.ContentResolver;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.provider.ContactsContract;
import android.util.Log;

import com.loopj.android.http.JsonHttpResponseHandler;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

/**
 * Created by nateparrott on 7/1/14.
 */
public class FriendsManager {
    public FriendsManager() {
        data = SquawkApp.getAppContext().getSharedPreferences(kDataKey, Context.MODE_PRIVATE);
    }
    static String kDataKey = "kDataKey";
    SharedPreferences data;

    private boolean syncInProgress = false;
    private HashMap<String, String> needsSyncAfterWithMap = null;
    public void syncContactsToServer(HashMap<String, String> phonesToNamesMap) {
        if (syncInProgress) {
            needsSyncAfterWithMap = phonesToNamesMap;
        }
        syncInProgress = true;
        uploadContacts(phonesToNamesMap);
    }
    private void uploadContacts(HashMap<String, String> phonesToNamesMap) {
        // [phone#]:[Name] strings, to which we'll store in userPrefs to determine which ones are new and have to be uploaded:
        final HashSet<String> identifiers = new HashSet<String>(phonesToNamesMap.size());
        for (String phone : phonesToNamesMap.keySet()) {
            identifiers.add(phone + ":" + phonesToNamesMap.get(phone));
        }
        Set<String> uploadedIdentifiers = data.getStringSet("UploadedContactIdentifiers", new HashSet<String>());
        ArrayList<String> phoneNumbersToUpload = new ArrayList<String>();
        ArrayList<String> namesToUpload = new ArrayList<String>();
        for (String identifier : identifiers) {
            if (!uploadedIdentifiers.contains(identifier)) {
                // we need to upload this:
                String[] idParts = identifier.split(":");
                String phone = idParts[0];
                String name = idParts[1];
                phoneNumbersToUpload.add(phone);
                namesToUpload.add(name);
            }
        }
        if (phoneNumbersToUpload.size() > 0) {
            // upload:
            try {
                JSONObject postBody = new JSONObject();
                postBody.put("contact_phones", new JSONArray(phoneNumbersToUpload));
                postBody.put("contact_names", new JSONArray(namesToUpload));
                byte[] payload = postBody.toString().getBytes("utf-8");
                Squawk.post("/register_contacts", null, payload, "application/octet-stream", new JsonHttpResponseHandler() {
                    public void onSuccess(int statusCode, org.apache.http.Header[] headers, JSONObject response) {
                        if (response.optString("success", "no").equals("okay")) {
                            data.edit().putStringSet("UploadedContactIdentifiers", identifiers).commit();
                            downloadContacts(true);
                        }
                    }
                    public void onFailure(int statusCode, org.apache.http.Header[] headers, java.lang.Throwable throwable, org.json.JSONObject errorResponse) {
                        doneSyncing(false);
                    }
                });
            } catch (Exception e) {
                throw new RuntimeException();
            }
        } else {
            downloadContacts(false);
        }
    }

    static long kMinFriendsOnSquawkRefreshSeconds = 60 * 60 * 20; // every 20 hrs

    private void downloadContacts(boolean newlyUploadedContacts) {
        long lastDownloaded = data.getLong("LastDownloaded", 0); // unix time
        final long now = System.currentTimeMillis() / 1000;
        if (now - lastDownloaded > kMinFriendsOnSquawkRefreshSeconds || newlyUploadedContacts) {
            Squawk.get("/check_contacts_signed_up", null, new JsonHttpResponseHandler() {
                public void onSuccess(int statusCode, org.apache.http.Header[] headers, JSONObject response) {
                    JSONArray phones = response.optJSONArray("phones");
                    if (phones != null) {
                        HashSet<String> phonesSet = new HashSet<String>(phones.length());
                        for (int i=0; i<phones.length(); i++) {
                            phonesSet.add(phones.optString(i, ""));
                        }
                        data.edit().putStringSet("Phones", phonesSet).putLong("LastDownloaded", now).commit();
                        doneSyncing(true);
                    } else {
                        doneSyncing(false);
                    }
                }
                public void onFailure(int statusCode, org.apache.http.Header[] headers, java.lang.Throwable throwable, org.json.JSONObject errorResponse) {
                    doneSyncing(false);
                }
            });
        } else {
            doneSyncing(false);
        }
    }

    private void doneSyncing(boolean didUpdate) {
        syncInProgress = false;
        if (needsSyncAfterWithMap != null) {
            HashMap<String, String> map = needsSyncAfterWithMap;
            needsSyncAfterWithMap = null;
            syncContactsToServer(map);
        }
        if (didUpdate) {
            for (FriendsOnSquawkCallback callback : callbacks) {
                callback.didUpdate();
            }
        }
    }

    public Set<String> getPhonesOfFriendsOnSquawk() {
        return data.getStringSet("Phones", new HashSet<String>());
    }

    public static class FriendsOnSquawkCallback {
        public void didUpdate() {}
    }

    public ArrayList<FriendsOnSquawkCallback> callbacks = new ArrayList<FriendsOnSquawkCallback>();
}

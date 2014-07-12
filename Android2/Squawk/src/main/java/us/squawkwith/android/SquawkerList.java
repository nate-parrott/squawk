package us.squawkwith.android;

import android.content.ContentResolver;
import android.database.ContentObserver;
import android.database.Cursor;
import android.os.Handler;
import android.provider.ContactsContract;
import android.widget.ListView;

import com.loopj.android.http.JsonHttpResponseHandler;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.security.acl.Group;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Set;

/**
 * Created by nateparrott on 6/30/14.
 */
public class SquawkerList {
    SquawkerList() {
        callbacks = new ArrayList<SquawkerListUpdatedCallback>();
        SquawkApp.getAppContext().getContentResolver().registerContentObserver(ContactsContract.Contacts.CONTENT_URI, true, new ContentObserver(new Handler()) {
            @Override
            public void onChange(boolean selfChange) {
                update();
            }
        });
        friendsManager = new FriendsManager();
        friendsManager.callbacks.add(new FriendsManager.FriendsOnSquawkCallback() {
                @Override
                public void didUpdate() {
                    update();
                }
        });
    }

    public FriendsManager friendsManager;

    ArrayList<Message> squawks;
    public void refreshSquawks() {
        Squawk.get("/squawks/recent", null, new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, org.apache.http.Header[] headers, JSONObject response) {
                if (response.optBoolean("success")) {
                    JSONArray results = response.optJSONArray("results");
                    ArrayList<Message> resultSquawks = new ArrayList<Message>(results.length());
                    for (int i = 0; i<results.length(); i++) {
                        try {
                            resultSquawks.add(new Message(results.getJSONObject(i)));
                        } catch (JSONException e) {
                            throw new RuntimeException();
                        }
                    }
                    squawks = resultSquawks;
                    Squawk.squawkDownloadCache.preloadSquawks(squawks);
                    update();
                } else {
                    // error
                    update();
                }
            }

            @Override
            public void onFailure(int statusCode, org.apache.http.Header[] headers, java.lang.Throwable throwable, org.json.JSONObject errorResponse) {
                // don't do anything yo
            }
        });
    }

    public void update() {
        HashMap<String, Squawker> squawkersByPhone = new HashMap<String, Squawker>();

        ContentResolver resolver = SquawkApp.getAppContext().getContentResolver();
        Cursor phoneNumbers = resolver.query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, null, null, null, null);
        int kPhoneNumber = phoneNumbers.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER);
        int kPhoneAssociatedID = phoneNumbers.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID);

        HashMap<String, Squawker> squawkersForContactIDs = new HashMap<String, Squawker>();

        while (phoneNumbers.moveToNext()) {
            String number = phoneNumbers.getString(kPhoneNumber);
            if (number != null && number.length() >= 10) {
                number = Squawker.normalizePhoneNumber(number);
                Squawker squawker = squawkersByPhone.get(number);
                if (squawker == null) {
                    squawker = new Squawker();
                    squawkersByPhone.put(number, squawker);
                }
                squawker.phoneNumbers.add(number);
                String contactID = phoneNumbers.getString(kPhoneAssociatedID);
                squawker.contactIDs.add(contactID);
                squawkersForContactIDs.put(contactID, squawker);
            }
        }

        Cursor contacts = resolver.query(ContactsContract.Contacts.CONTENT_URI, null, null, null, null);
        HashMap<String, String> namesForPhones = new HashMap<String, String>(); // for upload to the server for push notifications
        int kID = contacts.getColumnIndex(ContactsContract.Contacts._ID);
        int kDisplayName = contacts.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME);
        while (contacts.moveToNext()) {
            String id = contacts.getString(kID);
            Squawker squawker = squawkersForContactIDs.get(id);
            if (squawker != null) {
                if (squawker.name == null) {
                    squawker.name = contacts.getString(kDisplayName);
                    for (String phone : squawker.phoneNumbers) {
                        namesForPhones.put(phone, squawker.name);
                    }
                }
            }
        }
        friendsManager.syncContactsToServer(namesForPhones);

        addSpecialSquawkers(squawkersByPhone);

        if (squawks != null) {
            for (Message squawk : squawks) {
                Squawker squawker = squawkersByPhone.get(squawk.sender);
                if (squawker == null) {
                    squawker = new Squawker();
                    squawkersByPhone.put(squawk.sender, squawker);
                    squawker.phoneNumbers.add(squawk.sender);
                }
                squawker.isRegistered = true;
                squawker.squawks.add(squawk);
            }
        }

        Set<String> registeredPhones = friendsManager.getPhonesOfFriendsOnSquawk();
        if (registeredPhones != null) {
            for (String phone : registeredPhones) {
                Squawker squawker = squawkersByPhone.get(phone);
                if (squawker != null) {
                    squawker.isRegistered = true;
                }
            }
        }
        mGroups = sortIntoGroups(squawkersByPhone.values());
        didUpdate();
    }
    private int kMostRecent = 2;
    private List<List<Squawker>> sortIntoGroups(Collection<Squawker> squawkers) {
        ArrayList<Squawker> registered = new ArrayList<Squawker>(squawkers.size());
        ArrayList<Squawker> unregistered = new ArrayList<Squawker>(squawkers.size());
        for (Squawker sq : squawkers) {
            if (sq.isRegistered) {
                registered.add(sq);
            } else {
                unregistered.add(sq);
            }
        }
        Collections.sort(registered);
        // don't sort unregistered; it's probably already in some sort of ordering
        List<Squawker> topKGroup = registered.subList(0, Math.min(kMostRecent, registered.size()));
        List<Squawker> registeredGroup = registered.subList(topKGroup.size(), registered.size());

        ArrayList<List<Squawker>> groups = new ArrayList<List<Squawker>>(3);
        groups.add(topKGroup);
        groups.add(registeredGroup);
        groups.add(unregistered);
        return groups;
    }

    public List<List<Squawker>> mGroups;

    public static class SquawkerListUpdatedCallback {
        public void onChange() {};
    }
    public List<SquawkerListUpdatedCallback> callbacks;
    private void didUpdate() {
        for (SquawkerListUpdatedCallback cb : callbacks) {
            cb.onChange();
        }
    }

    private void addSpecialSquawkers(HashMap<String, Squawker> squawkersByPhone) {
        Squawker robot = new Squawker();
        robot.phoneNumbers.add(Squawker.normalizePhoneNumber("00000000000"));
        robot.name = "Squawk Robot";
        squawkersByPhone.put(robot.phoneNumbers.get(0), robot);
    }
}

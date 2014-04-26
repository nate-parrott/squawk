package com.parrott.squawk;

import android.app.Activity;
import android.app.ListActivity;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Bundle;
import android.provider.ContactsContract;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ListView;
import android.telephony.TelephonyManager;
import android.widget.TextView;
import android.widget.Toast;

import com.parse.FindCallback;
import com.parse.GetDataCallback;
import com.parse.ParseAnalytics;
import com.parse.ParseObject;
import com.parse.ParseQuery;
import com.parse.ParseUser;

import java.text.ParseException;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.parse.ParseQueryAdapter;

public class MainActivity extends ListActivity {

    private Map<String, Person> people = new HashMap<String, Person>();
    private ContactAdapter contactAdapter;
    private EditText filterText;
    private boolean isPlaying = false;
    private ParseUser me;

    /**
     * Called when the activity is first created.
     */
    public void onCreate(Bundle savedInstanceState) {
        if (ParseUser.getCurrentUser() == null) {
            splashScreen();
        }
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        ParseAnalytics.trackAppOpened(getIntent());
        me = ParseUser.getCurrentUser();
        Cursor cursor = getContentResolver().query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, null, null, null, null);

        while (cursor.moveToNext()) {
            String contactName = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME));
            String contactPhone = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER));
            contactPhone = contactPhone.replaceAll("[^0-9]", "").length() != 11 ?
                    "1" + contactPhone.replaceAll("[^0-9.]", "") : contactPhone.replaceAll("[^0-9.]", "");

            if (contactPhone != null) {
                contactName = contactName == null ? contactPhone : contactName;
                people.put(contactPhone, new Person(contactName, contactPhone));
            }
        }
        cursor.close();
        contactAdapter = new ContactAdapter(people);
        //filterText = (EditText) findViewById(R.id.inputSearch);
        //filterText.addTextChangedListener(filterTextWatcher);
        ListView list = (ListView) findViewById(android.R.id.list);
        list.setAdapter(contactAdapter);
        updateData();
        updateScreen(list);
    }

    private void updateScreen(ListView list) {
        contactAdapter = new ContactAdapter(people);
        list.setAdapter(contactAdapter);
        list.setLongClickable(false);
        list.setOnItemClickListener(new ListView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, View view, int pos, long id) {
                Log.d("test", "onItemClick has fired with position " + pos);
                Person contact = contactAdapter.getItem(pos).getValue();
                MediaPlayer mp = new MediaPlayer();
                contact.setUnreadMsgs(contact.getUnreadMsgs() - 1);
                contactAdapter.notifyDataSetChanged();
                if (contact.getUnreadMsgs() != 0) {

                    if (!isPlaying) {
                        isPlaying = true;
                        try {
                            mp.setDataSource(contact.getNextSquawkFile().getUrl());
                            mp.prepare();
                            mp.start();
                        } catch (Exception e) {
                            Log.e("test", "prepare() failed");
                        }
                    } else {
                        isPlaying = false;
                        mp.release();
                        mp = null;
                    }
                }
            }
        });
    }


    public void updateData() {
        Log.d("test", "Beginning updateData");
        ParseObject.registerSubclass(Message.class);
        ParseQuery<Message> query = new ParseQuery("Message");
        query.whereEqualTo("recipient", me);
        query.setLimit(50);
        query.orderByDescending("createdAt");
        query.findInBackground(new FindCallback<Message>() {
            @Override
            public void done(List<Message> msgs, com.parse.ParseException e) {
                Log.d("test", "finished fetching msgs");
                if (msgs != null)
                    Log.d("test", msgs.toString());
                if (e == null) {
                    for (Message msg : msgs) {
                        String sender = msg.getSenderPhoneNumber();
                        if (!msg.getListened()) {
                            if (people.containsKey(sender)) {
                                people.get(sender).addMessage(msg);
                            } else
                                people.put(sender, new Person(sender, sender));
                        }
                    }

                } else {
                    Log.d("test", "PARSE FUCKED UP: " + e);
                }
            }
        });
        contactAdapter = new ContactAdapter(people);
        contactAdapter.notifyDataSetChanged();
    }


    public void beginRecordingHandler() {

    }

    public String returnMyNumber() {
        String num = null;
        String service = Context.TELEPHONY_SERVICE;
        TelephonyManager tel_manager = (TelephonyManager) getSystemService(service);
        int device_type = tel_manager.getPhoneType();

        switch (device_type) {
            case (TelephonyManager.PHONE_TYPE_CDMA):
                num = tel_manager.getLine1Number();
                break;
            default:
                //return something else
                num = "no number";
                break;
        }
        return num.replaceAll("[^0-9]", "").length() != 11 ? "1" + num.replaceAll("[^0-9.]", "") : num.replaceAll("[^0-9.]", "");
    }

    public void splashScreen() {
        Intent startApp = new Intent(MainActivity.this, StartupScreen.class);
        startActivityForResult(startApp, 10);
    }


}

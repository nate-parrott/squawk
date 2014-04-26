package com.parrott.squawk.squawk;

import android.app.Activity;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.database.Cursor;
import android.os.AsyncTask;
import android.os.Bundle;
import android.provider.ContactsContract;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.ListView;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;


public class SquawkMainActivity extends Activity {
    final static int LOGIN_REQUEST = 10;
    final static String DEBUG = SquawkMain.DEBUG;

    private Dialog progressDialog;
    private SquawkAdapter adapter;
    private HashMap<String, SquawkThread> threads = new HashMap<String, SquawkThread>();
    private List<Message> squawks;
    //session stuff
    private String myPhoneNum;
    private String myToken;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        SharedPreferences myData = getPreferences(0);

        // checks if user is logged in -- if not, prompts with login screen
        if (myData.getString("token", "").length() < 1) {
            Log.d(DEBUG, "First time");
            loginScreen();
        } else {
            Log.d(DEBUG, "Not first time");
            myPhoneNum = myData.getString("phone", "");
            myToken = myData.getString("token", "");
        }

        setContentView(R.layout.squawk_main);
        //get contacts from phone
        getContacts();
        //get squawks in background
        GetSquawksTask getSquawks = new GetSquawksTask();
        getSquawks.execute();

    }

    private class GetSquawksTask extends AsyncTask<Void, Void, JSONObject> {

        protected JSONObject doInBackground(Void... params) {
            // Gets the current list of squawks to me
            try {
                JSONObject args = new JSONObject();
                args.put("token", myToken);
                //JSONObject response = new SquawkMain.GetJSONTask().execute();
                JSONObject response = SquawkMain.getJSON(getResources().getString(R.string.get_squawks), args);
                if(response.getBoolean("success")){
                    return response;
                }
            } catch (Exception e) {
                // TODO Auto-generated catch block
            }
            Log.d(DEBUG, "requesting messages");
            return null;
        }

        @Override
        protected void onPreExecute() {
            SquawkMainActivity.this.progressDialog = ProgressDialog.show(SquawkMainActivity.this, "",
                    "Loading...", true);
            super.onPreExecute();
        }

        @Override
        protected void onProgressUpdate(Void... values) {
            super.onProgressUpdate(values);
        }

        @Override
        protected void onPostExecute(JSONObject result) {
            if (result == null)
               return;
            //check if sender is in our contacts
            try{
                JSONArray squawks = result.getJSONArray("results");
                for(int i = 0; i < squawks.length(); i++){
                    JSONObject squawk = squawks.getJSONObject(i);
                    String thisSender = squawk.getString("sender");
                    //populate an array of members
                    JSONArray thisMembersJSON = squawk.getJSONArray("thread_members");
                    //if this is not a multisquawk, membersMinusMe should contain just the sender
                    ArrayList<String> membersMinusMe = new ArrayList<String>();
                    for(int j = 0; j < thisMembersJSON.length(); j++){
                        if (!thisMembersJSON.getString(j).equals(myPhoneNum))
                            membersMinusMe.add(thisMembersJSON.getString(j));
                    }
                    String thisId = squawk.getString("_id");
                    String thisDate = squawk.getString("date");
                    Message thisMsg = new Message(thisSender, membersMinusMe, thisId, thisDate);

                    //if we don't already have a thread for these members, create one and add this message
                    if(threads.containsKey(membersMinusMe)){
                        threads.get(thisSender).addMessage(thisMsg);
                    }
                    else {
                        String name = "";
                        for(String member : membersMinusMe){
                            //if the phone number has a name, use that
                            if(threads.containsKey(member)){
                                name += threads.get(member).getDisplayName() + ", ";
                            }
                            //else add the phone number
                            else
                                name += member;
                        }

                        SquawkThread newThread = new SquawkThread(membersMinusMe, name);
                        newThread.addMessage(thisMsg);
                        threads.put(name, newThread);
                    }

                }
                adapter = new SquawkAdapter(getParent(), (List) threads.values());
                ListView list = (ListView) findViewById(android.R.id.list);
                list.setAdapter(adapter);
                SquawkMainActivity.this.progressDialog.dismiss();
            } catch (JSONException e){
                e.printStackTrace();
            }
        }
    }

    private void getContacts(){
        Cursor cursor = getContentResolver().query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, null, null, null, null);

        while (cursor.moveToNext()) {
            String contactName = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME));
            String contactPhone = cursor.getString(cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER));
            contactPhone = formatPhoneNum(contactPhone);

            if (contactPhone != null) {
                contactName = (contactName == null ? contactPhone : contactName);
                threads.put(contactPhone, new SquawkThread(contactPhone, contactName));
            }
        }
        cursor.close();
    }


    private String formatPhoneNum(String contactPhone){
        return contactPhone.replaceAll("[^0-9]", "").length() != 11 ?
                "1" + contactPhone.replaceAll("[^0-9.]", "") : contactPhone.replaceAll("[^0-9.]", "");
    }

    public void loginScreen() {
        Intent startApp = new Intent(this, LoginScreenActivity.class);
        startActivityForResult(startApp, LOGIN_REQUEST);
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.squawk_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        if (id == R.id.action_settings) {
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        // Check which request we're responding to
        if (requestCode == LOGIN_REQUEST) {
            // Make sure the request was successful
            if (resultCode == RESULT_OK) {
                // yay! (this is the only possible result of a login request anyway...)
            }
        }
    }

}

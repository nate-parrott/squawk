package com.parrott.squawk.squawk;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.telephony.SmsManager;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.*;
import java.security.SecureRandom;

/**
 *  allows user to login to squawk
 */
public class LoginScreenActivity extends Activity {

    SecureRandom random = new SecureRandom();
    final static String SQUAWK_NUMBER = "6465767688";
    String secretKey;

    private String getSecret() {
        return secretKey;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().requestFeature(Window.FEATURE_ACTION_BAR);
        getActionBar().hide();
        setContentView(R.layout.login_screen);
    }


    @Override
    public boolean onCreateOptionsMenu(Menu menu) {

        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.launch_screen, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        return id == R.id.action_settings || super.onOptionsItemSelected(item);
    }

    /**
     * sends a verification text to the Squawk phone number (SQUAWK_NUMBER)
     * @param secretKey is the secret verification key
     */
    private void sendVerificationText(String secretKey) {
        SmsManager sms = SmsManager.getDefault();
        sms.sendTextMessage(SQUAWK_NUMBER, null, secretKey, null, null);
    }

    /**
     * attempts to login to Squawk (Will - replaced GET with the global method)
     * @param secretKey is the secret verification key
     * @return true if login is successful, o/w false
     */
    private boolean login(String secretKey) throws IOException {
        boolean toReturn = false;
        JSONObject args = new JSONObject();
        try {
            args.put("secret", secretKey);
            JSONObject responseJSON = SquawkMain.getJSON("/make_token", args);
            if (responseJSON.getBoolean("success")) {
                SharedPreferences myData = getPreferences(0);
                SharedPreferences.Editor editor = myData.edit();
                editor.putString("phone", responseJSON.getString("phone"));
                editor.putString("token", responseJSON.getString("token"));
                editor.commit();
                toReturn = true;
            }
        } catch (JSONException e) {
            Log.d("login", "json error: " + e);
        }
        return toReturn;
    }

    /**
     * join squawk for the first time
     * @param view is the view of the join button (required parameter)
     */
    public void join(View view) {
        Log.d("login", "button clicked");
        secretKey = "Your secret key is " + random.nextInt();
        sendVerificationText(secretKey);

        ProgressDialog dialog = new ProgressDialog(LoginScreenActivity.this);
        dialog.setMessage("Logging in...");
        dialog.show();

        Thread login = new Thread(new Runnable() {
            @Override
            public void run() {
                boolean loggedIn = false;

                while (!loggedIn) {
                    try {
                        Log.d("Comments", "Trying to login");
                        loggedIn = login(getSecret());
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    try {
                        Thread.sleep(1000);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                Log.d("Comments", "Logged in!");

            }
        });
        login.start();

        dialog.dismiss();

        // the following code sends the user back into the main Squawk activity
        Intent returnIntent = new Intent();
        setResult(RESULT_OK, returnIntent);
        finish();
    }
}

package com.parrott.squawk;

import android.app.Activity;
import android.content.Intent;
import android.net.ParseException;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;

import com.parse.LogInCallback;
import com.parse.ParseCloud;
import com.parse.ParseInstallation;
import com.parse.ParseUser;

import org.json.JSONObject;

import java.math.BigInteger;
import java.security.SecureRandom;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by Will on 1/27/14.
 * Initial activity will spawn the splash screen and initiate sms verification
 */
public class StartupScreen extends Activity implements View.OnClickListener{


    private SecureRandom random = new SecureRandom();
    private String password;
    private String username;
    private TextView startPrompt;
    private EditText nickName;


    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.startup_screen);
        if (ParseUser.getCurrentUser()== null){
            this.password = new BigInteger(130, random).toString(32);
            startPrompt = (TextView) findViewById(R.id.verify);
            nickName = (EditText) findViewById(R.id.nickname);
            startPrompt.setOnClickListener(this);
        }
    }

    public void sendSmsVerify(){
        Intent sendIntent = new Intent(Intent.ACTION_VIEW);
        sendIntent.setData(Uri.parse("smsto:6465767688"));
        sendIntent.putExtra("sms_body", this.password);
        startActivity(sendIntent);
    }

    @Override
    public void onClick(View view) {
        if (nickName.getText().toString().trim().equals("")){
            nickName.setHint("please enter a nickname!");
            return;
        }

        boolean tryToLogin = true;
        sendSmsVerify();
        HashMap<String, String> args = new HashMap<String, String>();
        args.put("password", this.password);
        while(tryToLogin){
            try{
                username = getCloudCallResult("lookupUsernameByPassword",  args).toString();
                Log.d("test", "username is: " + username);
                tryToLogin = false;
            } catch(Exception e) {
                Log.d("test", e.toString());
                tryToLogin = true;
            }
        }

        ParseUser.logInInBackground(username, password, new LogInCallback() {
            @Override
            public void done(ParseUser parseUser, com.parse.ParseException e) {
                ParseUser.getCurrentUser().put("nickname", nickName.getText().toString());
                ParseUser.getCurrentUser().put("installation", ParseInstallation.getCurrentInstallation());
                ParseInstallation.getCurrentInstallation().saveInBackground();
                ParseUser.getCurrentUser().saveInBackground();
                setResult(Activity.RESULT_OK);
                finish();

            }
        });
    }

    public Object getCloudCallResult(String methodName, HashMap<String, String> args) throws com.parse.ParseException{
        Object jObj = JSONObject.NULL;
        while (jObj == JSONObject.NULL){
            jObj = ParseCloud.callFunction(methodName, args);
            Log.d("test", "waiting for login...");
            try{
                Thread.sleep(1000);
            } catch (Exception e){Log.d("test", "interrupted by " + e.toString());}
        }
        return jObj;
    }

    @Override
    public void onBackPressed(){
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.addCategory(Intent.CATEGORY_HOME);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }



}
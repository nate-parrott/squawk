package com.parrott.squawk;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

/**
 * Created by Will on 1/30/14.
 * gets push notifications and triggers an update
 */
public class Receiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        try{
            if (intent.getAction().toString() == "android.intent.action.UPDATE"){
                Intent i = new Intent(context, MainActivity.class);
                context.startActivity(i);
            }
        } catch(Exception e)
        {
            Log.d("test", e.toString());
        }
    }
}

package us.squawkwith.android;

import android.app.Application;
import android.content.Context;

/**
 * Created by nateparrott on 6/29/14.
 */
public class SquawkApp extends Application {
    private static Context context;

    public void onCreate(){
        super.onCreate();
        SquawkApp.context = getApplicationContext();
    }

    public static Context getAppContext() {
        return SquawkApp.context;
    }
}

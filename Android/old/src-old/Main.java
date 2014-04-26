package com.parrott.squawk;

import com.parse.Parse;
import com.parse.ParseACL;
import com.parse.ParseInstallation;
import com.parse.ParseObject;

import com.parse.ParseUser;
import com.parse.PushService;

import android.app.Application;

public class Main extends Application {

	@Override
	public void onCreate() {
		super.onCreate();

		// Add your initialization code here
        Parse.initialize(this, "lEf1qOOpwSfPKKDcOTPuFOxfZJa5ArkaCDRZqPpu", "IyoFHiUjlOuHvhHp3UxJKSpsBhfg8vpEExENQg3Q");

		ParseACL defaultACL = new ParseACL();
	    
		// If you would like all objects to be private by default, remove this line.
		defaultACL.setPublicReadAccess(true);
        PushService.setDefaultPushCallback(this, SquawkMainActivity.class);
		ParseACL.setDefaultACL(defaultACL, true);
	}
}

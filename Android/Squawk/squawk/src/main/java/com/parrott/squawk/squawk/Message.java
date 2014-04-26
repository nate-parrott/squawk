package com.parrott.squawk.squawk;

import org.json.JSONObject;

import java.text.DateFormat;
import java.util.ArrayList;
import java.util.Date;

/**
 * Created by Will on 3/28/2014.
 */

/**
 * defines a message in Squawk. Contains methods for playing back a message (and for replying?)
 */
public class Message {
    //From
    private String senderPhone;
    //To
    private ArrayList<String> threadMembers;
    //Unique ID
    private String _id;
    private String date;

    public Message(String senderPhone, ArrayList<String> threadMembers, String _id, String date){
        this.senderPhone = senderPhone;
        this.threadMembers = threadMembers;
        this._id = _id;
        this.date = date;
    }

    public String getSenderPhone() {
        return senderPhone;
    }

    public ArrayList<String> getThreadMembers() {
        return threadMembers;
    }

    public String get_id() {
        return _id;
    }

    public String getDate() {
        return date;
    }

    public boolean getSquawk(){
        JSONObject args = new JSONObject();
        try {
            args.put("id", this._id);
        } catch (Exception e){
            e.printStackTrace();
        }

        //JSONObject response = SquawkMain.GET("" + R.string.play_squawk, args);
        return false;
    }

    public boolean reply(){

        return false;
    }

}

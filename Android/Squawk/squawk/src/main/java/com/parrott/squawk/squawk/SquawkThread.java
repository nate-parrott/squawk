package com.parrott.squawk.squawk;

import android.util.Log;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by Will on 3/28/2014.
 */
public class SquawkThread {
    private List<Message> msgs = new ArrayList<Message>();
    //For display in the listview
    private String displayName;
    //Recipients
    private ArrayList<String> threadMembers;
    public boolean hasApp;
    public SquawkThread(ArrayList<String> threadMembers, String displayName){
        this.threadMembers = threadMembers;
        this.displayName = displayName;
    }

    //constructor for single phone number
    public SquawkThread(String phoneNum, String name){
        this.displayName = name;
        this.threadMembers = new ArrayList<String>();
        threadMembers.add(phoneNum);
    }

    public void addMessage(Message m){
        this.msgs.add(m);
    }

    public int numMsgs(){
        return msgs.size();
    }

    public Message popMessage(){
        if (msgs.size() > 0)
            return msgs.remove(msgs.size() -1);
        else
            Log.d("test", "no messages!");
        return null;
    }

    public boolean exactPhoneMatch(String[] otherNums){
        boolean result = true;
        if(otherNums.length != threadMembers.size())
            return false;
        else{
            for(int i = 0;  i< otherNums.length; i++){
                result = result || otherNums[i].equals(threadMembers.get(0));
            }
        }
        return result;
    }

    public boolean exactPhoneMatch(String otherNum){
        if(threadMembers.size() != 1)
            return false;
        return otherNum.equals(threadMembers.get(0));
    }

    public String getDisplayName(){
        return this.displayName;
    }

}

package com.parrott.squawk;

import com.parse.ParseFile;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * Created by Will on 1/26/14.
 * Person represents a contact and allows you to access their squawks
 */
public class Person {
    private String phoneNumber;
    private String name;
    private int unreadMsgs = 0;
    private Date date = null;
    private List<Message> pendingSquawks = new ArrayList<Message>();


    public Person(){

    }

    public Person(String name, String phone){
        this.setName(name);
        this.setPhone(phone);
    }

    public void setPhone(String num){
        this.phoneNumber = num.replaceAll("[^0-9]", "").length() <= 11 ? "1" + num.replaceAll("[^0-9.]", "") : num.replaceAll("[^0-9.]", "");
    }

    public String getPhone(){

        return this.phoneNumber;
    }

    public void addMessage(Message squawk){
        date = squawk.getTime();
        pendingSquawks.add(squawk);
    }

    public ParseFile getNextSquawkFile(){
        Message nextMsg =pendingSquawks.remove(pendingSquawks.size() -1);
        nextMsg.put("listened", true);
        nextMsg.saveInBackground();
        return nextMsg.getFile();
    }

    public void setName(String name){
        this.name = name;
    }

    public String getName(){
        return this.name;
    }


    public int getUnreadMsgs(){
        return this.pendingSquawks.size();
    }

    public void setUnreadMsgs(int x){
        this.unreadMsgs = x;
    }


    public Date getMostRecent(){
        return this.date;

    }
}

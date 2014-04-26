package com.parrott.squawk;

import com.parse.ParseClassName;
import com.parse.ParseFile;
import com.parse.ParseObject;
import com.parse.ParseUser;

import java.util.Date;

/**
 * Created by will on 1/26/14.
 * An extension of ParseObject that makes
 * it more convenient to access information
 * about a given Message
 */

@ParseClassName("Message")
public class Message extends ParseObject {
    public Message(){

    }

    public String getRecipientPhoneNumber(){
        return getParseUser("recpient").getUsername();
    }
    public void setRecipient(ParseUser recipient){
        put("recipient", recipient);
    }
    public String getSenderPhoneNumber(){
        try{
            return getParseUser("sender").fetchIfNeeded().getUsername();
        } catch (Exception e) {
            return "";
        }

    }

    public void setSender(ParseUser me){
        put("sender", me);

    }

    public boolean getListened(){
        return getBoolean("listened");
    }

    public void setListened(boolean val){
        put("listened", val);
    }

    public ParseFile getFile(){
        return getParseFile("file");
    }

    public void setFile(ParseFile file){
        put("file", file);
    }

    public Date getTime(){
        return getUpdatedAt();
    }
}

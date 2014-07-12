package us.squawkwith.android;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * Created by nateparrott on 6/30/14.
 */
public class Squawker implements Comparable<Squawker> {
    public static String normalizePhoneNumber(String phone) {
        StringBuilder sb = new StringBuilder();
        String digits = "0123456789";
        int phoneLen = phone.length();
        for (int i=0; i<phoneLen; i++) {
            char c = phone.charAt(i);
            boolean isDigit = false;
            for (int d=0; d<10 && !isDigit; d++) {
                isDigit = digits.charAt(d) == c;
            }
            if (isDigit) {
                sb.append(c);
            }
        }
        while (sb.length() < 11) {
            sb.insert(0, '1');
        }
        return sb.toString();
    }

    ArrayList<String> phoneNumbers = new ArrayList<String>();
    ArrayList<String> contactIDs = new ArrayList<String>();
    String name = null;
    boolean isRegistered = false;
    ArrayList<Message> squawks = new ArrayList<Message>(); // should be in reverse chronological order

    @Override
    public String toString() {
        if (name != null) return name;
        if (phoneNumbers.size() > 0) {
            return phoneNumbers.get(0);
        }
        return "Unknown Squawker";
    }

    public List<Message> getUnread() { // in chronological order:
        ArrayList<Message> unread = new ArrayList<Message>();
        for (Message sq : squawks) {
            if (sq.listened == false) {
                unread.add(0, sq);
            }
        }
        return unread;
    }
    public int getUnreadCount() {
        return getUnread().size();
    }

    public long lastMessageTimeMS() {
        return squawks.isEmpty() ? 0 : squawks.get(0).date.getTime();
    }

    public int compareTo(Squawker other) {
        long comp = other.lastMessageTimeMS() - lastMessageTimeMS();
        if (comp < 0) return -1; else if (comp > 0) return 1;
        int regComp = (other.isRegistered ? 1 : 0) - (isRegistered ? 1 : 0);
        if (regComp != 0) return regComp;
        return toString().compareTo(other.toString());
    }
}

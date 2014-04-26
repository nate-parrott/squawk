package com.parrott.squawk;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import android.content.Context;
import android.graphics.Typeface;
import android.media.MediaRecorder;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.Filterable;
import android.widget.ImageButton;
import android.widget.RelativeLayout;
import android.widget.TextView;


import com.parse.ParseFile;

import java.util.Map;
import java.util.TreeMap;

/**
 * Created by Will on 1/26/14.
 * an adapter to display contacts in the main app
 */
public class ContactAdapter extends BaseAdapter{

    private ArrayList<TreeMap.Entry> people;
    private RecordButton record;
    private MediaRecorder mRecorder;
    private ParseFile squawk;
    private File squawkFile = null;


    public ContactAdapter(Map<String, Person> map){
        people = new ArrayList<TreeMap.Entry>();
        ValueComparator comparator = new ValueComparator(map);
        TreeMap<String, Person> sorted = new TreeMap<String, Person>(comparator);
        sorted.putAll(map);
        people.addAll(sorted.entrySet());
    }

    @Override
    public int getCount() {
        return people.size();
    }

    @Override
    public TreeMap.Entry<String, Person> getItem(int position) {
        return (TreeMap.Entry) people.get(position);
    }

    @Override
    public long getItemId(int position) {
        return 0;
    }

    public View getView(int position, View convertView, ViewGroup parent) {
        final View result;

        if (convertView == null) {
            result = LayoutInflater.from(parent.getContext()).inflate(R.layout.list_item, null);
        } else {
            result = convertView;
        }
        TreeMap.Entry<String, Person> item = getItem(position);
        //adjust the name to display pending squawks
        String toDisplay = item.getValue().getName();
        if(item.getValue().getUnreadMsgs() > 0){
            toDisplay += "(" + item.getValue().getUnreadMsgs() + ")";
            ((TextView) result.findViewById(R.id.contact_name)).setTypeface(null, Typeface.BOLD);
        }
        else {
            ((TextView) result.findViewById(R.id.contact_name)).setTypeface(null, Typeface.NORMAL);
        }
        ((TextView) result.findViewById(R.id.contact_name)).setText(toDisplay);
        //bind record button to handler
        record = new RecordButton((ImageButton) result.findViewById(R.id.record));
        record.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent){
                RelativeLayout row = (RelativeLayout) view.getParent();
                if(motionEvent.getAction() == MotionEvent.ACTION_DOWN){
                    try {
                        onRecord(row.getContext(), true);
                        //start animate
                    } catch (Exception e){
                        Log.d("test", e.toString());
                    }
                }
                else if (motionEvent.getAction() == MotionEvent.ACTION_UP){
                    try{
                        //stop animate
                        onRecord(getContext(), false);
                    } catch (Exception e){
                        Log.d("test", e.toString());
                    }
                    Message mySquawk = new Message();
                    mySquawk.setRecipient();
                }
                return true;
            });
        //record.setLongClickable(true);
        return result;
    }
    private void onRecord(Context context, boolean start) throws IOException{
        if (start) {
            startRecording(context);
        } else {
            stopRecording();
        }
    }

    private void startRecording(Context context) throws IOException {
        File outputDir = context.getCacheDir();
        File squawkFile = File.createTempFile("squawk", "mp4", outputDir);
        mRecorder = new MediaRecorder();
        mRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
        mRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
        mRecorder.setOutputFile(squawkFile.getPath());
        mRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);

        try {
            mRecorder.prepare();
        } catch (IOException e) {
            Log.e("test", "prepare() failed in startRecording");
        }

        mRecorder.start();
    }

    private void stopRecording() {
        mRecorder.stop();
        mRecorder.release();
        mRecorder = null;
        //this.squawk = new ParseFile(squawkFile.)
    }

    public class RecordButton extends ImageButton {
        // this needs to be changed to allow holding the button down, rather than toggling on/off
        OnTouchListener touche =
        };

        public RecordButton(ImageButton button) {
            super(button.getContext());
            setOnTouchListener(touche);
        }
    }

    class ValueComparator implements Comparator<String> {

        Map<String, Person> base;
        public ValueComparator(Map<String, Person> base) {
            this.base = base;
        }

        // Note: this comparator imposes orderings that are inconsistent with equals.
        public int compare(String a, String b) {
            Person personA = base.get(a);
            Person personB = base.get(b);
            int compCode;
            if ((personA.getMostRecent() != null) && (personB.getMostRecent() != null)){
                compCode = personA.getMostRecent().compareTo(personB.getMostRecent());
            }
            else{
                compCode = personA.getName().compareTo(personB.getName());
            }

            if ( compCode == 0){
                return 1;
            }
            else{
                return compCode;
            }
        }
    }

    public void squawking(){

    }
}

package us.squawkwith.android;

import android.graphics.Color;
import android.view.MotionEvent;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

import us.squawkwith.android.R;
import us.squawkwith.android.Squawk;
import us.squawkwith.android.Squawker;

/**
 * Created by nateparrott on 6/30/14.
 */
public class SquawkerCell extends LinearLayout {
    private TextView name, unreadCount;
    private void setup() {
        name = (TextView)findViewById(R.id.name);
        unreadCount = (TextView)findViewById(R.id.unreadCount);
        setBackgroundColor(Color.WHITE);
        setOnTouchListener(new OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent) {
                if (motionEvent.getAction() == MotionEvent.ACTION_DOWN) {
                    startAudioInteraction();
                } else if (motionEvent.getAction() == MotionEvent.ACTION_UP) {
                    endAudioInteraction();
                } else if (motionEvent.getAction() == MotionEvent.ACTION_CANCEL) {
                    endAudioInteraction();
                }
                return true;
            }
        });
    }

    public SquawkerCell(android.content.Context context, android.util.AttributeSet attrs) {
        super(context, attrs);
    }

    private Squawker squawker;
    public void setSquawker(Squawker sq) {
        if (name == null) {
            setup();
        }
        squawker = sq;
        updateUI();
    }

    public void updateUI() {
        name.setText(squawker.toString());
        name.setTextColor(squawker.isRegistered ? Color.BLACK : Color.GRAY);
        unreadCount.setText(Integer.toString(squawker.getUnreadCount()));
    }

    private ArrayList<AudioAction> audioActionQueue = new ArrayList<AudioAction>();
    public void startAudioInteraction() {
        setBackgroundColor(Color.RED);
        audioActionQueue.clear();
        List<Message> unread = squawker.getUnread();
        if (unread.size() > 0) {
            // playback:
            audioActionQueue.add(new AudioAction.Delay(0.1)); // so we don't start playing back/recording during scrolling
            for (Message msg : unread) {
                final AudioAction.Playback playback = new AudioAction.Playback(msg);
                playback.onListened = new Runnable() {
                    @Override
                    public void run() {
                        playback.message.markListened();
                        updateUI();
                    }
                };
                audioActionQueue.add(playback);
            }
            audioActionQueue.add(new AudioAction.PostPlaybackBeep());
        } else {
            audioActionQueue.add(new AudioAction.Delay(0.1)); // so we don't start playing back/recording during scrolling
            audioActionQueue.add(new AudioAction.PreRecordBeep());
            audioActionQueue.add(new AudioAction.Record(squawker));
        }
        runAudioActionQueue();
    }
    private void runAudioActionQueue() {
        if (audioActionQueue.size() > 0) {
            final AudioAction action = audioActionQueue.get(0);
            action.start(new AudioAction.EndHandler() {
                @Override
                public void run(boolean success) {
                    if (audioActionQueue.size() > 0 && audioActionQueue.get(0) == action) {
                        audioActionQueue.remove(0);
                    }
                    if (success) {
                        runAudioActionQueue();
                    } else {
                        audioActionQueue.clear();
                        endAudioInteraction();
                    }
                }
            });
        }
    }
    public void endAudioInteraction() {
        setBackgroundColor(Color.WHITE);
        if (audioActionQueue.size() > 0) {
            audioActionQueue.get(0).complete(false);
        }
        audioActionQueue.clear();
    }
}

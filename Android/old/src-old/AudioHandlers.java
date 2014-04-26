package com.parrott.squawk;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Environment;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.ImageButton;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

/**
 * Cowritten by Joe and Will
 * Contains a collection of useful audio recording and playback methods and classes
 */
public class AudioHandlers {
    private static final String LOG_TAG = "AudioHandler";
    private RecordButton mRecordButton = null;
    private MediaRecorder mRecorder = null;
    private String mFileName;
    private static MediaPlayer mPlayer = null;
    private int resId;

    private void onRecord(boolean start) {
        if (start) {
            startRecording();
        } else {
            stopRecording();
        }
    }


    public static void startPlaying(Context context, byte[] mp3SoundByteArray) {
        try {
            // create temp file that will hold byte array
            File temp = File.createTempFile("squawk", "mp4", context.getCacheDir());
            temp.deleteOnExit();
            FileOutputStream fos = new FileOutputStream(temp);
            fos.write(mp3SoundByteArray);
            fos.close();

            mPlayer = new MediaPlayer();

            FileInputStream fis = new FileInputStream(temp);
            mPlayer.setDataSource(fis.getFD());

            mPlayer.prepare();
            mPlayer.start();
        } catch (IOException ex) {
            String s = ex.toString();
            ex.printStackTrace();
        }
    }

    public static void stopPlaying() {
        mPlayer.release();
        mPlayer = null;
    }

    private void startRecording() {
        mRecorder = new MediaRecorder();
        mRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
        mRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
        mRecorder.setOutputFile(mFileName);
        mRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);

        try {
            mRecorder.prepare();
        } catch (IOException e) {
            Log.e(LOG_TAG, "prepare() failed in startRecording");
        }

        mRecorder.start();
    }

    private void stopRecording() {
        mRecorder.stop();
        mRecorder.release();
        mRecorder = null;
    }

    public class RecordButton extends ImageButton {
        boolean mStartRecording = true;
        // this needs to be changed to allow holding the button down, rather than toggling on/off
        OnTouchListener touche = new OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent) {
                onRecord(mStartRecording);
                if (mStartRecording) {
                    setImageResource(resId);
                } else {
                    setImageResource(resId);
                }
                mStartRecording = !mStartRecording;
                return true;
            }
        };

        public RecordButton(ImageButton button) {
            super(button.getContext());
            setOnTouchListener(touche);
        }
    }

}

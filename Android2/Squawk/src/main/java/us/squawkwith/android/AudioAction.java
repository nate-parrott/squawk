package us.squawkwith.android;

import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Handler;

import com.loopj.android.http.AsyncHttpResponseHandler;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.IOException;

/**
 * Created by nateparrott on 7/2/14.
 */
public class AudioAction {
    public void start(EndHandler endHandler) {
        endHandler.run(true);
    }
    public void complete(boolean isCancel) {

    }

    interface EndHandler {
        void run(boolean succcess);
    }

    public static class Delay extends AudioAction {
        private boolean cancelled = false;
        private double mTime = 0;
        Delay(double time) {
            mTime = time;
        }
        @Override
        public void start(final EndHandler endHandler) {
            Runnable runnable = new Runnable() {
                @Override
                public void run() {
                    if (!cancelled) {
                        endHandler.run(true);
                    }
                }
            };
            Handler handler = new Handler();
            handler.postDelayed(runnable, (long)(mTime * 1000));
        }
        @Override
        public void complete(boolean isCancel) {
            cancelled = true;
            super.complete(isCancel);
        }
    }

    public static class Playback extends AudioAction {
        public Message message;
        Playback(Message msg) {
            message = msg;
        }
        private MediaPlayer player;
        @Override
        public void start(final EndHandler endHandler) {
            mEndHandler = endHandler;
            player = new MediaPlayer();
            player.setOnErrorListener(new MediaPlayer.OnErrorListener() {
                @Override
                public boolean onError(MediaPlayer mediaPlayer, int i, int i2) {
                    done(false);
                    return true;
                }
            });
            player.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
                @Override
                public void onCompletion(MediaPlayer mediaPlayer) {
                    // mark as listened:
                    if (onListened != null) onListened.run();
                    done(true);
                }
            });
            //player.setDataSource(Squawk.createPlaybackUrl(message));
            Squawk.squawkDownloadCache.getFileWithId(message.getFilenameForCache(), Squawk.createPlaybackUrl(message), new Runnable() {
                @Override
                public void run() {
                    File f = Squawk.squawkDownloadCache.fileForId(message.getFilenameForCache());
                    if (f.exists()) {
                        try {
                            player.setDataSource(f.getAbsolutePath());
                            player.prepare();
                            player.start();
                        } catch (IOException e) {
                            done(false);
                        }
                    } else {
                        done(false);
                    }
                }
            });
        }
        public Runnable onListened;

        private EndHandler mEndHandler;
        private void done(boolean success) {
            if (player != null) {
                player.release();
                player = null;
            }
            mEndHandler.run(success);
        }

        @Override
        public void complete(boolean isCancel) {
            if (player != null) {
                player.stop();
                player.release();
                player = null;
            }
            super.complete(isCancel);
        }
    }

    public static class PostPlaybackBeep extends AudioAction {
        @Override
        public void start(EndHandler endHandler) {
            endHandler.run(true);
        }
    }

    public static class PreRecordBeep extends AudioAction {
        @Override
        public void start(EndHandler endHandler) {
            endHandler.run(true);
        }
    }

    public static class Record extends AudioAction {
        Record(Squawker recipient) {
            super();
            mRecipient = recipient;
        }
        private Squawker mRecipient;
        private MediaRecorder mMediaRecorder;
        private String mOutputPath;
        private EndHandler mEndHandler;
        private static int namePrefix = 0;
        @Override
        public void start(EndHandler endHandler) {
            mEndHandler = endHandler;
            try {
                mMediaRecorder = new MediaRecorder();
                mMediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
                mMediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
                mMediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);
                mOutputPath = File.createTempFile(String.format("squawk-%d", namePrefix++), "m4a").getPath();
                mMediaRecorder.setOutputFile(mOutputPath);
                mMediaRecorder.prepare();
                mMediaRecorder.start();
            } catch (IOException e) {
                done(false);
            }
        }
        @Override
        public void complete(boolean isCancel) {
            if (mMediaRecorder != null) {
                mMediaRecorder.stop();
                mMediaRecorder.release();
                mMediaRecorder = null;
            }
            if (isCancel) {
                deleteFile();
            } else {
                // send squawk:
                try {
                    JSONObject args = new JSONObject();
                    args.put("filename", "squawk.m4a");
                    args.put("recipients", new JSONArray(mRecipient.phoneNumbers));
                    Squawk.uploadMedia("/squawks/send", args, mOutputPath, "application/octet-stream", new AsyncHttpResponseHandler() {
                        @Override
                        public void onSuccess(int i, org.apache.http.Header[] headers, byte[] bytes) {
                            deleteFile();
                        }

                        @Override
                        public void onFailure(int i, org.apache.http.Header[] headers, byte[] bytes, java.lang.Throwable throwable) {
                            // TODO: alert user of failure
                            deleteFile();
                        }
                    });
                } catch (JSONException e) {
                    throw new RuntimeException();
                }
            }
            super.complete(isCancel);
        }
        private void done(boolean success) {
            mEndHandler.run(success);
            if (mMediaRecorder != null) {
                mMediaRecorder.release();
                mMediaRecorder = null;
            }
        }
        private void deleteFile() {
            File f = new File(mOutputPath);
            if (f.exists()) f.delete();
        }
    }
}

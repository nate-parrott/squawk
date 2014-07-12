package us.squawkwith.android;

import com.loopj.android.http.AsyncHttpResponseHandler;

import org.apache.http.Header;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOError;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * Created by nateparrott on 7/4/14.
 */
public class DownloadCache {
    DownloadCache(String namespace) {
        mNamespace = namespace;
        File dir = downloadCacheDir();
        if (!dir.exists()) dir.mkdir();
    }
    private String mNamespace = null;

    public File fileForId(String filename) { // may not exist
        return new File(downloadCacheDir(), filename);
    }

    public File downloadCacheDir() {
        File appCacheDir = SquawkApp.getAppContext().getCacheDir();
        return new File(appCacheDir, mNamespace);
    }

    public void getFileWithId(String filename, String url, final Runnable onDone) {
        final File f = fileForId(filename);
        if (f.exists()) {
            if (onDone != null) onDone.run();
        } else {
            Squawk.getClient().get(url, new AsyncHttpResponseHandler() {
                @Override
                public void onSuccess(int i, Header[] headers, byte[] bytes) {
                    // save file:
                    try {
                        SaveAtomic.saveAtomic(bytes, f);
                    } catch (IOException e) {
                        f.delete();
                    }
                    if (onDone != null) onDone.run();
                }

                @Override
                public void onFailure(int i, Header[] headers, byte[] bytes, Throwable throwable) {
                    if (onDone != null) onDone.run();
                }
            });
        }
    }

    private long kMaxCacheSize = 10 * 1000 * 1000; // 10 mb
    public boolean isCacheFull() {
        long spaceUsed = FileSize.fileSize(downloadCacheDir());
        long spaceLeft = Math.min(kMaxCacheSize - spaceUsed, downloadCacheDir().getUsableSpace());
        return spaceLeft < 0;
    }

    public void fillCacheWithIds(List<String> allIds, HashMap<String, String> urlsForIds) {
        // preloads everything with these ids and urls, while deleting everything else
        for (File f : downloadCacheDir().listFiles()) {
            if (!allIds.contains(f.getName())) {
                f.delete();
            }
        }
        for (String id : allIds) {
            if (isCacheFull()) break;
            getFileWithId(id, urlsForIds.get(id), null);
        }
    }

    public void preloadSquawks(List<Message> messages) {
        ArrayList<String> ids = new ArrayList<String>(messages.size());
        HashMap<String, String> urlsForIds = new HashMap<String, String>(messages.size());
        for (Message msg : messages) {
            ids.add(msg.getFilenameForCache());
            urlsForIds.put(msg.getFilenameForCache(), Squawk.createPlaybackUrl(msg));
        }
        fillCacheWithIds(ids, urlsForIds);
    }
}

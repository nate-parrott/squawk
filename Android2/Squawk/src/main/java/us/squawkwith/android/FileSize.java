package us.squawkwith.android;

import java.io.File;

/**
 * Created by nateparrott on 7/4/14.
 */
public class FileSize {
    public static long fileSize(File file) {
        if (file.isDirectory()) {
            long size = 0;
            for (File child : file.listFiles()) {
                size += fileSize(child);
            }
            return size;
        } else {
            return file.length();
        }
    }
}

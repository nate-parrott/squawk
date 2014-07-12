package us.squawkwith.android;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

/**
 * Created by nateparrott on 7/4/14.
 */
public class SaveAtomic {
    public static void saveAtomic(byte[] data, File path) throws IOException {
        File temp = File.createTempFile(path.getName(), null);
        BufferedOutputStream output = new BufferedOutputStream(new FileOutputStream(temp));
        output.write(data);
        output.flush();
        output.close();
        temp.renameTo(path);
    }
}

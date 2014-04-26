package com.parrott.squawk.squawk;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

import org.w3c.dom.Text;

import java.util.List;

/**
 * Created by Will on 3/24/2014.
 */
public class SquawkAdapter extends ArrayAdapter<SquawkThread> {

    private View view;
    private Context context;
    private List<SquawkThread> threads;
    public SquawkAdapter(Context context, List<SquawkThread> threads){
        super(context, R.layout.list_item, threads);
        this.threads = threads;
        this.context = context;
    }

    @Override
    public int getCount() {
        return 0;
    }

    @Override
    public long getItemId(int i) {
        return 0;
    }

    @Override
    public View getView(int i, View view, ViewGroup viewGroup) {
        View v = view;

        if (v == null) {
            LayoutInflater inflater = (LayoutInflater) getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            v = inflater.inflate(R.layout.list_item, null);
        }

        SquawkThread thread = threads.get(i);

        if(thread != null){
            TextView threadName = (TextView) v.findViewById(R.id.contact_name);
            TextView pendingSquawks = (TextView) v.findViewById(R.id.pending_squawks);

            threadName.setText(thread.getDisplayName());
            pendingSquawks.setText(thread.numMsgs());
        }

        return v;
    }
}

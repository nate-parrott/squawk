package us.squawkwith.android;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;

import java.util.ArrayList;

/**
 * Created by nateparrott on 6/30/14.
 */
public class SquawkArrayAdapter extends ArrayAdapter<Squawker> {
    SquawkArrayAdapter(Context context) {
        super(context, 0, new ArrayList<Squawker>());
        inflater = LayoutInflater.from(context);
    }
    private LayoutInflater inflater;
    @Override
    public View getView(int position, View view, ViewGroup parent) {
        Squawker squawker = getItem(position);
        if (squawker == null) {
            // insert divider:
            View v = new View(SquawkApp.getAppContext());
            v.setMinimumHeight(20);
            return v;
        }
        SquawkerCell cell;
        if (view instanceof SquawkerCell) {
            cell = (SquawkerCell) view;
        } else {
            cell = (SquawkerCell)inflater.inflate(R.layout.squawker_cell, parent, false);
        }
        cell.setSquawker(squawker);
        return cell;
    }
}

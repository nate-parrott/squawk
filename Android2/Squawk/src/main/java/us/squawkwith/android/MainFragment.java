package us.squawkwith.android;

import android.app.Activity;
import android.app.Fragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by nateparrott on 6/29/14.
 */
public class MainFragment extends Fragment {
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        return inflater.inflate(R.layout.main_fragment, container, false);
    }

    private SquawkArrayAdapter adapter = null;
    private SquawkerList squawkerList = null;

    public void onAppear() {
        refresh();
        GcmSetup setup = new GcmSetup();
        setup.activity = getActivity();
        setup.registerGcmIfNeeded();
    }

    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        squawkerList = new SquawkerList();

        adapter = new SquawkArrayAdapter(getActivity().getBaseContext());
        ListView listView = (ListView)getView().findViewById(R.id.listView);
        listView.setAdapter(adapter);
        squawkerList.callbacks.add(new SquawkerList.SquawkerListUpdatedCallback() {
            @Override
            public void onChange() {
                reloadList();
            };
        });

        refresh();
    }
    private void reloadList() {
        List<List<Squawker>> groups = squawkerList.mGroups;
        int count = 0;
        if (groups != null) {
            for (List<Squawker> group : groups) {
                count += group.size();
            }
            count += 2;
        }
        ArrayList<Squawker> squawkers = new ArrayList<Squawker>(count);
        if (groups != null) {
            for (List<Squawker> group : groups) {
                if (!squawkers.isEmpty()) {
                    // insert a divider, signalled by null:
                    squawkers.add(null);
                }
                squawkers.addAll(group);
            }
        }
        adapter.clear();
        adapter.addAll(squawkers);
    }

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        activity.getActionBar().show();
    }

    public void refresh() {
        squawkerList.refreshSquawks();
    }
}
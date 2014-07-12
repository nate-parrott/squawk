package us.squawkwith.android;

import android.app.Activity;
import android.app.Fragment;
import android.os.Bundle;
import android.os.Handler;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.loopj.android.http.JsonHttpResponseHandler;

import org.json.JSONException;
import org.json.JSONObject;

import java.security.SecureRandom;
import java.util.Random;
import java.util.TimerTask;

/**
 * Created by nateparrott on 6/29/14.
 */
public class LoginFragment extends Fragment {
    public enum State {
        None,
        ShowingSmsPrompt,
        TryingToLogin
    }

    private State state = State.None;
    void setState(State newState) {
        state = newState;

        Button getStarted = (Button)getView().findViewById(R.id.getStarted);
        Button done = (Button)getView().findViewById(R.id.done);
        TextView messagePrompt = (TextView)getView().findViewById(R.id.messagePrompt);
        TextView error = (TextView)getView().findViewById(R.id.error);
        ProgressBar loader = (ProgressBar)getView().findViewById(R.id.loader);

        getStarted.setVisibility(state == State.None? View.VISIBLE : View.INVISIBLE);
        if (state != State.None) {
            error.setText("");
        }

        done.setVisibility(state == state.ShowingSmsPrompt ? View.VISIBLE : View.INVISIBLE);
        messagePrompt.setVisibility(state == state.ShowingSmsPrompt ? View.VISIBLE : View.INVISIBLE);

        loader.setVisibility(state == state.TryingToLogin? View.VISIBLE : View.INVISIBLE);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.login_fragment, container, false);
        Button getStarted = (Button)view.findViewById(R.id.getStarted);
        getStarted.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                promptSendSms();
            }
        });
        Button done = (Button)view.findViewById(R.id.done);
        done.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                doneSendingSms();
            }
        });
        return view;
    }

    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setState(state.None);
    }

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        activity.getActionBar().hide();
    }

    public String kVerificationPhoneNumber = "646-576-7688";

    public void promptSendSms() {
        if (secret == null) {
            generateSecret();
        }
        TextView messagePrompt = (TextView)getView().findViewById(R.id.messagePrompt);
        String message = "Text \"" + secret + "\" to " + kVerificationPhoneNumber + " from your phone so we can verify your phone number.";
        messagePrompt.setText(message);
        setState(state.ShowingSmsPrompt);
    }
    private String secret = null;
    private void generateSecret() {
        SecureRandom r = new SecureRandom();
        String characters = "abcdefghijklmnopqrstuvwxyz0123456789";
        int groups = 1;//3;
        int groupLength = 3;
        StringBuilder b = new StringBuilder();
        for (int group=0; group<groups; group++) {
            for (int i=0; i<groupLength; i++) {
                b.append(characters.charAt(r.nextInt(characters.length())));
            }
            if (group+1 < groups) {
                b.append("-");
            }
        }
        secret = b.toString();
    }

    public static double kDelayBetweenLoginAttempts = 0.8;
    public static int kMaxLoginAttempts = 5;
    private int currentLoginAttempt = 0;
    public void doneSendingSms() {
        setState(state.TryingToLogin);
        currentLoginAttempt = 0;
        tryLogin();
    }

    private void tryLogin() {
        JSONObject params = new JSONObject();
        try {
            params.putOpt("secret", secret);
        } catch (JSONException e) {}
        Squawk.get("/make_token", params, new JsonHttpResponseHandler() {
            @Override
            public void onSuccess(int statusCode, org.apache.http.Header[] headers, org.json.JSONObject response) {
                boolean success = response.optBoolean("success");
                if (success) {
                    final String token = response.optString("token");
                    final String phone = response.optString("phone");
                    // do /notify_friends:
                    JSONObject notifyFriendsParams = new JSONObject();
                    try {
                        notifyFriendsParams.put("token", token);
                    } catch (JSONException e) {}
                    Squawk.get("/notify_friends", notifyFriendsParams, new JsonHttpResponseHandler() {
                        @Override
                        public void onSuccess(int statusCode, org.apache.http.Header[] headers, org.json.JSONObject response) {
                            // we did it!
                            Squawk.preferences().edit()
                                    .putString(Squawk.kLoginTokenSettingsKey, token)
                                    .putString(Squawk.kUserPhoneSettingsKey, phone)
                                    .apply();
                            MainActivity activity = (MainActivity)getActivity();
                            activity.updateCurrentFragment();
                        }
                        @Override
                        public void onFailure(int statusCode, org.apache.http.Header[] headers, java.lang.Throwable throwable, org.json.JSONObject errorResponse) {
                            showError("Couldn't connect to the Internet");
                        }
                    });
                } else {
                    currentLoginAttempt++;
                    if (currentLoginAttempt >= kMaxLoginAttempts) {
                        showError("We didn't receive your text.");
                    } else {
                        // wait a couple seconds and try again:
                        Runnable runnable = new Runnable() {
                            @Override
                            public void run() {
                                tryLogin();
                            }
                        };
                        Handler handler = new Handler();
                        handler.postDelayed(runnable, (long)(kDelayBetweenLoginAttempts * 1000));
                    }
                }
            }
            @Override
            public void onFailure(int statusCode, org.apache.http.Header[] headers, java.lang.Throwable throwable, org.json.JSONObject errorResponse) {
                   showError("Couldn't connect to the Internet");
            }
        });
    }

    private void showError(String msg) {
        TextView error = (TextView)getView().findViewById(R.id.error);
        error.setText(msg);
        setState(state.None);
    }
}

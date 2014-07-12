import secret
import requests
import json
import util

def send_push(push):
    headers = {"Content-Type": "application/json", "Authorization": "key="+secret.GCM_API_KEY}
    data = {
        "alert": push.alert,
        "play_sound": push.sound != None
    }
    for k, v in push.data.iteritems():
        data[k] = v
    
    payload = {
        "registration_ids": [push.token],
        "data": data
    }
    
    result = requests.post("https://android.googleapis.com/gcm/send", headers=headers, data=json.dumps(payload))
    if result.status_code != 200:
        util.log("GCM responded with status code %i" % result.status_code)
        util.log("Response is:")
        util.log(result.text)

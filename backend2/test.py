import requests, json, copy, urllib, random

address = 'http://localhost:5000'
phone = '12223334444'

token = None

def url(endpoint, args):
    args = copy.copy(args)
    if token: args['token'] = token
    return address+endpoint+'?args='+urllib.quote(json.dumps(args))

def assert_okay(resp):
    if resp.status_code != 200:
        print "Request to '%s' returned %i"%(resp.url, resp.status_code)
        print resp.text
        print ""
        quit()

def assert_success(resp):
    assert_okay(resp)
    assert resp.json()['success']

secret = 'secret_'+str(random.random())
resp = requests.get(address+'/verify', params={'From': phone, 'Body': "abc "+secret})
assert_okay(resp)

resp = requests.get(url('/make_token', {"secret": secret}))
assert_okay(resp)
token = resp.json()['token']

assert_okay(requests.get(url('/notify_friends', {})))

resp = requests.get(url('/which_users_not_signed_up', {"phones": ["19999990000", "17185947958"]}))
assert_okay(resp)
assert tuple(resp.json()['users_not_signed_up']) == ('19999990000',)

resp = requests.post(url('/register_contacts', {}), data=json.dumps({'contact_phones': ['17185947958'], 'contact_names': ['Nate']}))
assert_okay(resp)

resp = requests.get(url('/check_contacts_signed_up', {}))
assert_okay(resp)
assert '17185947958' in resp.json()['phones']

resp = requests.post(url('/squawks/send', {"recipients": [phone]}), data="NULL")
assert_success(resp)

resp = requests.get(url('/squawks/recent', {}))
squawk = resp.json()['results'][0]
assert squawk['sender']==phone and squawk['listened']==False
data = requests.get(url('/squawks/serve', {"id": squawk['_id']})).text
assert data=='NULL'

resp = requests.post(url('/squawks/listened', {"id": squawk['_id']}))
assert_okay(resp)
resp = requests.get(url('/squawks/recent', {}))
squawk = resp.json()['results'][0]
assert squawk['sender']==phone and squawk['listened']==True

assert_okay(requests.post(url('/send_checkmark', {"recipients": [phone]})))

prefs = {"test_pref": [1,2,3]}
assert_okay(requests.post(url('/update_prefs', {}), data=json.dumps(prefs), headers={"Content-Type": "application/json"}))

resp = requests.post(url('/squawks/send', {"recipients": ["01010101010"]}), data="NULL")
assert_success(resp)

print 'Done.'

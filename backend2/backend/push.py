from apns import APNs, Payload
from backend import app, db
import flask
import util
import json
import squawk
import pymongo
import gcm

def badge_for_user(phone):
	count = len(filter(lambda s: s['listened']==False, squawk.recent_squawks(phone)))
	return count if count else None

class Push(object):
	def __init__(self, phone, type, token, alert=None, sound=None, data={}):
		self.phone = phone
		self.type = type
		self.token = token
		self.alert = alert
		self.data = data # custom json
		self.sound = sound
		self.content_available = False

	def ios_payload(self):
		return Payload(alert=self.alert, custom=self.data, sound=self.sound, content_available=self.content_available, badge=badge_for_user(self.phone))

def should_send_push_to_user_for_thread(user, thread_identifier):
	if user == None:
		return False
	recents = list(db.messages.find({"recipient": user}, sort=[('date', pymongo.DESCENDING)], limit=squawk.NUM_RECENT_SQUAWKS))
	num_unread_from_this_thread = len([msg for msg in recents if msg['listened']==False and msg.get('thread_identifier', None)==thread_identifier])
	NUM_UNREAD_TO_NOT_SEND_PUSH = 2
	return num_unread_from_this_thread < NUM_UNREAD_TO_NOT_SEND_PUSH+1 # including current!

def send_pushes(pushes):
	key = 'secret/Squawk2Key-nopassword.pem'
	apns_production = None
	apns_dev = None
	util.log("sending pushes")
	for push in pushes:
		if push.type=='ios':
			if not apns_production:
				apns_production = APNs(use_sandbox=False, cert_file='secret/Squawk2Cert-production.pem', key_file=key)
			apns_production.gateway_server.send_notification(push.token, push.ios_payload())
		elif push.type=='ios-dev':
			if not apns_dev:
				apns_dev = APNs(use_sandbox=True, cert_file='secret/Squawk2Cert-dev.pem', key_file=key)
			apns_dev.gateway_server.send_notification(push.token, push.ios_payload())
		elif push.type=='android':
			gcm.send_push(push)
	return "okay"

@app.route('/register_push_token')
def register_push_token():
	token = util.args()['push_token']
	platform_type = util.args()['type']
	entry = db.push_tokens.find_one({"token": token, "type": platform_type})
	if entry == None:
		entry = {"token": token, "type": platform_type}
	entry['phone'] = util.myphone()
	db.push_tokens.save(entry)
	return json.dumps({"success": True})

@app.route('/unregister_push_token', methods=["GET", "POST"])
def unregister_push_token():
	token = util.args()['push_token']
	platform_type = util.args()['type']
	db.push_tokens.remove({"token": token, "type": platform_type})

@app.route('/send_test_push')
def test_push():
	token = flask.request.args.get('token')
	type = flask.request.args.get('platform')
	send_pushes([Push('', type, token, alert="Hello, world")])
	return "okay"

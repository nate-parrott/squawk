from backend import app, db
import flask
from flask import request
import util
import json
import push
import squawk
import robot
import localized

@app.route('/notify_friends')
def notify():
	pushes = []
	me = util.myphone()
	user = db.users.find_one({"phone": me})
	if not user.get('notified_friends_yet', False):
		user['notified_friends_yet'] = True
		db.users.save(user)

		matching_listings = db.contact_listings.find({"contact_phones": {"$in": [me]}})
		for listing in matching_listings:
			recipient = listing['phone']
			name = squawk.name_for_user(me, recipient)
			user_receiving_notif = db.users.find_one({"phone": recipient})
			alert = localized.localized_message(localized.contact_joined_squawk, user_receiving_notif)%(name)
			for token_info in db.push_tokens.find({"phone": recipient}):
				#	def __init__(self, phone, type, token, alert=None, sound=None, data=None):
				pushes.append(push.Push(recipient, token_info['type'], token_info['token'], alert=alert, data={"type": "friend_joined", "phone": me}))
				pushes[-1].content_available = True
		push.send_pushes(pushes)
		robot.send_robot_message(me)
	return json.dumps({"success": True})

@app.route('/register_contacts', methods=['POST'])
def register_contacts():
	entry = db.contact_listings.find_one({"phone": util.myphone()})
	if entry==None:
		entry = {"phone": util.myphone(), "contact_phones": [], "contact_names": []}
	payload = json.loads(flask.request.data)
	entry['contact_phones'] += payload['contact_phones']
	entry['contact_names'] += payload['contact_names']
	db.contact_listings.save(entry)

	newly_registered_phones_on_squawk = list(map(lambda x: x['phone'], db.users.find({"phone": {"$in": payload['contact_phones']}})))
	return json.dumps({"success": "okay", "phones_on_squawk": newly_registered_phones_on_squawk})

@app.route('/check_contacts_signed_up')
def check_contacts_signed_up():
	listing = db.contact_listings.find_one({"phone": util.myphone()})
	if listing:
		friends = db.users.find({"phone": {"$in": listing['contact_phones']}})
		return json.dumps({"success": "true", "phones": [friend['phone'] for friend in friends]})
	else:
		return json.dumps({"success": "false"})

@app.route('/which_users_not_signed_up')
def which_users_not_signed_up():
	users_signed_up = map(lambda user: user['phone'], db.users.find({"phone": {"$in": util.args()['phones']}}))
	users_not_signed_up = [phone for phone in util.args()['phones'] if phone not in users_signed_up]
	return json.dumps({"success": True, "users_not_signed_up": users_not_signed_up})

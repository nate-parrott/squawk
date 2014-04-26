NUM_RECENT_SQUAWKS = 40

from backend import app, db
import flask
from flask import request
from util import normalize_phone, timestamp, myphone, args
from user import phone_for_token
import json
import datetime
import pymongo
from bson.objectid import ObjectId
import bson
from flask import Response
from apns import Payload
import push
import util
import s3
import robot

def name_for_user(user, receiver):
	if user==robot.ROBOT_PHONE:
		return 'Squawk Robot'
	listing = db.contact_listings.find_one({"phone": receiver})
	if listing and user in listing['contact_phones']:
		return listing['contact_names'][listing['contact_phones'].index(user)]
	else:
		return user

def push_notifs_for_message(sender, recipient, squawk_id, thread_identifier):
	name = name_for_user(sender, recipient)
	sound = alert = None
	if push.should_send_push_to_user_for_thread(recipient, thread_identifier):
		sound = "squawk.caf"
		alert = "%s sent you a Squawk."%(name) if sender!=recipient else None
	for token_info in db.push_tokens.find({"phone": recipient}):
		notif = push.Push(recipient, token_info['type'], token_info['token'], alert, sound, {"type": "message", "squawk_id": str(squawk_id)})
		if recipient!=sender: notif.content_available = True
		yield notif

def deliver_squawk(recipients, sender, audio_url, duration=-1):
	pushes = []

	thread_members = list(set(map(normalize_phone, recipients) + [sender]))
	thread_identifier = ','.join(sorted(thread_members))
	for phone in thread_members:
		if phone == sender and len(thread_members)>1:
			continue
		squawk_id = db.messages.save({
			"sender": sender, 
			"thread_members": thread_members, 
			"recipient": phone,
			"date": datetime.datetime.now(), 
			"listened": False, 
			"audio_url": audio_url, 
			"duration": duration,
			"thread_identifier": thread_identifier})
		pushes += list(push_notifs_for_message(sender, phone, squawk_id, thread_identifier))
	
	push.send_pushes(pushes)
	
	return True

@app.route('/squawks/send', methods=['POST'])
def send_squawk():
	sender = myphone()
	util.log("sent squawk from %s to %s"%(sender, ' '.join(args()['recipients'])))
	if args()['recipients'] == [robot.ROBOT_PHONE]:
		robot.send_robot_message(sender)
	if sender:
		duration = args().get('duration', -1)
		data = flask.request.data
		filename = s3.generate_unique_filename_with_ext('m4a')
		audio_url = s3.upload_file(filename, data)
		success = deliver_squawk(args()['recipients'], sender, audio_url, duration)
		return json.dumps({"success": success})
	else:
		return json.dumps({"success": False, "error": "bad_token"})

def squawk_to_json(squawk):
	return {
		'recipient': squawk['recipient'], 
		'thread_members': squawk['thread_members'], 
		'sender': squawk['sender'], 
		'date': timestamp(squawk['date']), 
		'_id': str(squawk['_id']), 
		'listened': squawk['listened'],
		'thread_identifier': squawk.get('thread_identifier', "")}

def recent_squawks(phone):
    return list(db.messages.find({"recipient": phone}, sort=[('date', pymongo.DESCENDING)], limit=NUM_RECENT_SQUAWKS))

@app.route('/squawks/recent', methods=['GET'])
def get_squawks():
	sender = myphone()
	if sender:
		results = map(squawk_to_json, recent_squawks(sender))
		return json.dumps({"success": True, "results": results})
	else:
		return json.dumps({"success": False, "error": "bad_token"})

@app.route('/squawks/listened', methods=['POST'])
def listened():
	id = ObjectId(args()['id'])
	msg = db.messages.find_one({'_id': id})
	if msg:
		msg['listened'] = True
		db.messages.save(msg)
	return json.dumps({"success": msg!=None})

@app.route('/squawks/serve')
def serve_squawk():
	phone = myphone()
	id = args()['id']
	msg = db.messages.find_one({"recipient": phone, "_id": bson.objectid.ObjectId(id)})
	if msg:
		return flask.redirect(msg.get('audio_url', ''))
	else:
		flask.abort(403)


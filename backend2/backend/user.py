from backend import app, db
from util import normalize_phone, args, log
import flask
from flask import request
from os import urandom
from base64 import b64encode
import json
import datetime

@app.route('/verify', methods=['GET', 'POST'])
def verify():
	# called by twilio (trusted) when a verification text comes in 
	# TODO: make sure this is actually coming from Twilio
	log("REQUEST ARGS: {}".format(request.args))
	phone = normalize_phone(request.args.get('From'))
	secret = request.args.get('Body').split(' ')[-1].lower()
	user = db.users.find_one({'phone': phone})
	if not user: user = {"date": datetime.datetime.now()}
	user['phone'] = phone
	user['secret'] = secret
	db.users.save(user)

	twiml_do_nothing = """<?xml version="1.0" encoding="UTF-8"?>
<Response>
</Response>"""
	return flask.Response(twiml_do_nothing, mimetype='text/xml')

def generate_token(phone):
	return b64encode(urandom(16)+str(phone))

@app.route('/make_token', methods=['GET'])
def make_token():
	secret = args()['secret']
	matching_user = db.users.find_one({'secret': secret})
	if matching_user:
		phone = matching_user['phone']
		token = generate_token(phone)
		db.tokens.save({"phone": phone, "token": token})
		return json.dumps({"success": True, "token": token, "phone": phone})
	else:
		return json.dumps({"success": False, "error": "bad_login"})

def phone_for_token(token):
	entry = db.tokens.find_one({"token": token})
	return entry['phone'] if entry else None


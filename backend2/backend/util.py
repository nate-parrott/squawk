import flask
import json
import datetime
import calendar
import sys

def normalize_phone(phone):
	digits = '0123456789'
	phone = ''.join([c for c in phone if c in digits])
	if len(phone)==10:
		phone = '1' + phone
	return phone

def args():
	return json.loads(flask.request.args.get('args'))

def myphone():
	import user
	return user.phone_for_token(args()['token'])

def timestamp(time):
	return calendar.timegm(time.utctimetuple())

def log(txt):
	print txt
	sys.stdout.flush()

def islocal():
    return 'localhost' in flask.request.host

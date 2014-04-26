from backend import app, db
import flask
import squawk
import random

ROBOT_PHONE = '00000000000'

def send_robot_message(phone):
	user = db.users.find_one({"phone": phone})
	if not user:
		return False
	num_intro_messages = 2
	num_random_messages = 13
	next_robot_message = user.get('next_robot_message', 'intro-0')

	audio_url = "https://s3.amazonaws.com/squawk2/%s.m4a"%next_robot_message

	msg_type, idx = next_robot_message.split('-')
	idx = int(idx)
	if msg_type=='intro' and idx+1<num_intro_messages:
		user['next_robot_message'] = 'intro-'+str(idx+1)
	else:
		next_idx = idx
		while next_idx==idx:
			next_idx = random.randint(0, num_random_messages-1)
		user['next_robot_message'] = 'random-'+str(next_idx)

	db.users.save(user)
	if not squawk.deliver_squawk([phone], ROBOT_PHONE, audio_url):
		return False
	return True


@app.route('/send_robot_msg')
def send_robot_msg_endpoint():
	to = flask.request.args.get('to')
	ok = send_robot_message(to)
	return "okay" if ok else "nokay"

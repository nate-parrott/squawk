#!/usr/bin/env python
# -*- coding: utf-8 -*-

import flask
from backend import app, db
import util
import squawk
import push
import json

@app.route('/send_checkmark', methods=['GET', 'POST'])
def send_checkmark():
	# calling this endpoint with GET is deprecated!
	recipients = util.args()['recipients'] if 'recipients' in util.args() else [util.args()['recipient']]
	sender = util.myphone()
	thread_identifier = util.args().get('thread_identifier', '')
	pushes = []
	for recipient in set(recipients):
		if not push.should_send_push_to_user_for_thread(recipient, thread_identifier):
			continue
		name = squawk.name_for_user(sender, recipient)
		message = u"%s: ✓"%(name)
		for token_info in db.push_tokens.find({"phone": recipient}):
			pushes.append(push.Push(recipient, token_info['type'], token_info['token'], message, "", {"type": "checkmark"}))
	push.send_pushes(pushes)
	return json.dumps({"success": True})

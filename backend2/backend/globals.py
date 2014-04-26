from backend import app, db
import flask
import json

@app.route('/globals.json')
def globals():
	payload = {"title": "this is Squawk", "messages": [{"min_version": 6, "max_version": 7, "show_url": "http://news.ycombinator.com"}]}
	return json.dumps(payload)

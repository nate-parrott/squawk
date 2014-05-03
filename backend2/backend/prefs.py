from backend import app, db
import flask
import util
import json

@app.route('/update_prefs', methods=['POST'])
def update_prefs():
    phone = util.myphone()
    if phone:
        prefs = flask.request.json
        user = db.users.find_one({"phone": phone})
        user['prefs'] = prefs
        db.users.save(user)
        return json.dumps({"success": True})
    else:
        return json.dumps({"success": False})

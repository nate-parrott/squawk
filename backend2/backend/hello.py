from backend import app

@app.route('/hello')
def hello():
	return "Hello, world!"

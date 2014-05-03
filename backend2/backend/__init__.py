# to deploy, cd into the main Squawk repo and run:
# git subtree push --prefix backend2 heroku master

from flask import Flask
import pymongo
import os

import newrelic.agent
newrelic.agent.initialize('newrelic.ini')

app = Flask(__name__)
debug = True
if 'MONGOHQ_URL' in os.environ:
	debug = False
	db = pymongo.MongoClient(os.environ['MONGOHQ_URL']).app22686072
else:
	db = pymongo.MongoClient().squawk

app.debug = debug

import hello
import user
import squawk
import friends
import push
import checkmark
import globals
import robot
import prefs

import os

from flask import Flask, g
from flask.ext.bcrypt import Bcrypt

from peewee import MySQLDatabase, SqliteDatabase

# XXX do we need gevent and peewee? not sure, but keep them; it's a good base
# for future development
from gevent import monkey
monkey.patch_all()

project_path = os.path.abspath(os.path.dirname(__file__))
app_name = os.path.basename(project_path)
print "Project path:", project_path
print "App name:", app_name
app = Flask(app_name)

if os.getenv('FLASK_TESTING', False):
    app.testing = True
if os.getenv('FLASK_DEBUG', False):
    app.debug = True

# setup bcrypt (needed by the auth module)
bcrypt = Bcrypt(app)

# read secret key from env, if not present, use a default one
app.secret_key = os.getenv('AWTAR_SECRET', '').decode('string-escape')
if app.secret_key == '' and app.debug:
    app.secret_key = 'wOY\xcc*F\x10eA\x1ew\x18}\xcd[\xc2\x86\xc8\xb1<e])\xc5'

# database
if app.testing: # testing mode (e.g. unit tests, etc)
    # db_uri = 'sqlite:///:memory:'
    print "Using SQLite's in-memory db"
    db = SqliteDatabase(':memory:', threadlocals=True)
else:
    # local dev database
    # db_uri = 'sqlite:///{project_path}/{app_name}_dev.db'.format(project_path=project_path, app_name=app_name)
    print "Using local mysql db"
    db = MySQLDatabase(app_name, user='root', threadlocals=True)

def db_connect():
    if db.is_closed():
        db.connect()

def db_close():
    if not db.is_closed():
        db.close()

if app.testing:
    # calling db.connect() on an in-memory sqlite database resets everything!
    def db_connect(): pass

# connect to the db for every request
@app.before_request
def ensure_db_connected():
    db_connect()

@app.after_request
def clear_connection_resource(request):
    db_close()
    return request

@app.after_request
def frame_buster(response):
    response.headers['X-Frame-Options'] = 'DENY'
    return response

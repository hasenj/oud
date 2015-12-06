import os

from flask import Flask, g
from flask.ext.bcrypt import Bcrypt

project_path = os.path.abspath(os.path.dirname(__file__))
app_name = os.path.basename(project_path)
print "Project path:", project_path
print "App name:", app_name
app = Flask(app_name)

if os.getenv('FLASK_TESTING', False):
    app.testing = True
if os.getenv('FLASK_DEBUG', False):
    app.debug = True

# read secret key from env, if not present, use a default one
app.secret_key = os.getenv('AWTAR_SECRET', '').decode('string-escape')
if app.secret_key == '' and app.debug:
    app.secret_key = 'wOY\xcc*F\x10eA\x1ew\x18}\xcd[\xc2\x86\xc8\xb1<e])\xc5'

@app.after_request
def frame_buster(response):
    response.headers['X-Frame-Options'] = 'DENY'
    return response

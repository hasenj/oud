import os

from app import app

import views

from werkzeug.serving import run_with_reloader
from socketio.server import SocketIOServer

def run_gevent_server():
    port = int(os.getenv("PORT", "9040"))
    # XXX we're not using socket.io ...
    SocketIOServer(('', port), app, resource="socket.io", policy_server=False).serve_forever()

def main():
    run_with_reloader(run_gevent_server)

if __name__ == "__main__":
    main()

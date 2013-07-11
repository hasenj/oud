PORT=9040
# Prepare virtual env and install/update requirements
if [ ! -d venv ]
then
    virtualenv venv --distribute
fi
source venv/bin/activate
pip -q install -r requirements.txt
# build client files ..
make -s

# kill any process listening on our port before starting our server
pid=`lsof -i tcp:$PORT -s tcp:listen -t`
if [ $pid ]
then
    kill -9 $pid
    sleep 1 # wait
fi
# finally, run the server
python main.py

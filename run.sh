PORT=9040
# kill any process listening on our port before starting our server
pid=`lsof -i tcp:$PORT -s tcp:listen -t`
if [ $pid ]
then
    kill -9 $pid
    sleep 1 # wait
fi
# run the server
source venv/bin/activate
python main.py

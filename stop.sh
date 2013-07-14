# kill the process listening on our port
PORT=9040
pid=`lsof -i tcp:$PORT -s tcp:listen -t`
if [ $pid ]
then
    kill -9 $pid
    sleep 1 # wait
fi

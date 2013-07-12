# Prepare virtual env and install/update requirements
if [ ! -d venv ]
then
    virtualenv venv --distribute
fi
source venv/bin/activate
pip install -r requirements.txt
# build client files ..
make

# Prepare virtual env and install/update requirements
if [ ! -d venv ]
then
    virtualenv venv --distribute
fi
venv/bin/easy_install -U distribute # not sure why but needed for ubuntu server
venv/bin/pip install -r requirements.txt
# build client files ..
make

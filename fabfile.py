import os.path
import time;
from fabric.api import *

env.hosts = [os.getenv('AWTAR_DEPLOY_HOST')]

deploy_dir = "deploy/awtar.me"

@task
def deploy():
    ts = str(int(time.time()))
    with lcd("out"):
        local("zip --quiet --recurse-paths ../awtar_deploy.zip .")
    run("mkdir -p {0}".format(deploy_dir))
    with cd(deploy_dir):
        arch = "{ts}.zip".format(ts=ts)
        put("awtar_deploy.zip", arch)
        local("rm awtar_deploy.zip")
        run("unzip {0} -d {1}".format(arch, ts))
        run("rm {0}".format(arch))
        run("ln -Tsf {0} current".format(ts))
    print "Deployed {0}".format(ts)

# XXX Need some task to configure nginx or something ...?

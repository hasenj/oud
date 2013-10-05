import os.path
from time import sleep
from fabric.api import *

env.hosts = [os.getenv('AWTAR_DEPLOY_HOST')]

def rev_hash(rev):
    return local("git rev-parse {0}".format(rev), capture=True)

def git_archive(hash):
    archive_path = "/tmp/{hash}.zip".format(hash=hash)
    local("git archive {hash} --format zip -9 --output {output_path}".format(hash=hash, output_path=archive_path))
    return archive_path

deploy_dir = "deploy/awtar.me"
project_name = "awtar"

@task
def deploy(rev="HEAD"):
    hash = rev_hash(rev)
    local_archive = git_archive(hash)
    upload_dir = os.path.join(deploy_dir, hash, project_name)
    run("mkdir -p {0}".format(upload_dir))
    with cd(upload_dir):
        arch = "{hash}.zip".format(hash=hash)
        put(local_archive, arch)
        run("unzip {0}".format(arch))
        run("./prepare.sh")
        run('./start.sh')
        sleep(1)
        # now that the server is running, set the symlink for serving the static data ..
        with cd("../.."):
            run("ln -Tsf {0}/awtar current".format(hash))
    print "Deployed commit {0}".format(hash)

@task
def start():
    current_version = os.path.join(deploy_dir, "current")
    with cd(current_version):
        run("./start.sh")

# XXX Need some task to configure nginx or something ...?

from fabric.api import *

def test():
    run("ls")
    with cd("deploy"):
        run("ls")
    run("echo done")

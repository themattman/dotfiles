#!/usr/bin/env python
#
# Purpose:
# Created:

__author__    = "Matthew Kneiser"
__copyright__ = ""
__status__    = "Development"

import argparse
import logging
import os
import signal
import sys

### UTILITY FUNCTIONS ###
def get_ioloop_instance(logger):
    try:
        from zmq.eventloop import ioloop
        ioloop.install()
    except ImportError as e:
        ERROR_MSG = """
        Could not import zmq and/or tornado. Do you have it installed?
        LINUX: Try sudo pip install pyzmq
        LINUX: Try sudo pip install tornado
        LINUX: If pip doesn't exist try sudo apt-get install python-pip first
        """
        print ERROR_MSG
        logger.exception(ERROR_MSG)
        main_ioloop = ioloop.IOLoop.instance()
        #main_ioloop.start()
        return main_ioloop

def receive_signal(signum, stack):
    """Handle kill signals to the Python wrapper
    """
    signals_to_catch = [
        signal.SIGHUP,
        signal.SIGINT,
        signal.SIGQUIT,
        signal.SIGABRT,
        signal.SIGTERM
    ]
    if signum in signals_to_catch:
        # Die gracefully if asked to die
        print '\nCaught signal %s.' % (str(signum))
        sys.stdout.flush()
        sys.exit(1)

def setup_sig_handler():
    """Setup signal handlers to catch signals from dying child processes
    """
    uncatchable = ['SIG_DFL', 'SIGSTOP', 'SIGKILL']
    for i in [x for x in dir(signal) if x.startswith("SIG")]:
        if i not in uncatchable:
            signum = getattr(signal, i)
            signal.signal(signum, receive_signal)
### END UTILITY FUNCTIONS ###

### MAIN ###
def usage():
    print "Usage: ./template.py [-h]"

def main(args):
    logger = logging.getLogger(__name__)
    if args.help is not None:
        usage()
    sys.exit(0)

if __name__ == "__main__":
    try:
        parser = argparse.ArgumentParser(description='Play with python. Unserious work being done here.')
        parser.add_argument('-h', '--help', action='store_true')
        parser.add_argument("-l", "--logging-level", default="ERROR",
                            dest="logging_level",
                            choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
                            help="log message at or above this level will be emitted. \
                            Default: %(default)s")
        main(parser.parse_args())
    except KeyboardInterrupt:
        print "Ctrl-C detected. Quitting."
        sys.exit(1)
### END MAIN ###

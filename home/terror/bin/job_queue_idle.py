#!/usr/bin/env python
# -*- coding: UTF-8 -*-
#---------------------------
# Name: job_queue_idle.py
# Purpose
#   This python script checks to see if a job queue server is idle.
#   If no jobs are listed for, or can be run by, the current host, the
#   script will return 0, indicating mythjobqueue can be safely
#   terminated, allowing the master backend to shut itself down.
#   Otherwise, the script returns the total number of jobs capable of
#   being run by the current host.
#
#   It can also be run in daemon mode, in which case it backgrounds
#   itself, and proceeds to automatically manage the start and stop of
#   mythjobqueue as needed.
#---------------------------

from MythTV import MythDB, Job, MythDBError
from optparse import OptionParser
import subprocess
import time
import sys
import os

DB = None
LEVEL = None

class VERBOSE_LEVEL:
    DEFAULT = 0
    VERBOSE = 1
    DEBUG   = 2

def verbose(level, *messages):
    if (LEVEL >= level):
        print ''.join(map(str,messages))

def get_pid():
    pid = None
    ps = subprocess.Popen(['ps', 'ax'], stdout=-1)
    ps.wait()
    for line in ps.stdout.read().split('\n'):
        if 'mythjobqueue' in line:
            pid = int(line.strip().split(' ')[0])
            break
    return pid

def run_jobqueue():
    if subprocess.call(['mythjobqueue', '--daemon']):
        verbose(VERBOSE_LEVEL.DEFAULT, "Daemon failed to run mythjobqueue")
        sys.exit(1)
    return get_pid()

def term_jobqueue(pid):
    subprocess.call(['kill', str(pid)])

def get_job_count():
    currenthost = DB.gethostname()
    verbose(VERBOSE_LEVEL.DEBUG, 'Checking job queue status for host ',
            currenthost)
    jobs = list(Job.getAllEntries(db=DB))
    jobCount=0
    if len(jobs) == 0:
        verbose(VERBOSE_LEVEL.VERBOSE, 'No jobs found')
    else:
        for job in jobs:
            if (len(job.hostname) == 0):
                verbose(VERBOSE_LEVEL.VERBOSE, 'Job ',job.id,
                        'available for processing on any host (',
                        job.comment,')')
                jobCount+=1
            elif ((job.hostname != currenthost)):
                verbose(VERBOSE_LEVEL.DEBUG, 'Job ',job.id,' claimed by ',
                        job.hostname,' (',job.comment,')')
            elif (not(job.status & job.DONE)):
                verbose(VERBOSE_LEVEL.VERBOSE, 'Currently processing job ',
                        job.id,' (',job.comment,')')
                jobCount+=1
            else:
                verbose(VERBOSE_LEVEL.DEBUG, 'Finished processing job ',
                        job.id,' (',job.comment,')')

    verbose(VERBOSE_LEVEL.VERBOSE, 'Found ',jobCount,' jobs.')
    if (jobCount > 0):
        verbose(VERBOSE_LEVEL.DEFAULT, "mythjobqueue is not idle.")
    else:
        verbose(VERBOSE_LEVEL.DEFAULT, "mythjobqueue is idle.")

    return jobCount

def run_daemon():
    # fork once
    try:
        pid = os.fork()
        if pid:
            # parent, exit
            sys.exit(0)
    except OSError, e:
        verbose(VERBOSE_LEVEL.DEFAULT, "Daemon failed fork to background.")
        sys.exit(1)

    os.chdir("/")
    os.setsid()
    os.umask(0)

    # fork twice
    try:
        pid = os.fork()
        if pid:
            # parent, exit
            sys.exit(0)
    except OSError, e:
        verbose(VERBOSE_LEVEL.DEFAULT, "Daemon failed fork to background.")
        sys.exit(1)

    pid = get_pid()
    if pid is None:
        pid = run_jobqueue()

    running = True
    while True:
        try:
            count = get_job_count()
            if running and count==0:
                term_jobqueue(pid)
            elif not running and count:
                pid = run_jobqueue()
        except MythDBError:
            # database is inaccessible
            # wait for bindings to automatically reconnect
            pass
        time.sleep(60)

        
if __name__ == '__main__':
    parser = OptionParser(usage="usage: %prog [options]")

    parser.set_defaults(verbose_level=VERBOSE_LEVEL.DEFAULT)
    parser.add_option('-v', '--verbose', action='store', type='int',
                      dest='verbose_level', default=VERBOSE_LEVEL.DEFAULT,
                      help='Verbosity level')
    parser.add_option('-d', '--daemonize', action='store_true',
                      dest='daemon', default=False,
                      help='Daemonize and manage mythjobqueue')

    opts, args = parser.parse_args()

    LEVEL = opts.verbose_level

    try:
        DB = MythDB()
    except MythDBError:
        verbose(VERBOSE_LEVEL.VERBOSE, 'Failed to connect to the database server.')
        sys.exit(int(opts.daemon))

    if opts.daemon:
        run_daemon()
        sys.exit(1)

    else:
        sys.exit(get_job_count())

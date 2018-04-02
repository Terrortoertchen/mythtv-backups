#!/bin/bash
# Check to see if anyone is currently logged in or if the machine was recently switched on.
# Echoed text appears in log file. It can be removed and --quiet added to the
# grep command once you are satisfied that mythTV is working properly.
# Exit codes:-
# 2 - Machine recently switched on, don't shut down.
# 1 - A user is logged in, don't shut down.
# 0 - No user logged in, OK to shut down.

# Customizable variables
MIN_UPTIME=20   # Minimum up time in minutes
# End of customizable variables

# Get a date/time stamp to add to log output
DATE=`date +%F\ %T\.%N`
DATE=${DATE:0:23}

UPTIME=`cat /proc/uptime | awk '{print int($1/60)}'`

if [ "$UPTIME" -lt "$MIN_UPTIME" ]; then
    echo $DATE Machine uptime less than $MIN_UPTIME minutes, don\'t shut down.
    exit 2
fi

# Some configurations ( at least lxdm + xfce4) do not report GUI-logged-on users
# with "who" or "users".
# pgrep tests if processes named xfce* exist

XFCE_PROCS=`pgrep xfce`

USERS=`who -q | tail -n 1 | sed 's/[a-z #]*=//'`

if [ "$USERS" == "0" ] && [ "$XFCE_PROCS" == "" ]; then
    echo $DATE No users are logged in, ok to shut down.
    exit 0
  else
    echo $DATE Someone is still logged in, don\'t shut down.
    exit 1
fi

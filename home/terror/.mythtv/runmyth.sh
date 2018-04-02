#!/bin/bash
# MythTV auto-start/end script

if [ -z `pidof mythfrontend.real` ]
then
    mythfrontend & 
        (for i in $( seq 1 100 )
    do
        echo $i;
        sleep 0.1;
    done) | zenity --auto-close --progress --text="Starting MythTV. This may take longer than this dialog shows." --title="Starting MythTV"
else
TK=$(pidof mythfrontend.real)
if [ `pidof mythfrontend.real` ]
then
    kill -n 15 $TK
    (for i in $( seq 1 100 )
    do
        echo $i;
        sleep 0.1;
    done) | zenity --auto-close --progress --text="Stopping MythTV. This may take longer than this dialog shows." --title="Stopping MythTV"
fi
fi

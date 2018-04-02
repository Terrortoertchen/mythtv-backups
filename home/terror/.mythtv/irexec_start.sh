#!/bin/bash
LIRC_SOCKET_PATH=/dev/
sudo mkdir /run/lirc
sudo ln -s /dev/lircd /run/lirc/lircd
irexec -d /home/terror/.mythtv/lircrc
pulseaudio -D
#sudo dvb-fe-tool -d DVB-C

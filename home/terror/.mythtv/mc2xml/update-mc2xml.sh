#!/bin/sh
cd /home/terror/.mythtv/mc2xml
rm -rf /home/terror/.mythtv/mc2xml/newxmltv.xml /home/terror/.mythtv/mc2xml/xmltv.xml /home/terror/.mythtv/xmltv.xml
#if /home/terror/.mythtv/mc2xml/mc2xml -c de -g 90461 -C mc2xml.chl -f ; then
if /home/terror/.mythtv/mc2xml/mc2xml -c de -g 90461 -f ; then
  sed -f /home/terror/.mythtv/mc2xml/sedscript.txt < /home/terror/.mythtv/mc2xml/xmltv.xml > /home/terror/.mythtv/mc2xml/newxmltv.xml && /usr/bin/mythfilldatabase --refresh 14 --file --sourceid 1 --xmlfile newxmltv.xml
fi

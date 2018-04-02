#####   commercialremover.sh Script for MythTV, updated 2013/12/15
###
##	Made for MythTV 0.26 also tested against 0.27, by jmw for MythGrid
##	https://sourceforge.net/projects/mythgrid/
##
##      This script requires the User Job to pass additional arguments under MythTV 0.26 or higher
##	User job command:
##      ‘commercialremover.sh %DIR% %FILE% %CHANID% %STARTTIMEUTC%'
###
#####
VIDEODIR=$1
FILENAME=$2
CHAN=$3
START=$4

# Sanity checking, to make sure everything is in order. Modified to check $CHAN and $START for MythTV 0.25 or higher support
if [ -z "$VIDEODIR" -o -z "$FILENAME" -o -z "$CHAN" -o -z "$START" ]; then
        echo "Usage: $0 <VideoDirectory> <FileName>"
        exit 5
fi
if [ ! -f "$VIDEODIR/$FILENAME" ]; then
        echo "File does not exist: $VIDEODIR/$FILENAME"
        exit 6
fi

#create temp file name
FILENAMEPREFIX="${CHAN}_${START}"
INFILEPATH="$VIDEODIR/$FILENAME"
TEMPFILEPATH="$INFILEPATH.tmp"
MAPEXT=".map"

LOGFOLDERPATH="/tmp/mythtv/commercialRemoval"
if [ ! -d "$LOGFOLDERPATH" ]; then
	mkdir -p $LOGFOLDERPATH
fi

LOG="$LOGFOLDERPATH/${FILENAMEPREFIX}.log"

echo "Generating cutlist..."
mythutil -q --gencutlist --chanid $CHAN --starttime $START > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
	echo "Generating cutlist failed for ${FILENAME} with error $ERROR" >> $LOG 2>&1
	exit $ERROR
fi

echo "Transcoding..."
mythtranscode --honorcutlist --allkeys -v all,jobqueue --showprogress --mpeg2 -i $INFILEPATH -o $TEMPFILEPATH > /dev/null 2>&1
ERROR=$?
if [ $ERROR -ne 0 ]; then
        echo "Transcoding failed for ${FILENAME} with error $ERROR" >> $LOG 2>&1
        exit $ERROR
fi

#Save a copy of the original with the extension .old
mv -f $INFILEPATH $INFILEPATH.old

#Overwrite the original file with the transcoded file
mv -f $TEMPFILEPATH $INFILEPATH
#Sometimes a .map file is generated, clean that up too
rm -f $TEMPFILEPATH$MAPEXT

#clear out the old cutlist
echo "Clearing cutlist..."
mythutil -q --clearcutlist --chanid $CHAN --starttime $START > /dev/null 2>&1

echo "Clearing skiplist..."
mythutil -q --clearskiplist --chanid $CHAN --starttime $START > /dev/null 2>&1

#Determine new filesize to update the db with
UPDATEDFILESIZE=$(du -b $INFILEPATH | awk '{print $1}')

#Get mythtv database information
DBSERVER="localhost"
DBUSER="mythtv"
DBNAME="mythconverg"
DBPASS="u5joNIJH"

#Try getting mythtv database information from existant files in the following order
MYTHDBFILE="/etc/mythtv/mysql.txt"
MYTHCONFIGFILE="/etc/mythtv/config.xml"
MYCONFIGFILE="~/.mythtv/config.xml"

if [ -f "$MYTHDBFILE" ]; then
	DBSERVER=$( grep "DBHostName=" $MYTHDBFILE | sed s/.*DBHostName=/\/ )
	DBUSER=$( grep "DBUserName=" $MYTHDBFILE | sed s/.*DBUserName=/\/ )
	DBNAME=$( grep "DBName=" $MYTHDBFILE | sed s/.*DBName=/\/ )
	# Determine database password
	DBPASS=$( grep "DBPassword=" $MYTHDBFILE | sed s/.*DBPassword=/\/ )
elif [ -f "$MYTHCONFIGFILE" ]; then
	DBSERVER=$( grep -E -m 1 -o "<DBHostName>(.*)</DBHostName>" $MYTHCONFIGFILE | sed -e 's,.*<DBHostName>\([^<]*\)</DBHostName>.*,\1,g' )
	DBUSER=$( grep -E -m 1 -o "<DBUserName>(.*)</DBUserName>" $MYTHCONFIGFILE | sed -e 's,.*<DBUserName>\([^<]*\)</DBUserName>.*,\1,g' )
	DBNAME=$( grep -E -m 1 -o "<DBName>(.*)</DBName>" $MYTHCONFIGFILE | sed -e 's,.*<DBName>\([^<]*\)</DBName>.*,\1,g' )
	DBPASS=$( grep -E -m 1 -o "<DBPassword>(.*)</DBPassword>" $MYTHCONFIGFILE | sed -e 's,.*<DBPassword>\([^<]*\)</DBPassword>.*,\1,g' )
elif [ -f "$MYCONFIGFILE" ]; then
	DBSERVER=$( grep -E -m 1 -o "<Host>(.*)</Host>" $MYCONFIGFILE | sed -e 's,.*<Host>\([^<]*\)</Host>.*,\1,g' )
	DBUSER=$( grep -E -m 1 -o "<UserName>(.*)</UserName>" $MYCONFIGFILE | sed -e 's,.*<UserName>\([^<]*\)</UserName>.*,\1,g' )
	DBNAME=$( grep -E -m 1 -o "<DatabaseName>(.*)</DatabaseName>" $MYCONFIGFILE | sed -e 's,.*<DatabaseName>\([^<]*\)</DatabaseName>.*,\1,g' )
	DBPASS=$( grep -E -m 1 -o "<Password>(.*)</Password>" $MYCONFIGFILE | sed -e 's,.*<Password>\([^<]*\)</Password>.*,\1,g' )
fi

if [ -z "$DBSERVER" -o -z "$DBUSER" -o -z "$DBPASS" -o -z "$DBNAME" ]; then
	# Update the database entry for the file size
	echo "UPDATE recorded SET filesize='${UPDATEDFILESIZE}' WHERE chanid='${CHAN}' && starttime='${START}'" | mysql -h ${DBSERVER} -u ${DBUSER} --password=${DBPASS} ${DBNAME}
fi

echo "Commericals removed for $FILENAME" >> $LOG 2>&1
exit 0

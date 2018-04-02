#!/bin/bash

### removecommercials - for mythtv user job.
### $author Zack White - zwhite dash mythtv a t nospam darkstar deleteme frop dot org
### $Modified 20080330 Richard Hendershot - rshendershot a t nospam gmail deleteme dot youknowcom
### $Modified 20100112 Aaron Larson to get password from mythtv config file, clear autoskip list after transcoding, and detect pre-flagged files.

# Should be set as a mythtv user job with a command as:
#  removecommercials %DIR% %FILE% %CHANID% %STARTTIME%
#
#   initialize;  all except SKIP are required for this to function correctly
declare VIDEODIR=$1
declare FILENAME=$2
declare CHANID=$3
declare STARTTIME=$(echo $4 | sed -e 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3-\4-\5-\6/')
declare SKIP=$5
# for lossless transcoding autodetect.  Set to empty string for rtJpeg/mpeg4.
declare MPEG2=--mpeg2
declare PROG=$(basename $0)

if [ -z "${VIDEODIR}" -o -z "${FILENAME}" -o -z "${CHANID}" -o -z "${STARTTIME}" ]; then
        cat - <<-EOF
	Usage: $PROG <VideoDirectory> <FileName> <ChannelID> <StartTime> [SKIP]

	Flag commercials (if they are not already flagged), do a lossless transcode
	to remove the commercials, and fixup the database as necessary.	 The net
	effect is that this script can be run as the *only* job after a recording,
	or as a job after a commercial flagging job (either way).  The optional 5th
	parameter 'SKIP', if specified as a non zero length string, will transcode
	using the existing cutlist.
	EOF
        exit 5
fi
if [ ! -f "${VIDEODIR}/${FILENAME}" ]; then
        echo "$PROG: File does not exist: ${VIDEODIR}/${FILENAME}"
        exit 6
fi
if [ ! -d "${VIDEODIR}" ]; then
        echo "$PROG: <VideoDirectory> must be a directory"
        exit 7
fi
if [ ! -d "${VIDEODIR}/originals" ]; then
        mkdir "${VIDEODIR}"/originals
fi
if [ ! -d "${VIDEODIR}/originals" ]; then
        echo "$PROG: you must have write access to <VideoDirectory>"
        exit 8
fi

# mythtv stores the mysql configuration information in the following
# file.  Extract the DB user and password.
mythConfig=~/.mythtv/config.xml
mysqlArgs=""
if [ -e "$mythConfig" ]; then
        mysqlUserOpt=$(sed $mythConfig -n -e '/<UserName/p')
        if [ -n "$mysqlUserOpt" ]; then
           mysqlUser=$(echo $mysqlUserOpt | sed 's: *</*UserName> *::g')
           mysqlArgs+=" -u $mysqlUser"
        fi
        mysqlPassOpt=$(sed $mythConfig -n -e '/<Password/p')
        if [ -n "$mysqlPassOpt" ]; then
           mysqlPass=$(echo $mysqlPassOpt | sed 's: *</*Password> *::g')
           if [ -n "$mysqlPass" ]; then
               mysqlArgs+=" -p$mysqlPass"
           fi
        fi
fi

if [ -z "${SKIP}" ]; then
        #   if transcode was run after mythcommflag in the normal setup screens
        #   then the current file may not match the existing index, so rebuild
        echo "$PROG: Rebuilding seek list for ${FILENAME}"
        mythcommflag --chanid ${CHANID} --starttime ${STARTTIME} --quiet --rebuild
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
                echo "$PROG: Rebuilding seek list failed for ${FILENAME} with error $ERROR"
                exit $ERROR
        else
                echo "$PROG: Rebuilding seek list successful for ${FILENAME}"
        fi

        #   flag commercials (generate skiplist)
        #   you can use mythcommflag -f ${VIDEODIR}/${FILENAME} --getskiplist
        #   to view results

	# has mythcommflag already run?
	alreadyFlagged=$(mysql $mysqlArgs -B -N -e "select commflagged from recorded where basename = '${FILENAME}'" mythconverg)
	if [ "$alreadyFlagged" == "1" ]; then
	    echo "$PROG: ${FILENAME} already flagged, skipping mythcommflag."
	else
	    echo "$PROG: Commercial flagging ${FILENAME}"
	    mythcommflag --chanid ${CHANID} --starttime ${STARTTIME} --quiet
	    ERROR=$?
	    if [ $ERROR -gt 126 ]; then
		    echo "$PROG: Commercial flagging failed for ${FILENAME} with error $ERROR"
		    exit $ERROR
	    else
		    echo "$PROG: Commercial flagging successful for ${FILENAME}"
	    fi
	fi

	#   generate cutlist from skiplist
	#   you can use mythcommflag -f ${VIDEODIR}/${FILENAME} --getcutlist
	#   to view results
	echo "$PROG: Creating cutlist from skiplist for ${FILENAME}"
	mythcommflag --chanid ${CHANID} --starttime ${STARTTIME} --quiet --gencutlist
	ERROR=$?
	if [ $ERROR -ne 0 ]; then
		echo "$PROG: Creating cutlist from skiplist failed for ${FILENAME} with error $ERROR"
		exit $ERROR
	else
		echo "$PROG: Creating cutlist from skiplist successful for ${FILENAME}"
	fi
else
        echo "$PROG: skipping commercial detection due to parameter $SKIP"
fi  #end skip

#   cut the commercials from the file.  creates a new file and a map file.
echo "$PROG: Transcoding commercials out of original file (${FILENAME})"
mythtranscode --chanid ${CHANID} --starttime ${STARTTIME} $MPEG2 --honorcutlist -o "${VIDEODIR}/${FILENAME}.mpeg"
ERROR=$?
if [ $ERROR -ne 0 ]; then
        echo "$PROG: Transcoding failed for ${FILENAME} with error $ERROR"
        exit $ERROR
else
        echo "$PROG: Transcoding successful for ${FILENAME}"
fi

echo "$PROG: Moving ${VIDEODIR}/${FILENAME}  to  ${VIDEODIR}/originals/${FILENAME}"
mv "${VIDEODIR}/${FILENAME}" "${VIDEODIR}/originals"
ERROR=$?
if [ $ERROR -ne 0 ]; then
        echo "$PROG: Moving failed with error $ERROR"
        exit $ERROR
else
        echo "$PROG: Moving successful"
fi

echo "$PROG: Moving ${VIDEODIR}/${FILENAME}.mpeg  to  ${VIDEODIR}/${FILENAME}"
if [ ! -f "${VIDEODIR}/${FILENAME}" ]; then
        mv "${VIDEODIR}/${FILENAME}.mpeg" "${VIDEODIR}/${FILENAME}"
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
                echo "$PROG: Moving failed with error $ERROR"
                exit $ERROR
        else
                echo "$PROG: Moving successful"
        fi
else
        echo "$PROG: cannot replace original.  skipping file move. (${VIDEODIR}/${FILENAME})"
fi


echo "$PROG: removing map file: ${VIDEODIR}/${FILENAME}.mpeg.map"
if [ -f "${VIDEODIR}/${FILENAME}.mpeg.map" ]; then
        rm "${VIDEODIR}/${FILENAME}.mpeg.map"
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
                echo "$PROG: unable to remove map file: ${VIDEODIR}/${FILENAME}.mpeg.map"
        else
                echo "$PROG: removed map file successfully"
        fi
fi

#   file has changed, rebuild index
echo "$PROG: Rebuilding seek list for ${FILENAME}"
mythcommflag --chanid ${CHANID} --starttime ${STARTTIME} --quiet --rebuild
ERROR=$?
if [ $ERROR -ne 0 ]; then
        echo "$PROG: Rebuilding seek list failed for ${FILENAME} with error $ERROR"
        exit $ERROR
else
        echo "$PROG: Rebuilding seek list successful for ${FILENAME}"
fi

echo "$PROG: Clearing cutlist for ${FILENAME}"
mythcommflag --chanid ${CHANID} --starttime ${STARTTIME} --quiet --clearcutlist
ERROR=$?
if [ $ERROR -eq 0 ]; then
        echo "$PROG: Clearing cutlist successful for ${FILENAME}"
else
        echo "$PROG: Clearing cutlist failed for ${FILENAME} with error $ERROR"
        exit $ERROR
fi

# mythcommflag sets cutlist to zero, but doesn't update the filesize.
# Fix the database entry for the file
mysql $mysqlArgs mythconverg << EOF
    UPDATE
        recorded
    SET
        cutlist = 0,
        filesize = $(ls -l "${VIDEODIR}/${FILENAME}" | awk '{print $5}')
    WHERE
        basename = '${FILENAME}';
EOF

echo "$PROG: Clearing autoskip list: ${VIDEODIR}/${FILENAME}"
mysql $mysqlArgs mythconverg << EOF
    DELETE FROM
	   recordedmarkup
    WHERE
	   CONCAT( chanid, starttime ) IN (
		   SELECT
			   CONCAT( chanid, starttime )
		   FROM
			   recorded
		   WHERE
			   basename = '$FILENAME'
	   );
EOF

# If you want to keep the originals, comment out this line.
echo "$PROG: removing saved copy of: ${VIDEODIR}/originals/${FILENAME}"
rm "${VIDEODIR}/originals/${FILENAME}"
ERROR=$?
if [ $ERROR -ne 0 ]; then
	echo "$PROG: failed to remove ${VIDEODIR}/originals/${FILENAME}"
	exit $ERROR
fi

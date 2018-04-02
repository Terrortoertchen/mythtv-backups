#
# getTrailers v0.3
#
# Be sure you have lynx and youtube-dl installed
#

# The directory to store your trailers (no trailing slash)
TRAILERDIR="/storage/mythtv/trailers";

# Maximum size to download from YouTube
# Format key can be found here:
#   http://en.wikipedia.org/wiki/YouTube#Quality_and_codecs
MAXFORMAT="22";



# ---- BEGIN ----

if [ -d "$TRAILERDIR" ]; then
	VIDS=`lynx -dump "http://www.youtube.com/trailers?s=trp&p=1" |grep "\. http" |grep "\?v=" | awk '{print $2}' | uniq`

	cd $TRAILERDIR

	for F in `ls`; do
		FOUND=false
		for V in $VIDS; do
			FILENAME=${V##*v=}
			FILENAMEF="$FILENAME.flv"
			FILENAME="$FILENAME.mp4"
			if [ "$FILENAME" == "$F" ]; then
				FOUND=true;
			fi;
			if [ "$FILENAMEF" == "$F" ]; then
				FOUND=true;
			fi;
		done;
		if ! $FOUND; then
			rm -f $F;
		fi;
	done;

	for V in $VIDS; do
		FILENAME=${V##*v=}
		FILENAMEF="$FILENAME.flv"
		FILENAME="$FILENAME.mp4"
		if [ ! -e $FILENAME ]; then
			if [ ! -e $FILENAMEF ]; then
				youtube-dl "$V";
			else
				echo "$FILENAMEF exists."
			fi;
		else
			echo "$FILENAME exists."
		fi;
	done;
fi;

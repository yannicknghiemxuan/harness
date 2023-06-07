#!/bin/sh
HOST=`uname -n`
VIDEOLIST=/galaxy/public_space/GOZER/fichiers_a_encoder.txt
BASEPATH=/galaxy/public_space/
NEWBASEPATH=/galaxy/public_space/WE_Black/
OLDIFS=$IFS
NEWIFS='
'
IFS=$NEWIFS

mkdir -p "$NEWBASEPATH" > /dev/null 2>&1

for fullfilepath in `cat $VIDEOLIST`; do
    if [ ! -f "$fullfilepath" ]; then
	echo THE FILE DOES NOT EXIST :..:..:..:..:..:..: "$fullfilepath" DOES NOT EXIST
	continue
    fi
    filename=`echo $fullfilepath | sed -e "s@/.*/@@"`
    filepath=`echo $fullfilepath | sed -e "s@$filename@@"`
    relativepath=`echo $fullfilepath | sed -e "s@$BASEPATH@@" -e "s@$filename@@"`
    newpath="$NEWBASEPATH/$relativepath"
    newfilename=`echo $filename | sed -e "s@\..*@@"`\.avi
    newfullfilepath=$newpath/$newfilename
    sourceext=`echo $filename | sed -e "s@.*\.@@"`
    if [ -f "${newfullfilepath}_tmp" ]; then
	echo being encoded or should not exist ..:..:.. "$newfullfilepath"
    elif [ ! -f "$newfullfilepath" ]; then
	echo has to be encoded :..:..:..:..:..:..:..:.. "$newfullfilepath"
    fi
done

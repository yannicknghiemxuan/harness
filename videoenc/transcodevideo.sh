#!/bin/sh
HOST=`uname -n`
ENCODER=ffmpeg
BITRATE=640kb
PREVENTRIGHTMODIF=/galaxy/public_space/GOZER/PREVENT_RIGHT_MODIFICATIONS
CREATEDPREVENTFILE=
VIDEOLIST=/galaxy/public_space/WE_Black/films.txt
ERRLIST=/galaxy/public_space/WE_Black/erreurs_encodage_${HOST}.txt
NONEXISTINGFILES=/galaxy/public_space/WE_Black/fichiers_non_existants_${HOST}.txt
LOGFILE=/galaxy/public_space/WE_Black/journal_${HOST}.log
BASEPATH=/galaxy/public_space/
NEWBASEPATH=/galaxy/public_space/WE_Black/$ENCODER
CONFIGPATH=/galaxy/logic/videoenc/config
OLDIFS=$IFS
NEWIFS='
'
IFS=$NEWIFS


check_codecs() {
    reencodefile=false
    isaudiocompatible=`grep -E "^${audiocodec};" $CONFIGPATH/codecs_audio | awk -F\; '{print $2}'`
    if [ "$isaudiocompatible" = "" ]; then
	echo "error: unknown codec $audiocodec in $CONFIGPATH/codecs_audio" > $LOGFILE
    elif [ "$isaudiocompatible" = "false" ]; then
	reencodefile=true
	return
    fi
    isvideocompatible=`grep -E "^${videocodec};" $CONFIGPATH/codecs_video | awk -F\; '{print $2}'`
    if [ "$isvideocompatible" = "" ]; then
	echo "error: unknown codec $videocodec in $CONFIGPATH/codecs_video" > $LOGFILE
    elif [ "$isvideocompatible" = "false" ]; then
	reencodefile=true
    fi
}


process_file() {
    filename=`echo $fullfilepath | sed -e "s@/.*/@@"`
    filepath=`echo $fullfilepath | sed -e "s@$filename@@"`
    audiocodec=`echo $line | awk -F@ '{print $2}'`
    videocodec=`echo $line | awk -F@ '{print $3}'`
    origsize=`echo $line | awk -F@ '{print $4}'`
    aspectratio=`echo $origsize | sed -e 's@x@:@'`
    check_codecs
    relativepath=`echo $fullfilepath | sed -e "s@$BASEPATH@@" -e "s@$filename@@"`
    newpath="$NEWBASEPATH/$relativepath"
    [ ! -d "$newpath" ] && mkdir -p "$newpath" 2>> $ERRLIST && chmod 777 "$newpath" 2>> $ERRLIST
    newfilename=`echo $filename | sed -e 's@\.[^\.]*$@@'`\.avi
    newfullfilepath=$newpath/$newfilename
    sourceext=`echo $filename | sed -e "s@.*\.@@"`
    if [ $reencodefile = false ]; then
	[ ! -f "$newfullfilepath.txt" ]  && echo `du -hs "$fullfilepath"` > "$newfullfilepath.txt"
	return
    fi
    IFS=$OLDIFS
    resizeopt="-s $origsize"
    if [ "$sourceext" = "mp4" ] || [ "$sourceext" = "m4v" ] || [ "$sourceext" = "m4v" ]; then
	resizeopt="-s 572x358"
    fi
    [ -f "${newfullfilepath}_tmp" ] && return
    if [ -f "$newfullfilepath" ]; then
	filesize=`ls -l "$newfullfilepath" | awk '{print $5}'`
	[ "$filesize" -gt 1048576 ] && return
    fi
    echo `date`":encoding $fullfilepath" >> $LOGFILE
    ffmpeg -i "$fullfilepath" -vcodec libxvid $resizeopt -aspect $aspectratio -b $BITRATE -acodec libmp3lame -ab 192k -f avi "${newfullfilepath}_tmp"
    [ -f "${newfullfilepath}_tmp" ] && mv "${newfullfilepath}_tmp" "$newfullfilepath" 2>> $ERRLIST
    echo `date`":generation of $newfullfilepath completed" >> $LOGFILE
    IFS=$NEWIFS
}


main() {
    if [ ! -f $PREVENTRIGHTMODIF ]; then
	CREATEDPREVENTFILE=true
	touch $PREVENTRIGHTMODIF
    fi
    [ -f $LOGFILE ] && rm $LOGFILE
    mkdir -p "$NEWBASEPATH" > /dev/null 2>&1
    chmod 777 "$NEWBASEPATH" > /dev/null 2>&1
    
    for line in `cat $VIDEOLIST`; do
	fullfilepath=`echo $line | awk -F@ '{print $1}'`
	if [ ! -f "$fullfilepath" ]; then
	    echo "$fullfilepath" >> $NONEXISTINGFILES
	    continue
	fi
	process_file
    done
    
    if [ ! -z "$CREATEDPREVENTFILE" ]; then
	rm -f $PREVENTRIGHTMODIF
    fi
}


main

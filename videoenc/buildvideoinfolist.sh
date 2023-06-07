#!/bin/sh
IFS='
'
rootdir=/galaxy/public_space
targetdir=$rootdir/WE_Black
moviefiles=$targetdir/films.txt
tmpfile=$targetdir/file.temp
filmdirs="Montages video Yannick
Clips
Concerts
Courts metrages
Emissions Series Tele
Films americains
Films documentaires
Films documentaires HD
Films documentaires IMAX
Films francais
Films UK Irlande"


main() {
    for dir in $filmdirs; do
	for i in `find "$rootdir/$dir"`; do
	    if [ -f "$i" ]; then
		filesize=`ls -l "$i" | awk '{print $5}'`
		if [ "$filesize" -gt 10485760 ]; then
		    grep "${i}@" $moviefiles > /dev/null 2>&1
		    if [ $? -ne 0 ]; then
			echo "getting info for $i"
			ffmpeg -i "$i" > $tmpfile 2>&1
			videocodec=`grep Stream $tmpfile | grep 'Video:' | awk '{print $4}' | awk -F\, '{print $1}' | head -n 1`
			videores=`grep Stream $tmpfile | grep 'Video:' | awk '{print $6}' | awk -F\, '{print $1}' | head -n 1`
			audiocodec=`grep Stream $tmpfile | grep 'Audio:' | awk '{print $4}' | awk -F\, '{print $1}' | head -n 1`
			echo "$i@$audiocodec@$videocodec@$videores" >> $moviefiles
		    fi
		fi
	    fi
	done
    done
    [ -f $tmpfile ] && rm $tmpfile
}


main

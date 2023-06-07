#!/bin/sh
targetdir=$1
[ -z "$targetdir" ] && exit 1

IFS='
'

cd "$targetdir"
for txtfile in `find . -name "*.txt"`; do
    sourcefilepath="`sed -e 's@^[0-9\.]*[a-zA-Z][\t\ ]*@@' "$txtfile"`"
    targetfile="`echo "$sourcefilepath" | sed -e 's@/.*/@@g' -e 's@^\ *@@'`"
    targetdir="`echo "$txtfile" | sed -e 's@[^/]*\$@@'`"
    if [ ! -f "$targetdir/$targetfile" ]; then
	echo cp "$sourcefilepath" "$targetdir/$targetfile"
	cp "$sourcefilepath" "$targetdir/$targetfile"
	if [ $? -eq 0 ]; then
	    echo rm "$txtfile"
	    rm "$txtfile"
	else
	    exit $?
	fi
    fi
done

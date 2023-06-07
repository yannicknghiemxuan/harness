#!/usr/bin/env bash
set -euxo pipefail
while true; do
    for c in {1..10}; do
	for i in {0..3}; do
	    thedate=$(date +%Y%m%d_%Hh%M)
	    filename=/home/tnx/work/webcam/output/cam_${i}_${thedate}.jpg
	    fswebcam -d /dev/video$i -r 640x480 --jpeg 85 -D 1 $filename
	    [[ $c -eq 1 ]] && cp $filename /home/tnx/Dropbox/voyage/surveillance/cam_${i}.jpg
	done
	sleep 60
    done
done

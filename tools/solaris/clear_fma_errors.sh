#!/usr/bin/env bash
for i in $(fmadm list | grep -E -i 'major|critical' | awk '{print $4}'); do
    fmadm clear $i
done

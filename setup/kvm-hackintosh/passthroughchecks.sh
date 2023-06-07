#!/usr/bin/env bash
shopt -s nullglob
echo "IOMMU devices"
for d in /sys/kernel/iommu_groups/*/devices/*; do 
    n=${d#*/iommu_groups/*}; n=${n%%/*}
    printf 'IOMMU Group %s ' "$n"
    lspci -nns "${d##*/}"
done | sort -V
echo "=== make sure the vfio devices are listed"
sudo dmesg | grep vfio
echo "=== state of the passthrough devices"
for i in $(sed < passthroughdevices -e 's@[,]@ @g'); do
    lspci -nnk -d $i
done

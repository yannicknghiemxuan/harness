#!/usr/bin/env bash
# The purpose of this script is to remove the old kernels installed on a Ubuntu system
# while excluding the current running kernel version from the cleaning list.
# It's been working well for me for years but obviously use at your own risks!
set -euxo pipefail
. /etc/autoenv
[[ ${SOURCED_IDENTIFY_OS-} != yes ]] && . $AUTOROOT/harness/modules/identify_OS || true


ubuntu_get_kernel_info()
{
    export DEBIAN_FRONTEND=noninteractive
    tmpf=$(mktemp)
    cur_kern=$(uname -r \
		   | awk -F\- '{print $1 "-" $2}')
    # 3,3n 4,4n -> n for numeric sort, by field 3 then field 4
    dpkg --list \
	| egrep -v meta-package \
	| grep -E 'linux-image-[0-9]' \
	| awk '{print $2}' \
	| awk -F\- '{print $3 "-" $4}' \
	| sort -V \
	       > $tmpf
    last_kern=$(tail -n 1 $tmpf)
}


ubuntu_safeguard_checks()
{
    # Safeguard 1: we make that not all kernels are going to be removed
    kern_count=$(wc -l $tmpf \
		     | awk '{print $1}')
    kern_rmcount=$(grep -v -E "${cur_kern}|${last_kern}" $tmpf \
		       | wc -l \
		       | awk '{print $1}')
    if [[ $kern_count -eq $kern_rmcount ]]; then
	echo 'ERROR: safeguard condition #1 not fulfilled: no kernel would be left after removal, exiting' >&2
	rm $tmpf >/dev/null 2>&1 || true
	exit 1
    fi
    # Safeguard 2: we make sure the patterns of the current and latest kernel versions are valid
    if [[ ! $cur_kern =~ ^[0-9]*[.][0-9]*[.][0-9]*[-][0-9]*$ ]] \
	   || [[ ! $last_kern =~ ^[0-9]*[.][0-9]*[.][0-9]*[-][0-9]*$ ]]; then
	echo 'ERROR: safeguard condition #2 not fulfilled: kernel version pattern incorrect, exiting' >&2
	rm $tmpf >/dev/null 2>&1 || true
	exit 1
    fi
}


ubuntu_clean_kernels()
{
    [[ $kern_rmcount -ne 0 ]] \
	&& sudo apt-get remove --purge -yqq \
		$(dpkg --list \
		      | grep -v meta-package \
		      | grep -E 'linux-image-[0-9]|linux-.*headers-[0-9]|linux-image-extra-[0-9]|linux-modules-[0-9]' \
		      | awk '{print $2}' \
		      | grep -v -E "${cur_kern}|${last_kern}" \
		      | xargs) || true
    sudo apt-get autoremove --purge -yqq
    sudo apt-get clean -yqq
    rm $tmpf >/dev/null 2>&1 || true
}


main()
{
    [[ $OS_TYPE != Linux ]] && exit 0 || true
    case $ID in
	ubuntu|linuxmint|debian)
	    ubuntu_get_kernel_info
	    ubuntu_safeguard_checks
	    ubuntu_clean_kernels
	    ;;
	centos|rhel|fedora|rocky)
	    # nothing to do, installonly_limit variable in /etc/yum.conf limits the number of installed kernels
	    ;;
    esac
}


main

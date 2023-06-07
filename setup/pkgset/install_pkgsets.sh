#!/usr/bin/env bash
set -euxo pipefail
. /etc/autoenv
[[ ${SOURCED_IDENTIFY_OS-} != yes ]] && . $AUTOROOT/harness/modules/identify_OS || true


install_Linux_dnf()
{
    pre_install_cmd
    eval "sudo dnf install -y $pkglist"
    if [[ -n ${grplist-} ]]; then
    	OIFS=$IFS
    	IFS=';'
    	for i in "$grplist"; do
    	    eval "sudo dnf groupinstall -y $i"
    	done
	IFS=$OIFS
    fi
    [[ -n ${pkg_rm-} ]] && sudo dnf remove -y $pkg_rm || true
    if [[ $ID == ubuntu ]]; then
    	snaplist=$(grep -E '^snap_' $pkgsetfile | grep -E '=' | awk -F\= '{print $1}' | \
    		       sed -e 's@snap_@\$snap_@g' | xargs)
    	for i in $snaplist; do
    	    for j in $(eval "echo $i"); do
    		eval "sudo snap install --classic $j" || true
    	    done
    	done
    fi
    post_install_cmd
}


install_Linux_apt()
{
    export DEBIAN_FRONTEND=noninteractive

    pre_install_cmd
    sudo apt-get update
    eval "sudo apt-get install -y $pkglist"
    if [[ -n ${pkg_rm-} ]]; then
	for package in $pkg_rm; do
	    sudo apt-get remove -yqq $package || true
	done
	sudo apt-get autoremove -y
    fi
    if [[ $ID == ubuntu ]]; then
    	snaplist=$(grep -E '^snap_' $pkgsetfile | grep -E '=' | awk -F\= '{print $1}' | \
    		       sed -e 's@snap_@\$snap_@g' | xargs)
    	for i in $snaplist; do
    	    for j in $(eval "echo $i"); do
    		eval "sudo snap install --classic $j" || true
    	    done
    	done
    fi
    post_install_cmd
}


install_MacOS()
{
    pre_install_cmd
    eval "brew install $pkglist"
    post_install_cmd
}


install_FreeBSD()
{
    pre_install_cmd
    eval "sudo pkg install $pkglist"
    post_install_cmd
}


load_pkg_info()
{
    pkgsetfile=$AUTOROOT/harness/config/pkgsets/${ID}_${VERSION_ID}
    . $pkgsetfile
    grplist=$(grep -E '^grp_' $pkgsetfile \
		 | grep -v -E '^#' \
		 | grep -E '=' \
		 | awk -F\= '{print $1}' \
		 | sed -e 's@grp_@\$grp_@g' \
		 | xargs || true)
    pkglist=$(grep -E '^pkg_' $pkgsetfile \
		  | grep -v -E '^#' \
		  | grep -E '=' \
		  | awk -F\= '{print $1}' \
		  | grep -v -E 'pkg_rm' \
		  | sed -e 's@pkg_@\$pkg_@g' \
		  | xargs)
    precmdlist=$(grep -E '^precmd_' $pkgsetfile \
		     | grep -v -E '^#' \
		     | grep -E '=' \
		     | awk -F\= '{print $1}' \
		     | sed -e 's@precmd_@\$precmd_@g' \
		     | xargs || true)
    postcmdlist=$(grep -E '^postcmd_' $pkgsetfile \
		      | grep -v -E '^#' \
		      | grep -E '=' \
		      | awk -F\= '{print $1}' \
		      | sed -e 's@postcmd_@\$postcmd_@g' \
		      | xargs || true)
}


main()
{
    load_pkg_info
    case $ID in
	debian|ubuntu|linuxmint)
	    install_Linux_apt
	    ;;
	centos|rocky)
	    install_Linux_dnf
	    ;;
	macos)
	    install_MacOS
	    ;;
	freebsd)
	    install_FreeBSD
	    ;;
    esac
}


main

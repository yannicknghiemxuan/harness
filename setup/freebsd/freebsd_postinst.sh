#!/usr/bin/env bash
set -euxo
#
# Post-install script for FreeBSD - TNX Corp. 2017
#
# history
# 11/09/2017: creation
# 14/01/2018: installed on thinkpad T450 and fixed a couple of issues
# 09/03/2018: added more fonts
# 21/03/2019: refreshed the script
#             added the -euxo options
#             using /sbin/sysrc to modify rc.conf
#             externalized the install of bash
#             cleaned the obsolete packages, updated some of the names
#

# uncomment for proxy server
export http_proxy="http://www-proxy-lon.uk.oracle.com:80"

# for pkg - still not working as intended
export ASSUME_ALWAYS_YES=yes

logfile=./freebsd_postinst.log
pkg_sys="beadm sudo coreutils"
pkg_utils="emacs-nox bash zsh ksh93 tmux rsync wget pstree hexedit vim p7zip corkscrew expect"
pkg_fs="fusefs-ntfs"
pkg_x11="xorg xterm xkill xman xcalc xfontsel xscreensaver tightvnc slim"
pkg_x11_font="urwfonts urwfonts-ttf koi8-u-monaco-x11"
pkg_print="cups cups-pdf"
pkg_gnome="terminator"
# removed 'cinnamon' as its support on FreeBSD is not great for the moment
# removed 'xfce', it needs some extra config to work properly with slim
# -> check https://forums.freebsd.org/threads/58380/
pkg_wm="open-motif windowmaker mate fvwm lxde-meta"
pkg_office="en_GB-libreoffice fr-libreoffice"
pkg_caodao="gimp blender"
pkg_media="vlc mplayer mpg123"
# zeroconf with avahi / nss_mdns
# -> check https://gist.github.com/reidransom/6033227
pkg_net="avahi-app nss_mdns firefox thunderbird pidgin irssi elinks filezilla openconnect nmap"
pkg_libs="ncurses"
pkg_dev="gcc gdb automake autoconf cmake"
pkg_virt="virtualbox-ose virtualbox-ose-additions"
pkg_games="nethack36-nox11 chocolate-doom zdoom eduke32"
#pkg_emu="dgen-sdl RetroArch"
pkg_dev="autoconf automake python27 python36 godot godot-tools"
configfiles="computing/config/emacs/.emacs \
computing/config/freebsd/.bashrc \
computing/config/freebsd/.xinitrc \
computing/config/freebsd/.xsession \
computing/config/freebsd/.Xdefaults \
computing/config/freebsd/.vnc \
computing/config/tmux/.tmux.conf"
userlist="tnx"


check_requirements()
{
    if [[ ! -x /usr/local/bin/bash ]]; then
	echo "bash needs to be installed, run ./install_bash.sh"
	exit
    fi
}


backup_configs()
{
    for f in /etc/rc.conf /boot/loader.conf /etc/sysctl.conf /etc/syslog.conf /etc/passwd \
	/usr/local/etc/slim.conf /etc/ttys /usr/local/etc/PolicyKit/PolicyKit.conf /etc/devfs.conf \
	/usr/local/etc/pkg.conf /etc/nsswitch.conf; do
	if [[ ! -f ${f}_orig && -f $f ]]; then cp -Pp $f ${f}_orig; fi
    done
}


enable_service() {
    [[ -z $1 ]] && return 0
    s=$1
    sysrc ${s}_enable=YES
    service $s start || service $s onestart || true
}


configure_automount()
{
    # source: https://www.freebsd.org/doc/handbook/usb-disks.html
    if grep operator /etc/devfs.rules >/dev/null 2>&1; then
	return 0
    fi
    # To make the device mountable as a normal user
    cat >> /etc/devfs.rules <<EOF
[localrules=5]
add path 'da*' mode 0660 group operator
EOF
    echo 'devfs_system_ruleset="localrules"' >> /etc/rc.conf
    echo 'vfs.usermount=1' >> /etc/sysctl.conf
    sysctl vfs.usermount=1

    # creates an automount directory for each user
    for u in $userlist; do
	pw groupadd $u || true
	pw usermod $u -G operator,wheel,$u || true
	mkdir /mnt/$u || true
	chown $u:$u /mnt/$u || true
    done

    # enables automount
    echo '/media		-media		-nosuid' >> /etc/auto_master
    cat >> /etc/devd.conf <<EOF
notify 100 {
	match "system" "GEOM";
	match "subsystem" "DEV";
	action "/usr/sbin/automount -c";
};
EOF

    # MATE users should configure PolicyKit to allow normal users to mount removable media automatically
    cat > /usr/local/etc/PolicyKit/PolicyKit.conf <<EOF
<?xml version="1.0" encoding="UTF-8"?> <!-- -*- XML -*- -->

<!DOCTYPE pkconfig PUBLIC "-//freedesktop//DTD PolicyKit Configuration 1.0//EN"
"http://hal.freedesktop.org/releases/PolicyKit/1.0/config.dtd">

<!-- See the manual page PolicyKit.conf(5) for file format -->

<config version="0.1">
    <match action="org.freedesktop.hal.storage.mount-removable">
        <return result="yes"/>
    </match>
    <match action="org.freedesktop.hal.storage.mount-fixed">
        <return result="yes"/>
    </match>
    <match user="root">
        <return result="yes"/>
    </match>
    <define_admin_auth group="wheel"/>
</config>
EOF

    service automount restart
    service devd restart
    enable_service autofs
    service automount start
    service automountd start
    service autounmountd start
}


configure_powerd()
{
    # source: https://cooltrainer.org/a-freebsd-desktop-howto/
    if grep -E powerd_flags /etc/rc.conf >/dev/null 2>&1; then
	return 0
    fi
    cat >> /etc/rc.conf <<EOF

# powerd: hiadaptive speed while on AC power, adaptive while on battery power
powerd_enable="YES"
powerd_flags="-a hiadaptive -b adaptive"
EOF
}


configure_bluetooth()
{
    # source: https://cooltrainer.org/a-freebsd-desktop-howto/
    if grep -E hcsecd_enable /etc/rc.conf >/dev/null 2>&1; then
	return 0
    fi
    cat >> /etc/rc.conf <<EOF

# Enable BlueTooth
hcsecd_enable="YES"
sdpd_enable="YES"
EOF
}


configure_ntpd()
{
    # source: https://cooltrainer.org/a-freebsd-desktop-howto/
    if grep -E ntpd_enable /etc/rc.conf >/dev/null 2>&1; then
	return 0
    fi
    cat >> /etc/rc.conf <<EOF

# Synchronize system time
ntpd_enable="YES"
# Let ntpd make time jumps larger than 1000sec
ntpd_flags="-g"
EOF
}


configure_shells()
{
    chsh -s bash root
    chsh -s bash tnx
}


install_pkgs()
{
    [[ ! -f /tmp/pkg_conf.patched ]] && patch /usr/local/etc/pkg.conf <<EOF
--- pkg.conf_orig	2018-01-11 23:52:25.654827000 +0000
+++ pkg.conf	2018-01-11 23:55:56.033263000 +0000
@@ -26,7 +26,7 @@
 #ABI = "freebsd:10:x86:64";     # Autogenerated
 #DEVELOPER_MODE = false;
 #VULNXML_SITE = "http://vuxml.freebsd.org/freebsd/vuln.xml.bz2";
-#FETCH_RETRY = 3;
+FETCH_RETRY = 10;
 #PKG_PLUGINS_DIR = "/usr/local/lib/pkg/";
 #PKG_ENABLE_PLUGINS = true;
 #PLUGINS [
@@ -38,7 +38,7 @@
 #NAMESERVER = "";
 #HTTP_USER_AGENT = "Custom_User_Manager";
 #EVENT_PIPE = "";
-#FETCH_TIMEOUT = 30;
+FETCH_TIMEOUT = 200;
 #UNSET_TIMESTAMP = false;
 #SSH_RESTRICT_DIR = "";
 #PKG_ENV {
EOF
    [[ $? -eq 0 ]] && touch /tmp/pkg_conf.patched

    pkg upgrade
    [[ $? -ne 0 ]] && exit
    pkg install ${pkg_sys-} ${pkg_utils-} ${pkg_fs-} ${pkg_x11-} ${pkg_x11_font-} ${pkg_print-} \
	${pkg_wm-} ${pkg_office-} ${pkg_caodao-} ${pkg_media-} ${pkg_libs-} ${pkg_net-} ${pkg_dev-} \
	${pkg_virt-} ${pkg_emu-} ${pkg_dev-} 2>&1 | tee -a $logfile
}


install_user_cfgs()
{
    [[ ! -d /home/tnx ]] || [[ -f /tmp/computing.tar.gz ]] && return 0
    scp -P 443 tnx@www.irishgalaxy.com:/galaxy/computing.tar.gz /tmp
    [[ $? -ne 0 ]] && return 0
    cd /tmp
    gunzip -dc computing.tar.gz | tar xf -
    for u in root tnx; do
	homedir=$(getent passwd $u | cut -d: -f6)
	for cfgfile in $configfiles; do
	    fname=$(echo $cfgfile | awk -F/ '{print $NF}')
	    [[ -f $homedir/$fname ]] && continue
	    test cp -r $cfgfile $homedir || return 0
	    test chown $u $homedir/$fname || return 0
	done
    done
}


configure_services()
{
    enable_service dbus				# dbus, needed for firefox and other apps
    enable_service hald				# hald, hardware abstraction layer
    enable_service avahi_daemon			# avahi zero configuration service
    enable_service avahi_dnsconfd
    enable_service moused			# mouse console driver
}


configure_mdns()
{
    sed -e 's@hosts: files dns@hosts: files dns mdns@' < /etc/nsswitch.conf > /etc/nsswitch.conf_
    mv /etc/nsswitch.conf_ /etc/nsswitch.conf
}


configure_bootconfig()
{
    # source: https://cooltrainer.org/a-freebsd-desktop-howto/
    if grep -E '\-v' /boot.config >/dev/null 2>&1; then
	return 0
    fi
    echo "-v" >> /boot.config
    cat >> /boot/loader.conf <<EOF
# Devil worship in loader logo
loader_logo="beastie"

# Boot-time kernel tuning
kern.ipc.shmseg=1024
kern.ipc.shmmni=1024
kern.maxproc=100000

# Load MMC/SD card-reader support
mmc_load="YES"
mmcsd_load="YES"
sdhci_load="YES"

# Access ATAPI devices through the CAM subsystem
atapicam_load="YES"

# Filesystems in Userspace
fuse_load="YES"

# Intel Core thermal sensors
coretemp_load="YES"

# AMD K8, K10, K11 thermal sensors
#amdtemp_load="YES"

# In-memory filesystems
tmpfs_load="YES"

# Asynchronous I/O
aio_load="YES"

# Handle Unicode on removable media
libiconv_load="YES"
libmchain_load="YES"
cd9660_iconv_load="YES"
msdosfs_iconv_load="YES"
EOF
}


configure_sysctl()
{
    # source: https://cooltrainer.org/a-freebsd-desktop-howto/
    if grep -E kern.ipc.shmmax /etc/sysctl.conf >/dev/null 2>&1; then
	return 0
    fi
    cat >> /etc/sysctl.conf <<EOF

# Enhance shared memory X11 interface
kern.ipc.shmmax=67108864
kern.ipc.shmall=32768

# Enhance desktop responsiveness under high CPU use (200/224)
kern.sched.preempt_thresh=224

# Bump up maximum number of open files
kern.maxfiles=200000

# Disable PC Speaker
hw.syscons.bell=0

# Shared memory for Chromium
kern.ipc.shm_allow_removed=1

EOF
}


configure_consoles()
{
    # redirection of system messages to a log file
    [[ -f /var/log/console.log ]] && return 0
    touch /var/log/console.log && chmod 600 /var/log/console.log
    sed -e 's@/dev/console@/var/log/console.log@' < /etc/syslog.conf > /etc/syslog.conf_
    mv /etc/syslog.conf_ /etc/syslog.conf
}


configure_CUPS()
{
    # source: https://www.freebsd.org/doc/en/articles/cups/printing-cups-configuring-server.html
    if grep -E cupsd_enable /etc/rc.conf >/dev/null 2>&1; then
	return 0
    fi
    cat >> /etc/rc.conf <<EOF

# CUPS print server
cupsd_enable="YES"
devfs_system_ruleset="system"
EOF
    /usr/local/etc/rc.d/cupsd restart
    echo "now configure your printer opening a browser to http://localhost:631"
}


configure_CDE()
{
    # Common Desktop Environment
    enable_service rpcbind
    enable_service dtspc
    enable_service dtcms
}


configure_slim()
{
    # note: if slim fails, check that dbus is running properly
    # enables slim login manager
    enable_service slim

    # creates the missing window manager startup files
    for i in WindowMaker:wmaker fvwm:fvwm Motif:mwm; do
	wm=$(echo $i | awk -F: '{print $1}')
	cmd=$(echo $i | awk -F: '{print $2}')
	[[ ! -f /usr/local/share/xsessions/$wm.desktop ]] && \
	    cat > /usr/local/share/xsessions/$wm.desktop <<EOF
[Desktop Entry]
Name=$wm
Exec=$cmd
EOF
    done

    # configures the theme
    cd /usr/local/share/slim/themes
    tar jxvf /tmp/computing/config/freebsd/slim/themes/slim-freebsd.tar.bz2
    cd -
    sed -e 's@current_theme       default@current_theme       freebsd-1680x1050@' < /usr/local/etc/slim.conf \
	> /usr/local/etc/slim.conf_ && \
	mv /usr/local/etc/slim.conf_ /usr/local/etc/slim.conf

    # now we need to make sure there are .xinitrc files in user's home dirs
    for theuser in root $(grep /home/ /etc/passwd | awk -F: '{print $1}' | xargs); do
	homedir=$(eval echo ~${theuser})
	[[ ! -f $homedir/.xinitrc ]] && echo 'exec $1' > $homedir/.xinitrc
	chown $theuser $homedir/.xinitrc
    done
}


configure_sound()
{
    # sound support - source: https://cooltrainer.org/a-freebsd-desktop-howto/
    if grep snd_driver_load /boot/loader.conf >/dev/null 2>&1; then
	return 0
    fi
    echo 'snd_driver_load="YES"' >> /boot/loader.conf
    kldload snd_driver || true
    echo '# Dont automatically use new sound devices' >> /etc/sysctl.conf
    echo 'hw.snd.default_auto=0' >> /etc/sysctl.conf
    defaudio=$(grep pcm /dev/sndstat | grep default | awk -F: '{print $1}')
    [[ -z $defaudio ]] && return 0 || true
    echo "# to list installed sound devices: cat /dev/sndstat" >> /etc/sysctl.conf
    echo "hw.snd.default_unit=$defaudio" >> /etc/sysctl.conf
}


configure_virtualbox()
{
    # virtualbox

    # sources:
    # - https://cooltrainer.org/a-freebsd-desktop-howto/
    # - https://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/virtualization-host-virtualbox.html
    if grep vboxnet_enable /etc/rc.conf >/dev/null 2>&1; then
	return 0
    fi
    cat >> /etc/devfs.conf <<EOF

    # Allow VirtualBox network access
    own     vboxnetctl      root:vboxusers
    perm    vboxnetctl      0660
EOF
    cat >> /boot/loader.conf <<EOF

# VirtualBox
vboxdrv_load="YES"
EOF
    enable_service vboxnet
    enable_service vboxguest
    enable_service vboxservice
    kldload vboxdrv || true
    kldload vboxnetflt || true
    pw groupmod vboxusers -m tnx		# adding users to the vboxusers group
    pw groupmod operator -m tnx			# USB support
}


display_info()
{
    cat <<EOF
check that the selected sound output is correct: to list installed sound devices: cat /dev/sndstat
then check /etc/sysctl.conf for hw.snd.default_unit=xxx"
EOF
}


create_boot_env()
{
    if beadm list -H | grep post-install >/dev/null 2>&1; then
	return 0
    fi
    beadm create post-install
    beadm activate post-install
}


check_requirements
#install_user_cfgs
install_pkgs
backup_configs
configure_shells
configure_services
configure_mdns
configure_automount
configure_powerd
#configure_bluetooth
configure_ntpd
configure_bootconfig
configure_sysctl
configure_consoles
configure_CUPS
#configure_CDE
#configure_slim
configure_sound
configure_virtualbox
create_boot_env
display_info

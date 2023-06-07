#!/bin/sh 
#pragma ident	"%Z%%M%	%I%	%E% SMI"
#
# GenFin V 1.0 20080708
#

#######################################################################################
# Start Global Varialbles                                                             #
#######################################################################################

remotelab=""
IRPERF2=irperf2
IRPERF=irperf
SOURCE=irperf
IRPERF4IP=192.168.254.10
IRPERF2IP=192.168.254.24
IRPERFIP=192.168.254.2

InstOS=`uname -s`
ECHO="/usr/bin/echo"
PING="$IRPERFIP"

# Linux Specifics
if [ $InstOS = Linux ]; then
	ECHO="/usr/bin/echo -e"
	PING="-c 5 $IRPERFIP"
fi


#check to see if we are in a remote lab
if ping $PING 2>/dev/null ;then 
	echo on irperf subnet in ireland lab
else
	[ -z "$remotelab" ] && remotelab=true
fi

sysname=`uname -n`

if [ -n "$remotelab" ] ; then
	IRPERF4IP=129.156.224.10
	IRPERF2IP=129.156.224.24
	IRPERFIP=129.156.224.2
	SOURCE=$IRPERFIP
	[ `echo $sysname|grep -c gmp03` -eq 1 ] && remotelab=JLT
fi

karch=`arch -k`
arch=`arch`
OSver=`uname -v`
unamea=`uname -a`
date=`date`

[ $InstOS = Linux ] && IRPERF2IP=$IRPERF2

#######################################################################################
# End Global Varialbles                                                               #
#######################################################################################

#### Check we're not running genfin on the Install Server
if [ "$sysname" = "irperf" ] || [ "$sysname" = "alacrity" ] || [ "$sysname" = "irperf2" ]; then
	echo "What ya doing running $0 on $sysname ?"
	exit 1
fi

rsh $IRPERF2IP touch /export/bench/tmp/generic/$sysname
[ ${InstOS} = "Linux" ] && echo Linux

if [ -d /a/etc ]; then
	echo "Genfin being run on $sysname by jumpstart at $date" |tee -a /tmp/${sysname}.generic
else
	echo "Genfin being run manually at $date" |tee -a /tmp/${sysname}.generic
	ln -s / /a   ### Allows this script to be run manually after install 
fi

mkdir -p /a/export/bench

if [ -f /a/etc/release ]; then
	cat /a/etc/release >> /tmp/${sysname}.generic
else
	echo "No /a/etc/release" >> /tmp/${sysname}.generic
	cat /etc/release >> /tmp/${sysname}.generic
fi

rsh $IRPERF2IP "/export/bench/autobench/5.x/bin/watchdog -t perf_install_${sysname} -c"
rcp /tmp/${sysname}.generic $IRPERF2IP:/tmp
/usr/bin/rsh $IRPERF2IP /dom/install.times.sh $sysname
/usr/bin/rsh $IRPERF2IP "date >  /var/ns-cgi/status/lastrup/$sysname" 2>/dev/null
/usr/bin/rsh $IRPERF2IP rm /tmp/stops_latest/stops.$sysname 2>/dev/null
# Check if machine needed manual intervention and remove flag file on irperf
/usr/bin/rsh $IRPERF2IP rm /tmp/.${sysname}_notify 2> /dev/null


conffile="/a/platform/$karch/kernel/drv/bge.conf"
if [ -f $conffile ]; then
	cp $conffile ${conffile}_old
	grep "0x14e41648" $conffile > /dev/null
	cstatus=$?
	if [ $cstatus -ne 0 ]; then
		echo "Adding \"pci14e4,1648.14e4.1648\" device to bge.conf"
		echo "For support of the dual bge card"
		echo "/^bge-known-subsystems/a\\" > /tmp/sedscr
		echo "                          0x14e41648," >> /tmp/sedscr
		chmod a+x /tmp/sedscr
		sed -f /tmp/sedscr $conffile > /tmp/bge.conf
		cp /tmp/bge.conf $conffile
	fi
fi

if [ "$arch" = "i86pc" ]
then
#######################################################################################
# Update Driver Aliases for x86 Boxen                                                 #
#######################################################################################
	# add pci8086,1039 to intel releases so that
	# the dell boxes use their onboard network cards
	grep "pci8086,1039" /a/etc/driver_aliases > /dev/null
	gstatus=$?
	if [ $gstatus -ne 0 ]; then
		echo "Adding \"pci8086,1039\" device to intel stuff"
		echo " Tis for support of onboard nic on the dell boxes"
		echo "iprb \"pci8086,1039\""  >> /a/etc/driver_aliases
		echo "pci8086,1039 pci8086,1039 net pci iprb.bef \"Intel Pro/100 Network Adapter\"" >> /a/boot/solaris/devicedb/master
	fi

	# Adding pciex8086,10a7 for AMD
	grep "pciex8086,10a7" /a/etc/driver_aliases > /dev/null
	gstatus=$?
	if [ $gstatus -ne 0 ]; then
		echo "Adding \"pciex8086,10a7\" device to intel stuff"
		echo " This is for support of igb on AMD boxes"
		echo "igb \"pciex8086,10a7\""  >> /a/etc/driver_aliases
	fi

	grep "pciex8086,10a9" /a/etc/driver_aliases > /dev/null
	gstatus=$?
	if [ $gstatus -ne 0 ]; then
		echo "Adding \"pciex8086,10a9\" device to intel stuff"
		echo " This is for support of igb on AMD boxes"
		echo "igb \"pciex8086,10a9\""  >> /a/etc/driver_aliases
	fi

	grep "pciex8086,10d6" /a/etc/driver_aliases > /dev/null
	gstatus=$?
	if [ $gstatus -ne 0 ]; then
		echo "Adding \"pciex8086,10d6\" device to intel stuff"
		echo " This is for support of igb on AMD boxes"
		echo "igb \"pciex8086,10d6\""  >> /a/etc/driver_aliases
	fi

	grep "pci8086,1050" /a/etc/driver_aliases > /dev/null
	gstatus=$?
	if [ $gstatus -ne 0 ]; then
		echo "Adding \"pci8086,1050\" device to intel stuff"
		echo " Tis for support of onboard nic on the dell 8300 boxes"
		echo "iprb \"pci8086,1050\""  >> /a/etc/driver_aliases
		echo "pci8086,1050 pci8086,1050 net pci iprb.bef \"Intel Network Adapter\"" >> /a/boot/solaris/devicedb/master
	fi

	grep "pci14e4,1648.1022.2b80" /a/etc/driver_aliases > /dev/null
	gstatus=$?
	if [ $gstatus -ne 0 ]; then
		echo "Adding \"pci14e4,1648.1022.2b80\" device to x86 stuff"
		echo " Tis for support of bges on celestica box"
		echo "bge \"pci14e4,1648.1022.2b80\"" >> /a/etc/driver_aliases
	fi

	grep "pciex10de,658" /a/etc/driver_aliases > /dev/null
	gstatus=$?
	if [ $gstatus -ne 0 ]; then
		echo "Adding \"pciex10de,658\" device to x86 stuff"
		echo " This for support of nvidia on Volans box"
		echo "nvidia \"pciex10de,658\"" >> /a/etc/driver_aliases
	fi

	# Renier 31/07/2006
	# Workaround: 6449495 bug 6393691 causes x86/amd64 systems not to boot from solaris partition in s10u3
	if grep s10[s,x]_u3wos_ /a/etc/release > /dev/null 2>&1
	then
		echo "Applying workaround for  6449495"
		grep -v etc/cluster/nodeid /a/boot/solaris/filelist.ramdisk > /tmp/filelist.ramdisk
		cp /tmp/filelist.ramdisk /a/boot/solaris/filelist.ramdisk
	fi

	grep -v install /a/boot/solaris/bootenv.rc >/tmp/bootenv.rc

#######################################################################################
# Set Correct BootPath on x86 Boxen                                                   #
#######################################################################################
	BOOTPATH=`/usr/bin/rsh ${IRPERF2IP} grep $sysname /dom/ARCH_LIST | grep -v "^#" |awk '{print $4}'`
	echo "Bootpath $BOOTPATH"	
	if [ ! -z "${BOOTPATH}" ] ;then
		grep -v bootpath /tmp/bootenv.rc >/a/boot/solaris/bootenv.rc
		echo "NOW DOING setprop bootpath $BOOTPATH..." 
		echo "setprop bootpath $BOOTPATH" >>/a/boot/solaris/bootenv.rc
	fi
		
#######################################################################################
# Set Console Devices correctly on x86 Boxen                                          #
#######################################################################################
	PXELINE=`rsh ${IRPERF2IP} "grep '^$sysname ' /dom/PXE_LIST"`
	if [ ${InstOS} = "SunOS" -a -z "$PXELINE" ]; then

		CONDEV=`echo $PXELINE |awk '{print $2}'`
		[ -z "$CONDEV" ] && CONDEV=ttya
		for PXEOPTS in $PXELINE ; do
			baud=`echo $PXEOPTS| awk -F= '/baud/ {print $2}'`
		done

		if [ `echo $PXELINE |grep -c screenkeyboard` -ge 1 ]; then
			grep -v "put-device" /a/boot/solaris/bootenv.rc > /tmp/bootenv.rc
			mv /tmp/bootenv.rc /a/boot/solaris/bootenv.rc
			echo "setprop output-device screen" >> /a/boot/solaris/bootenv.rc
			echo "setprop input-device keyboard" >> /a/boot/solaris/bootenv.rc
		else
			grep -v -E "console|put-device" /a/boot/solaris/bootenv.rc > /tmp/bootenv.rc
			mv /tmp/bootenv.rc /a/boot/solaris/bootenv.rc
			echo "setprop output-device $CONDEV" >> /a/boot/solaris/bootenv.rc
			echo "setprop input-device $CONDEV" >> /a/boot/solaris/bootenv.rc
			echo "setprop console $CONDEV" >> /a/boot/solaris/bootenv.rc
			if [ ! -z "$baud" ]; then
				grep -v "tty.-mode" /a/boot/solaris/bootenv.rc >/tmp/bootenv.rc
				mv /tmp/bootenv.rc /a/boot/solaris/bootenv.rc
				echo "setprop ${CONDEV}-mode ${baud},8,n,1,-" >> /a/boot/solaris/bootenv.rc
				echo "setprop console $CONDEV" >> /a/boot/solaris/bootenv.rc
				sed "/^kernel.*unix$/ s/$/ -B console=$CONDEV/" /a/boot/grub/menu.lst > /tmp/menu.lst
				cp /a/boot/grub/menu.lst /a/boot/grub/menu.lst.pre.genfin
				mv /tmp/menu.lst /a/boot/grub/menu.lst
				sed -e "s/<propval name='label' type='astring' value='[^\']*/<propval name='label' type='astring' value='${baud}/" /a/var/svc/manifest/system/console-login.xml > /tmp/console-login.xml
				mv /tmp/console-login.xml /a/var/svc/manifest/system/console-login.xml
			fi
		fi
	fi


	# 6969659 P4 sun4v picl_initialize failed: Daemon not responding
	# Set Ontario eeproms & Fix NIC driver alias
	if [ "$remotelab" != "JLT" ] && [ `prtdiag 2>/dev/null | grep -E -c 'Sun Fire T200|Sun Fire(TM) T1000'` -ge 1 ]; then
		eeprom input-device=virtual-console
		eeprom output-device=virtual-console
		eeprom use-nvramrc?=false
		echo "Using eeprom to set input-device=virtual-console output-device=virtual-console use-nvramrc?=false"

		ont_newdrv=`grep "pciex8086,105e" /a/etc/driver_aliases`
		if [ -z "${ont_newdrv}" ] ; then
			echo "updating driver_aliases for nic with one from the boot image"
			grep "\"pciex8086,105e\"" /etc/driver_aliases >> /a/etc/driver_aliases
		fi
	fi

#######################################################################################
# Disable dtlogin if specified in /dom/NO_DTLOGIN                                     #
#######################################################################################
	disable_dtlogin=`rsh ${IRPERF2IP} "grep -c ${sysname} /dom/NO_DTLOGIN"`
	if [ -n "$disable_dtlogin" ] ; then
		if [ ${disable_dtlogin} -gt 0 ]; then
			echo "It's one of them machines which need dtlogin disabled..."
			mv /a/etc/rc2.d/S99dtlogin /a/etc/rc2.d/xS99dtlogin
		fi
	fi


######################################################################################
# Workaround for fma/pcie bug #6664330, hitting intel motherboard with Xeon chipset  #
# Added by Andrew on Wed Mar 12 16:00:41 GMT 2008                                    #
# Bug was a duplicate of #6667017, fixed in snv_91                                   #
######################################################################################
	if [ "${InstOS}" = "SunOS" ]; then
		if [ `/usr/sbin/prtdiag | grep -c "BIOS.*S[3,5]000"` -gt 0 ]; then
			buildname=`uname -v`
			if [ `echo $buildname | grep -c snv` = "1" ]; then
				buildseq=`rsh ${IRPERFIP} "/bin9/seqline $buildname"`
				build91=`rsh ${IRPERFIP} "/bin9/seqline snv_91"`
				if [ $buildseq -lt $build91 ]; then	
					#/usr/sbin/svccfg -s svc:/network/physical:default setenv DLPI_DEVONLY 1
					rcp ${IRPERF2IP}:/export/bench/autobench/5.x/src/S98plumbnics /a/etc/rc3.d/
				fi
			fi
		fi
	fi
else
	# sparc section

	# 6969659 P4 sun4v picl_initialize failed: Daemon not responding
	# Set Ontario eeproms & Fix NIC driver alias & sun4v eeproms
	if [ "$remotelab" != "JLT" ] && [ `prtdiag | grep -E -c 'T6300|Sun Fire T200|Sun Fire(TM) T1000|Enterprise T5120|Enterprise T5220|sun4v T5140|sun4v T5240'` -ge 1 ]; then
		eeprom input-device=virtual-console
		eeprom output-device=virtual-console
		eeprom use-nvramrc?=true
		eeprom > /a/eeprom.genfin
		rcp /a/eeprom.genfin ${IRPERF2IP}:/tmp/eeprom.genfin.$sysname
		echo "Using eeprom to set input-device=virtual-console output-device=virtual-console use-nvramrc?=true"

		ont_newdrv=`grep "pciex8086,105e" /a/etc/driver_aliases`
		if [ -z "${ont_newdrv}" ] ; then
			echo "updating driver_aliases for nic with one from the boot image"
			grep "\"pciex8086,105e\"" /etc/driver_aliases >> /a/etc/driver_aliases
		fi
	fi

	# Override settings if the console is set in /dom/consoles
	override_console=`rsh ${IRPERF2IP} "grep '^$sysname' /dom/consoles" | awk -F: '{print $2}'`
	if [ -n "$override_console" ]; then
		#There must be an entry in /dom/consoles

		if [ "$override_console" = "screenkeyboard" ]; then
			output_dev="screen"
			input_dev="keyboard"
		else
			output_dev=$override_console
			input_dev=$override_console
		fi

		if [ -f /a/boot/solaris/bootenv.rc ]; then
			grep -v "output-device" /a/boot/solaris/bootenv.rc >/tmp/bootenv.rc
			grep -v "input-device" /tmp/bootenv.rc > /a/boot/solaris/bootenv.rc
			echo "setprop output-device $output_dev" >> /a/boot/solaris/bootenv.rc
			echo "setprop input-device $input_dev" >> /a/boot/solaris/bootenv.rc
		else
			eeprom output-device=$output_dev
			eeprom input-device=$input_dev
			#eeprom use-nvramrc?=false
			echo "Using eeprom to set input-device=$output_dev output-device=$output_dev" # use-nvramrc?=false"
		fi
	fi

# End of if i86pc else section
fi

if [ "$remotelab" != "JLT" ]; then

	DR1=`sed -e 's/#.*$//g' /etc/hosts | grep ${sysname} | grep -v localhost | awk '{print $1 " " $2}' |grep "${sysname}$" | sort -u | awk '{print $1}' | awk -F'.' '{print $1"."$2"."$3".1"}'`
	if [ -f /a/etc/defaultrouter ] ; then
		DR=`cat /a/etc/defaultrouter`
		if [ ! -z "$DR1" ] && [ "$DR1" != "$DR" ] ; then
			echo "$0: setting defaultrouter to be $DR1 instead of $DR"
			echo $DR1 > /a/etc/defaultrouter
		fi
	elif [ ! -z "$DR1" ] ; then
		echo "$0: setting defaultrouter to be $DR1"
		echo $DR1 > /a/etc/defaultrouter
	fi

	# PXE machines need to clean their DHCP stuff after they've got installed
	if [ "$arch" = "i86pc" ] ; then
		if [ -z "$remotelab" ] ; then
			MCS=${sysname}
			CMD="/dom/pxe-del $MCS"
			echo "PXE del command: $CMD"
			echo "/usr/bin/rsh $DR $CMD"
			/usr/bin/rsh $DR $CMD
			/usr/bin/rsh `echo $DR|sed -e 's/254/1/'` "perl -e 'print time' >>/tmp/$sysname" 
		elif [ "$remotelab" = "LRT" ]; then
			MCS=${sysname}
			CMD="/dom/pxe-del $MCS"
			rsh $IRPERF2IP "/dom/pxe-del $MCS $DR"
		else
			/usr/bin/rsh $IRPERF2IP "perl -e 'print time' >>/tmp/$sysname" 
			echo "Don't know how to clean up in lab $remotelab"
		fi
	fi
fi


##########################################################################################
# Work Around for CR: 6800809                                                            #
##########################################################################################
IOMMU_BUILD=0
[ `echo $OSver |grep -c snv` -gt 0 ] && IOMMU_BUILD=`echo $OSver |sed "s/[a-z,_]//g"`
[ `echo $OSver |grep -c osol` -gt 0 ] && IOMMU_BUILD=`echo $OSver |awk -F\- '{print $NF}' |sed "s/[a-z,_]//g"`
IOMMU_SYS=`rsh $IRPERF2IP "grep -c $sysname /dom/workarounds/IOMMU_CR_6800809"`

if [ "$IOMMU_SYS" -gt 0 -a "$IOMMU_BUILD" -gt 100 -a "$IOMMU_BUILD" -lt 104 ]; then
	echo "Adding Workaround for IOMMU hang"
	sed -e 's/^kernel.*$/& -B intel-iommu=no/g' /a/boot/grub/menu.lst > /tmp/menu.iommu
	cat /tmp/menu.iommu > /a/boot/grub/menu.lst
fi

if [ "$IOMMU_SYS" -gt 0 -a "$IOMMU_BUILD" -gt 117 -a "$IOMMU_BUILD" -lt 133 ]; then
	echo "Adding Workaround for IOMMU hang"
	sed -e 's/^kernel.*$/& -B intel-iommu=no/g' /a/boot/grub/menu.lst > /tmp/menu.iommu
	cat /tmp/menu.iommu > /a/boot/grub/menu.lst
fi

if [ "$IOMMU_SYS" -gt 0 -a "$IOMMU_BUILD" -eq 133 ]; then
	echo "Adding Workaround for IOMMU hang"
	sed -e 's/^kernel.*$/& -B immu-enable=false/g' /a/boot/grub/menu.lst > /tmp/menu.iommu
	cat /tmp/menu.iommu > /a/boot/grub/menu.lst
fi

#set default stripe to no
STRIPE=0

# NFSv4 domain set to avoid interactive jumpstarts
#   gratuitously robbed from Rick Mestas script on on10.eng

if [ "$InstOS" = "SunOS" -a -z "$remotelab" ]; then

	NFS4_DOMAIN=ireland.sun.com
	FILE=/a/etc/default/nfs
	STATE=/a/etc/.NFS4inst_state.domain
	VAR=NFSMAPID_DOMAIN
	VALUE=${NFS4_DOMAIN}
	
	TFILE=${FILE}.$$
	sed -e "s/^#[    ]*${VAR}=.*\$/${VAR}=${VALUE}/" ${FILE} > ${TFILE}
	mv ${TFILE} ${FILE}

	IFILE=`echo ${FILE} | sed -e "s|^/a||g"`
	#PERM=`grep "^${IFILE} e" /a/var/sadm/install/contents | (read f1 f2 f3 f4 f5 ; echo $f4)`
	PERM=`grep "^${IFILE} e" /a/var/sadm/install/contents | awk '{print $4}'`

	if [ -n "$PERM" ] ; then
		echo "running: chmod $PERM $FILE"
		chmod $PERM $FILE
	fi
	touch $STATE
fi


##############################################################################
###
###	Sets Root Password to Group Default					
###
##############################################################################
set_root() {
	# PASSWD=i6fWmM0jNRSts
	PASSWD=39mEDEByrfYRc
	cp /a/etc/shadow /a/etc/shadow.orig

	nawk -F: '{ if ( $1 == "root" ) 

		printf"%s:%s:%s:%s:%s:%s:%s:%s:%s\n",$1,passwd,$3,$4,$5,$6,$7,$8,$9

	else

		printf"%s:%s:%s:%s:%s:%s:%s:%s:%s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9

	}' passwd="$PASSWD" /a/etc/shadow.orig > /a/etc/shadow

	# remove the temporary file
	rm -f /a/etc/shadow.orig
	touch /a/noautoshutdown
}

system_setting() {

##############################################################################
###
###	Sets General System Defaults
###
##############################################################################
###
###	Stop questions after install
###
if [ -f /a/usr/openwin/bin/kdmconfig ]
then
mv /a/usr/openwin/bin/kdmconfig /a/usr/openwin/bin/kdmconfig.old
echo "exit 0" > /a/usr/openwin/bin/kdmconfig
chmod +x /a/usr/openwin/bin/kdmconfig
fi

cat  >/a/etc/.sysIDtool.state <<EOF_1
1	# System previously configured?
1	# Bootparams succeeded?
1	# System is on a network?
1	# Autobinder succeeded?
1	# Network has subnets?
1	# root password prompted for?
1	# locale and term prompted for?
1	# security policy in place
sun
EOF_1
rm /a/etc/.UNCONFIGURED

sed -e 's/TZ=PST8PDT/TZ=GB-Eire/' /a/etc/default/init > /tmp/init.$$

mv /tmp/init.$$ /a/etc/default/init

sed -e 's/CONSOLE/#CONSOLE/' /a/etc/default/login > /tmp/tmp.$$
sed -e 's/PASSREQ=YES/PASSREQ=NO/' /tmp/tmp.$$ > /tmp/login.$$
mv /tmp/login.$$ /a/etc/default/login

cat >/a/.rhosts	<<EOF_2
irperf relay
irperfa relay
irperfb relay
irperfc relay
irperfd relay
irperfe relay
irperf2 relay
irperf2a relay
irperf2b relay
irperf2c relay
irperf2d relay
irperf2e relay
+ +
EOF_2

if [ -d /a/root ] && [ `uname -s` = "SunOS" ] ; then
	cp -p /a/.rhosts /a/root
fi

###
###	Adds Users Needed to run benchmarks 
###
cat >>/a/etc/passwd <<EOF_3
cdebench:x:4322:1:CDE Bench Account:/usr1/cdebench:/bin/csh
viewperf:x:5325:1:ViewPerf Account:/export/bench/graphics/viewperf:/bin/csh
bbench:x:4328:1:Browser Benchmark Account:/export/bench/java/bbench:/bin/csh
glperf:x:4324:1:GLperf Account:/export/bench/graphics/GLperf:/bin/csh
xglbench:x:4324:1:xglbench Account:/export/bench/graphics/xglbench:/bin/csh
xengine:x:4329:1:Xengine Benchmark Account:/export/bench/graphics/xengine:/bin/csh
jmark:x:4320:1:Jmark account:/export/bench/java/jmark20:/bin/csh
caffeine:x:4324:1:Caffeine 3.0 account:/export/bench/java/caffeine30:/bin/csh
notes:x:5000:1:xglbench Account:/export/bench/lotus:/bin/csh
netscape:x:4324:1:netscape account:/export/bench/isv/netscape_test:/bin/csh
proe:x:4327:1:proe eng account:/export/bench/isv/proe:/bin/csh
sobench:x:4330:1:star office account:/export/bench/sobench/home/user01:/bin/csh
oracle:x:5001:5000:oracle account:/export/home/oracle:/usr/bin/ksh
mysql:x:1010:1010:MySQL Default User:/export/bench/mysql:/usr/bin/sh
applmgr:x:5002:5000:oracle applications account:/export/dsk1/app/applmgr:/usr/bin/ksh
dbbench:x:30:5000::/export/home/dbbench:/usr/bin/csh
ecuser:x:60003:60001:Ecperf access:/export/ecperf:/bin/csh
gnomeper:x:60004:1::/export/bench/gnomeper:/bin/sh
EOF_3

cat >>/a/etc/shadow <<EOF_4
cdebench:/SjA7Xf3RfenM:9449::::::
gbench:/SjA7Xf3RfenM:9449::::::
gbench2:/SjA7Xf3RfenM:9449::::::
bbench:/SjA7Xf3RfenM:9449::::::
viewperf:/SjA7Xf3RfenM:9449::::::
glperf:/SjA7Xf3RfenM:9449::::::
xglbench:/SjA7Xf3RfenM:9449::::::
xengine:/SjA7Xf3RfenM:9449::::::
jmark:/SjA7Xf3RfenM:9449::::::
netscape:/SjA7Xf3RfenM:9449::::::
caffeine:/SjA7Xf3RfenM:9449::::::
notes:oGJXboX1nTGhM:9449::::::
proe:/SjA7Xf3RfenM:9449::::::
sobench:/SjA7Xf3RfenM:9449::::::
oracle:A0Jv/fVfoPB.s:11197::::::
mysql:4jCSGk2OSClVg:13335::::::
applmgr:jxEKAB4eaZb6E:11204::::::
dbbench:ukTn7ddvTroKw:11305::::::
ecuser:x:12233::::::
gnomeper:whuE.eIJTl2dA:12487::::::
EOF_4

# Add group required for Oracle Applications & tpcso
# And the one for CDEbench
cat >>/a/etc/group <<EOF_G
dba::5000:
cde::9000:
EOF_G

###	Allows packages adds without interaction
###
if [ `uname` = "SunOS" ] ; then
cat >/a/var/sadm/install/admin/default <<EOF_5
mail=
instance=overwrite
partial=nocheck
runlevel=nocheck
idepend=nocheck
rdepend=nocheck
space=nocheck
setuid=nocheck
conflict=nocheck
action=nocheck
basedir=default
EOF_5
fi
# End Allows packages adds without interaction

# Removing webstart
cat >>/a/etc/rc2.d/S95webstop<<EOF_WEBSTART
#!/bin/sh
/usr/bin/echo "Checking for Webstart....\c"
[ -f /etc/init.d/webstart ] && rm -f /etc/rc2.d/S96webstart /etc/init.d/webstart
[ -f /etc/init.d/install ] && rm -f /etc/rc2.d/S96install /etc/init.d/install
rm -f /etc/rc2.d/S95webstop

exit
EOF_WEBSTART
chmod 744 /a/etc/rc2.d/S95webstop


}

savecorefiles(){
cat > /a/etc/rc3.d/S97savecorefiles <<EOF_cores
#!/bin/sh

if [ -x /usr/bin/coreadm ]; then
	havesetup=\`rsh $IRPERF2IP ls /export/bench/configs/$sysname/coreadm.setup.sh\`
	if [ -n "\$havesetup" ]; then
		echo "enabling corefiles to be saved in via a coreadm.setup.sh script"
		rcp $IRPERF2IP:/export/bench/configs/$sysname/coreadm.setup.sh /var/tmp
		sh -x /var/tmp/coreadm.setup.sh
	else
		echo "enabling corefiles to be saved in /var/core..."
		mkdir -p /var/core
		coreadm -g /var/core/core.%f.%p.%t -e global
		coreadm -d process
		coreadm -e log
		coreadm -e global-setid
		coreadm -e proc-setid
	fi
else
	echo "no coreadm, thus not enabling corefiles to be saved..."
fi
rm /etc/rc3.d/S97savecorefiles

EOF_cores

chmod a+x /a/etc/rc3.d/S97savecorefiles
}

changedumpdir() {

cat > /a/etc/rc3.d/S97changedumpdir <<EOF_dump
#!/bin/sh

mount |grep /export/bench >/dev/null 2>&1
if [ \$? -eq 0 ] && [ -x /usr/sbin/dumpadm ]
then
	mv /var/crash /export/bench
	dumpadm -s /export/bench/crash/${sysname}
	ln -s /export/bench/crash /var/crash
else
	#grep -i opensolaris /etc/release > /dev/null 2>&1
	grep -E -ice '(opensolaris|solaris next|solaris 11 express)' /etc/release > /dev/null 2>&1
	if [ \$? -eq 0 ]; then
		myname=`uname -n`
		mkdir -p /var/crash/\$myname
		dumpadm -s /var/crash/\$myname
		dumpadm -y 
	else
		echo "no dumpadm or /export/bench not mounted, not changing dump location" >/dev/console
	fi
fi

mv /etc/rc3.d/S97changedumpdir /var/tmp
EOF_dump

chmod a+x /a/etc/rc3.d/S97changedumpdir

}

copy_testfile_benchmarks(){
cat >>/a/etc/rc3.d/S99benchconfig <<EOF_ctb

	## Enough's Enough. Copying only what's needed
	# /auto is already there so use /auto/benchmarks/*
	for bench in \`grep b_name /auto/testfiles/TESTFILE.${sysname} | awk '{print \$2}' | sort -u\`; do
		install_script=/auto/benchmarks/\${bench}/install
		[ -x \$install_script ] && \$install_script ${IRPERF2IP}
	done

EOF_ctb
}

copy_powermeter_things(){
cat >>/a/etc/rc3.d/S99benchconfig <<EOF_pm
	## power meter stuffies..
	mkdir -p /auto/pm
	cd /net/${IRPERF2}/export/bench/configs/pm
	find . -name "*${sysname}*" | cpio -pvdum /auto/pm
	find bin | cpio -pvdum /auto/pm
	[ -f tty.${sysname} ] && cp ptd_ports.\`cat tty.${sysname} | awk '{print \$1}'\` /auto/pm
EOF_pm
}

xen() {
	DOMU=$sysname
	if [ `echo $DOMU | grep -c domu` = "1" ]; then
		DOM0=`echo $DOMU | awk -F\- '{print $1}'`
	else
		DOM0=$DOMU
	fi
	if [ $DOMU != $DOM0 ]; then
		echo "This is a xen domU, copying in xorg.conf to workaround CR 6915132..."
		rcp ${IRPERF2IP}:/export/bench/system/xen/scripts/xorg.conf.workaround /a/etc/X11/xorg.conf
		echo "This is a xen domU, telling  the dom0 to reboot me now..."
		DOM0_IP=`/usr/bin/rsh $IRPERF2IP "grep $DOM0$ /etc/hosts" | head -1 | awk '{print $1}'`
		/usr/bin/rsh $DOM0_IP "touch /tmp/${DOMU}_has_halted"
		echo "done!"
		halt
		exit 0
	fi
}

x86_reboot_hack() {

	if [ "${InstOS}" = "Linux" ]; then
		/sbin/reboot
		sleep 999
	fi

	# Else Assume SunOS
	echo "\n\nInitiating x86 Reboot Hack...."
	installrc=/etc/rcS.d/S20fixinstall
	[ -d /a/etc/rcS.d ] && installrc=/a/$installrc

	cat >>$installrc <<EOF_install
#!/bin/sh
svccfg <<_EOF
select svc:/milestone/multi-user-server
delprop install_multi-user-server
select svc:/milestone/inetd-upgrade
delprop install_inetd-upgrade
exit
_EOF
svcadm refresh svc:/milestone/multi-user-server:default
svcadm enable svc:/milestone/multi-user-server:default
svcadm refresh svc:/milestone/inetd-upgrade:default
svcadm enable svc:/milestone/inetd-upgrade:default
rm -f /etc/rcS.d/S20fixinstall
EOF_install
 
	chmod 755 $installrc
	sleep 180
	ptree
	/sbin/sync
	/usr/sbin/reboot
}

 
#############################################################################
###
###	Generic Start to Copy RC script
###
##############################################################################
start_rc_script(){

cat >/a/etc/rc3.d/S99benchconfig <<EOF_6
#!/bin/sh
	# temporary stop dtlogin
	[ -x /lib/svc/bin/svc.startd ] && svcadm disable -t application/cde-login
	[ -x /etc/init.d/dtlogin ] && /etc/init.d/dtlogin stop

	#if [ \`grep -ic opensolaris /etc/release\` -gt 0 ]; then
	if [ \`grep -E -ice '(opensolaris|solaris next|solaris 11 express)' /etc/release\` -gt 0 ]; then
		rolemod -K type=normal root
	fi

	# disable pkg/update crontab entry
	svcadm disable pkg/update

	# Send alert if we haven't rebooted after genfin
	echo "Clear watchdog reboot_after_genfin_check_${sysname}"
	rsh $IRPERFIP "/export/bench/autobench/5.x/bin/watchdog -t reboot_after_genfin_check_${sysname} -c"
	[ "\$?" != "0" ] && echo "Failed"

	# send things to console if we're greenlined
	[ -x /lib/svc/bin/svc.startd ] && exec 1> /dev/sysmsg 2>&1


	if [ "$remotelab" ] ;then
		/usr/bin/echo "$IRPERF2IP irperf2\n$IRPERFIP irperf\n$IRPERF4IP irperf4 irperf4.ireland" >>/etc/hosts

	else
		# lets get the hosts file and stop nis asap
		/bin/echo "Copying the hosts file from Install Server ($IRPERF2IP) to this box... \c"
		#/usr/bin/rsh $IRPERF2IP "cat /etc/hosts" >> /etc/hosts
		# need this to be a tad more smarter instead of a simple dump
		#/usr/bin/rsh $IRPERF2IP "cat /etc/hosts" >> /etc/hosts

		rcp $IRPERF2IP:/etc/hosts /tmp/hosts.irperf
		cp /etc/hosts /tmp/hosts.system
		cp /etc/hosts /etc/hosts.pre.genfin
		cat /tmp/hosts.system /tmp/hosts.irperf > /tmp/hosts.new
		# we change localhost entries and sed out the loghost from '...irperf loghost..'
		grep -v -E "localhost|::" /tmp/hosts.new | sed -e 's/loghost//g' | sort -u > /tmp/hosts.new2
		echo 127.0.0.1 localhost loghost >> /tmp/hosts.new2
		echo ::1 localhost loghost >> /tmp/hosts.new2
		# /etc/hosts is a symlnik to /etc/inet/hosts, don't overwrite it
		cp /tmp/hosts.new2 /etc/inet/hosts

	fi
	# Fix for Linux long sendmail timeout at boot
	if [ "$InstOS" = "Linux" ]; then
		echo "127.0.0.1 localhost.localdomain localhost ${sysname}" >/tmp/hosts
		grep -v localhost /etc/hosts >>/tmp/hosts
		mv /tmp/hosts /etc
	fi

	if [ "$remotelab" != "JLT" ]; then
		mv /var/yp /var/_yp
		[ -f /etc/defaultdomain ] && mv /etc/defaultdomain /etc/Not.using.defaultdomain
		[ -z "$remotelab" ] && cp /etc/nsswitch.files /etc/nsswitch.conf
	fi

	# Change setting in sshd_config to allow ssh in as root
	if [ -f /etc/ssh/sshd_config -a \`grep -c "PermitRootLogin no" /etc/ssh/sshd_config\`"" -eq 1 ]; then
		cp /etc/ssh/sshd_config /tmp
		sed -e 's/PermitRootLogin no/PermitRootLogin yes/' < /tmp/sshd_config > /etc/ssh/sshd_config
		if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
			/lib/svc/method/sshd -c
		fi
	fi

	if [ -x /usr/sbin/netservices ]; then
		echo "[ enabling /usr/bin/rsh and nfs/client to bypass secure by default ]"
		svcadm enable svc:/network/login:rlogin
		svcadm enable svc:/network/nfs/client:default
		svcadm disable telnet
		inetadm  -e network/rpc/rstat
		inetadm  -e network/rexec
		inetadm  -e network/shell:default
	else
		have_telnet=\`grep '^telnet' /etc/inetd.conf\`
		gstatus=\$?
		if [ \$gstatus -eq 0 ]; then
			grep -v '^telnet' /etc/inetd.conf > /tmp/inetd.conf.notelnet
			cp /etc/inetd.conf /etc/inetd.conf.with.telnet
			cp /tmp/inetd.conf.notelnet /etc/inetd.conf
			pkill -1 inetd
		fi
	fi

	rcp -p $IRPERFIP:/export/bench/autobench/5.x/bin/watchdog /var/tmp
	/var/tmp/watchdog -p $IRPERFIP -t s99benchconfig_$sysname -n 120 -m "s99benchconfig on $sysname has taken much longer than expected. Check the rig has installed. It was running $unamea"
	echo "########################################################################"
	echo "###                                                                    #" 
	echo "###	Transferring Benchmarks ... Please Wait                      #"
	echo "###                                                                    #" 
	echo "########################################################################"

	rcp -p $IRPERF2IP:/export/bench/autobench/5.x/bin/btimer.sh /var/tmp
	/var/tmp/btimer.sh start S99benchconfig $IRPERF2IP

	# greenline restarts S99benchconfig on reboot..  the dumb daft thing
	if [ -f /tmp/S99benchconfig.is.running ]; then
		echo "greenline wants me to start again does it ?  feck off"
		exit 0
	else
		touch /tmp/S99benchconfig.is.running
	fi
	
	irperfcnt=1
	up=0
	if [ -n "$remotelab" ] ; then
		up=1;
	fi
	while [ \$up -eq 0 ]; do
		if \`cd /net/${IRPERF2}/export/bench\`; then
			echo "install server is up.."
			cd /
			umountall -F nfs
			up=1
		else
			sleep	60
			echo "WAITING FOR INSTALL SERVER to BOOT"
			echo " count is at \$irperfcnt"
			irperfcnt=\`expr \$irperfcnt + 1\`

			if [ \$irperfcnt -ge 10 ]; then
				echo "autofs not up ?  I'm rebooting..."
				reboot
			fi
				
		fi
	done

	for req_dirs in bench dsk1 dsk2
	do
		if [ ! -d /export/\$req_dirs ]; then
			mkdir /export/\$req_dirs 
			chmod 777 /export/\$req_dirs
		fi
	done

	usezfs=`rsh $IRPERFIP ls /export/install/config/$sysname/${sysname}.zfs`
	if [ -n "$usezfs"  ]; then
		echo "System uses ZFS root by default"
		df -l -F zfs / > /dev/null 2>&1
		if [ \$? -ne 0 ]; then
			echo "But we have a ufs root, setting flag"
			touch /var/tmp/UFSROOT
		fi
	fi

	### Begin Autobench Transfer
	[ ! -f /usr/bin/rsync ] && rcp ${IRPERF2IP}:/export/software/rsync/rsync.$arch /usr/bin/rsync
	/var/tmp/btimer.sh start S99copy_autobench $IRPERF2IP

	mkdir -p /export/bench
	echo using rsync with exclude options
	rsync -e rsh -az --exclude testfiles --exclude nextrun ${IRPERF2IP}:/export/bench/autobench /export/bench
	ln -s /export/bench/autobench/5.x /auto

	# copy over just the nextrun and testfile(s) for this machine
	mkdir -p /auto/nextrun /auto/testfiles/defaults
	rsync -e rsh -az ${IRPERF2IP}:/auto/testfiles/TESTFILE.$sysname /auto/testfiles
	rsync -e rsh -az ${IRPERF2IP}:/auto/testfiles/defaults/TESTFILE.$sysname /auto/testfiles/defaults
	rsync -e rsh -az ${IRPERF2IP}:/auto/nextrun/NEXTRUN.$sysname /auto/nextrun

	# Pull any stats tools that are specified
	mkdir -p /auto/stats/$OS

	if [ -n "$remotelab" ] ; then
		echo ${IRPERFIP} > /auto/INSTALL_SERVER
		echo "remotelab=${remotelab}" > /auto/REMOTE_LAB
		echo "IRPERFIP=${IRPERFIP}" >> /auto/REMOTE_LAB
		echo "IRPERF2IP=${IRPERF2IP}" >> /auto/REMOTE_LAB
		echo "PERF_SERVER=${IRPERFIP}" >> /auto/REMOTE_LAB
		echo "PERF_SERVER2=${IRPERF2IP}" >> /auto/REMOTE_LAB
		cp /auto/autobench.vars /auto/autobench.vars.orig
		sed -e 's/irperf2/'$IRPERF2IP'/g' \
			-e 's/irperf/'$IRPERFIP'/g' \
			< /auto/autobench.vars.orig > /auto/autobench.vars
		echo "remotelab=${remotelab}" >> /auto/autobench.vars
		echo "def_perf_server=${IRPERFIP}" >> /auto/autobench.vars
		echo "export remotelab" >> /auto/autobench.vars
		echo "export def_perf_server" >> /auto/autobench.vars
	else
		echo ${IRPERF2} > /auto/INSTALL_SERVER
	fi
	/var/tmp/btimer.sh end S99copy_autobench $IRPERFIP


	# Fixes for random Build Issues
	echo "/usr/bin/rsync -e rsh -az ${IRPERF2IP}:/export/install/config/fixes/ /auto/buildfixes"	
	/usr/bin/rsync -e rsh -az ${IRPERF2IP}:/export/install/config/fixes/ /auto/buildfixes
	for script in \`ls /auto/buildfixes/*\`; do \$script; done 	

	if prtdiag | grep "[xX]45[04]0"; then
		echo "Installing SUNWhd on Thumper/Thor"
		rcp ${IRPERF2IP}:/export/software/firmware/SUNWhd-1.07.pkg /tmp
		if [ -f /tmp/SUNWhd-1.07.pkg ]; then
			pkgadd -d /tmp/SUNWhd-1.07.pkg all
		fi
	fi

	#Pull the Testfile benchmarks
	/auto/bin/install_benchmarks.sh
	
	rcp ${IRPERFIP}:/export/work/ASR/configureASR.sh /tmp
	sh -x /tmp/configureASR.sh > /var/tmp/configureASR.out 2>&1


	#setup ipoib 
	/auto/bin/ipoib.sh

cd /
EOF_6
}

install_time(){
cat >>/a/etc/rc3.d/S99benchconfig <<EOF_install
	rcp $IRPERF2IP:/tmp/$sysname /tmp
	start=\`head -1 /tmp/$sysname |cut -d' ' -f 4\`
	end=\`tail -1 /tmp/$sysname |cut -f1\`	
	if [ "\$end" -a "\$start" ] ;then
		mkdir -p /auto/Results/installtime/100
		echo "1	" \`expr \$end - \$start\` >/auto/Results/installtime/100/plot_var
	fi
	rsh $IRPERF2IP rm /tmp/$sysname
EOF_install
}

end_rc_script(){

	# for snv_14 we're missing the kbtrans module, which panics the box if
	# its missing, see bug 6270072
	if [ ! -f /a/kernel/misc/sparcv9/kbtrans ] && [ -d /a/kernel/misc/sparcv9 ] ; then
		echo "coping the missing kbtrans module"
		cp /kernel/misc/sparcv9/kbtrans /a/kernel/misc/sparcv9/kbtrans
	fi

cat >>/a/etc/rc3.d/S99benchconfig <<EOF_C
 
##############################################################################
###
###     Set up Harness Defaults
###
##############################################################################
	if [ "$karch" = "sun4v" ] ; then
		/auto/bin/checkresources.sh
	fi

	echo 1 > /auto/TESTNUM
	echo 1 > /auto/RUNNUM

	rm /auto/run_locks/* 2>/dev/null

	# network settings done here
	rm /etc/hostname6.* 2>/dev/null
	BUILD=\`cat /auto/nextrun/NEXTRUN.$sysname\`

	#ls for linux automount issues
	mkdir -p /export/bench/autobench/5.x/ifconfigs
	rcp -r ${IRPERF2IP}:/export/install/config/$sysname/ifconfig.${InstOS} /export/bench/autobench/5.x/ifconfigs/$sysname 2>/dev/null
	IFDIR=/export/bench/autobench/5.x/ifconfigs/$sysname

	ifcfg_sysbld_dir=/export/install/config/$sysname/ifconfig.\${BUILD}
	[ -d "\${ifcfg_sysbld_dir}" ] && IFDIR=\${ifcfg_sysbld_dir}

	## Setting this up as a standard directory archive so we can just do a find|cpio
	## Doing an ls on the thing cause Linux dont seem to be installin it
	ls $IFDIR 2>&1 >/dev/null
	echo "Adding NIC configs...."
	if [ -d \$IFDIR ]; then
		cd \$IFDIR
		#find ./ |grep -v -E "hosts|client" |cpio -pdum /
		#cat etc/hosts >>/var/tmp/hosts
		find ./ |grep -v -E "/hosts|netmasks|client" |cpio -pdum /
		cat etc/hosts >> /etc/hosts
		cat etc/netmasks >> /etc/netmasks
	fi

	mkdir -p  /export/bench/autobench/5.x/configs
	rsync -e rsh -az ${IRPERF2IP}:/export/bench/configs/defaults /export/bench/autobench/5.x/configs
	rsync -e rsh -az ${IRPERF2IP}:/export/bench/configs/$sysname /export/bench/autobench/5.x/configs 2>/dev/null

	if [ "$remotelab" != "JLT" ]; then
		## Manually generate netmasks unless theres one already provided in $IFDIR/etc
		if [ ! -f \$IFDIR/etc/netmasks -a $InstOS = "SunOS" ]; then
			mv /etc/netmasks /etc/netmasks.orig
			for ifs in \`ls /etc/hostname.* 2>/dev/null\`; do
				sys=\`cat \$ifs\`
				nmask=\`grep \$sys\$ /etc/hosts | head -1 | awk '{FS="."}{print \$1"."\$2"."\$3".0  255.255.255.0"}'\`
				echo \$nmask >>/etc/netmasks
			done
		fi
	fi

	#Some Debugging stuff - Colm
	mkdir -p /var/tmp/network_setup
	cp /etc/hosts /var/tmp/network_setup
	cp /etc/netmasks /var/tmp/network_setup
	cp /etc/hostname* /var/tmp/network_setup
	sort -u /etc/hosts > /etc/hosts.tmp && cat /etc/hosts.tmp > /etc/hosts
	cp /etc/hosts /var/tmp/network_setup/hosts.sorted


	## Copy our Disk_setup configs over to the SUT
	mkdir /auto/disk_setup
	DS_PATH=${IRPERF2IP}:/export/install/config/$sysname/DiskSetup
	rcp -pr \$DS_PATH /auto/disk_setup/$sysname
	[ -f /auto/disk_setup/$sysname/DiskSetup ] && /auto/disk_setup/$sysname/DiskSetup

	## Check for osol, this will be used again later
	#OSOL=\`grep -ic opensolaris /etc/release\`
	if [ -f /usr/gnu/bin/grep -E ] ; then 
		OSOL=\`/usr/gnu/bin/grep -E -ice '(opensolaris|solaris next|solaris 11 express)' /etc/release\`
	else 
		OSOL=\`/usr/bin/grep -E -ice '(opensolaris|solaris next|solaris 11 express)' /etc/release\`
	fi
	

	## Configure extra Disks 
	if [ $InstOS = SunOS -a -d /auto/disk_setup/$sysname ]; then
		DSETUP=/auto/bin/sol_disksetup.sh
		if [ \$OSOL -gt 0 ]; then
			DSETUP=/auto/bin/osol_disksetup.sh
			rolemod -K type=normal root
		fi
		\$DSETUP
	fi

	# Do we need run Linux specific config stuff
	if [ $InstOS = Linux ]; then
		/auto/bin/pull_linux_jvm.sh
		/auto/bin/linux/install_latest_oplin_drv.sh
	fi

	# do we have a specific xorg.conf ?  OS specific even ? With nVidia ?
	xorg_conf=""
	norm_xorg_conf=/auto/configs/$sysname/X11/xorg.conf
	os_xorg_conf=\${norm_xorg_conf}.\`uname\`

	if [ -f \${os_xorg_conf}.nvidia -a -f /usr/X11/lib/modules/drivers/nvidia_drv.so ]; then
		echo "a custom nvidia OS specific xorg.conf was specified"
		echo "using \${os_xorg_conf}.nvidia"
		xorg_conf=\${os_xorg_conf}.nvidia
	elif [ -f \$os_xorg_conf ]; then
		echo "a custom OS specific xorg.conf was specified"
		echo "using \$os_xorg_conf"
		xorg_conf=\$os_xorg_conf
	elif  [ -f \$norm_xorg_conf ]; then
		echo "a custom non-OS specific xorg.conf was specified"
		echo "using \$norm_xorg_conf"
		xorg_conf=\$norm_xorg_conf
	fi

	[ ! -z "\$xorg_conf" ] && cp \$xorg_conf /etc/X11/xorg.conf

	cd /export/bench
	[ "$karch" = "sun4v" ] && karch=sun4u
	for i in \`ls -d */*.$arch */*.$karch\`; do
		name=\`echo \$i | awk -F. '{print \$1}'\`
		ln -s /export/bench/\$i /export/bench/\$name
	done
	rsync -e rsh -a ${IRPERF2IP}:/export/bench/software.${arch}/src/statit /tmp/
	cd /tmp/statit

	if [ -n "$remotelab" ] ; then
		sh comp ${IRPERFIP}
	else
		sh comp 
	fi
	chown root /usr/bin/statit 
	chmod 755 /usr/bin/statit 
	chmod u+s /usr/bin/statit

	/usr/bin/echo "Copying diff_kstat /usr/bin....\c"
	if [ $InstOS =  "Linux" ] ; then
		echo "#!/bin/sh" > /usr/bin/diff_kstat
		echo exit 0 >> /usr/bin/diff_kstat
		chmod a+x /usr/bin/diff_kstat
	else
		rcp -p ${IRPERF2IP}:/export/software/tools/diff_kstat.$arch /usr/bin/diff_kstat
	fi
	echo "Done\n"

	if [ ! -x /usr/bin/nicstat ]; then
		/usr/bin/echo "Copying nicstat to /usr/bin...\c"
		rcp ${IRPERF2IP}:/export/software/tools/nicstat/nicstat.$arch /usr/bin/nicstat
		echo "Done\n"
	fi

	# Dont install this on non Solaris installs!
	if  [ "$InstOS" = "SunOS" ]; then
	DTK_version=0.99
	if [ -d /opt/DTT ]; then
		echo "$0: symlinking DTrace toolkit from /opt/DDT to /opt/DTraceToolkit-\$DTK_version"
		ln -s /opt/DTT /opt/DTraceToolkit-\$DTK_version
	elif [ ! -d /opt/DTraceToolkit-\$DTK_version ]; then
		/usr/bin/echo "Copying DTrace toolkit to /opt...\c"
		rsync -e rsh -az ${IRPERF2IP}:/export/software/tools/DTraceToolkit-\$DTK_version /opt
		echo "Done\n"
	fi
	fi

	if [ ! -d /var/spool/calendar ]; then
		mkdir /var/spool/calendar
	fi 

	if [ -f /boot/solaris/play.scr ]; then
		rm /boot/solaris/play.scr
	fi


	# add_alias_hostname is set in one of the above functions (eg zdbench)
	if [ "\$add_alias_hostname" != "" ]; then
		hostline=\`grep ${sysname}\$ /etc/hosts | head -1\`
		grep -v ${sysname}\$ /etc/hosts > /tmp/hosts.tmp
		echo "\$hostline \$add_alias_hostname" >> /tmp/hosts.tmp
		mv /tmp/hosts.tmp /etc/hosts
	fi

	# Dont delete, just move it S99benchconfig  ;)
	mv /etc/rc3.d/S99benchconfig /var/tmp

	[ -z "$remotelab" ] && cp /etc/nsswitch.files /etc/nsswitch.conf 

	# Before backing up system file check if we need to allow nmi
	if [ "$InstOS" = "SunOS" ]; then
		HAS_SC=`rsh $IRPERFIP /bin9/has_sc ${sysname}`
		if [ ! -z "\$HAS_SC" ] && [ "\$HAS_SC" = "1" ]; then
			/usr/bin/echo "set pcplusmp:apic_kmdb_on_nmi = 1" >>/etc/system
			/usr/bin/echo "set pcplusmp:apic_panic_on_nmi = 1" >>/etc/system
		fi
		/usr/bin/echo "set snooping=1" >>/etc/system
		/usr/bin/echo "set snoop_interval=90000000" >>/etc/system
		[ 0"` grep -c ${sysname} /auto/no_moddebug `" -eq 0 ] && /usr/bin/echo "set moddebug=0x80000000" >>/etc/system
	fi
	cp /etc/system /etc/system.autobench


	if [ "$arch" = "i86pc" ]; then
		cp /boot/solaris/bootenv.rc /boot/solaris/bootenv.rc.autobench
		cp /boot/grub/menu.lst /boot/grub/menu.lst.autobench
	fi

	cp /export/bench/autobench/5.x/src/S99benchmarks /etc/rc3.d
	chmod +x /etc/rc3.d/S99benchmarks
	
	# Stop automounting dsk and md disks/partitions
	vfiles=\`ls /etc/vfstab* 2> /dev/null\`
	for vfile in \$vfiles; do
		sed -e "/export\/dsk/ s/yes/no/" -e "/export\/md/ s/yes/no/" \$vfile > /tmp/vfstabnew.$$
		mv /tmp/vfstabnew.$$ \$vfile
	done

	[ -f /auto/src/$sysname/RUNFIXME ] && sh /auto/src/$sysname/RUNFIXME

	cd /auto/Results
	rm -rf * 2>/dev/null >/dev/null

	[ -f /bin9/validate_nextrun ] && /bin9/validate_nextrun
	#### Explorer is installed, run, and then uninstalled 28.1.2002
	echo "************************************************"
	echo "*** Begin of EXPLORER install, run and uninstall"
	echo "************************************************"
	thisbuild=\`cat /auto/nextrun/NEXTRUN.${sysname}\`
	thispath=\${thisbuild}.${sysname}
	getexplorer=1

	for thispath in \${thisbuild}.${sysname} \${thisbuild}.${sysname}_64 ; do
		exists=\`rsh ${IRPERFIP} "[ -f /export/results9/\$thispath/.EXPLORER.tar.gz ] && echo yes"\`
		nonzero=\`rsh ${IRPERFIP} "[ -s /export/results9/\$thispath/.EXPLORER.tar.gz ] && echo yes"\`

		if [ "\$exists" = "yes" ]; then
			if [ "\$nonzero" = "yes" ]; then
				getexplorer=0
			else
				rsh ${IRPERFIP} /export/results9/\$thispath/.EXPLORER.tar.gz
			fi
		fi
	done

	if [ \$getexplorer -eq 0 ]; then
		echo "*** Already have EXPLORER output NOT doing it ***"
	else
		echo "Installing, and running Explorer from S99benchconfig..."
		echo + >>/.rhosts
		[ -d /root ] && echo + >>/root/.rhosts
		/auto/bin/RunCmdForSec 3600 /auto/bin/run_explorer.sh ${IRPERFIP}
		cp /opt/SUNWexplo/output/*.gz /export/bench/autobench/5.x/Results/.EXPLORER.tar.gz
		# opensolaris can put things elsewhere after uninstalling explorer
		[ -d /var/pkg/lost+found ] && cp /var/pkg/lost+found//opt/SUNWexplo/output*/*.gz  /export/bench/autobench/5.x/Results/.EXPLORER.tar.gz
	fi
	#### End of Explorer

### getting Serial Number of Chassis #######

haveserial=`rsh $IRPERFIP ls /var/ns-cgi/status/serialnumbers/${sysname}`
if [ -z "\${haveserial}" -a -x S99sneep ]; then
	sh ./S99sneep > /var/tmp/serial.${sysname}
	rcp /var/tmp/serial.${sysname} ${IRPERFIP}:/var/ns-cgi/status/serialnumbers/${sysname}
fi
# not needed
#cd -

############################################

rcp ${IRPERF2IP}:/export/install/config/profile_copy /.profile
rcp ${IRPERF2IP}:/export/install/config/cshrc /.cshrc
chmod 777 /.profile /.cshrc
if [ -d /root ]; then
	cp /.profile /root
	cp /.cshrc /root
	chmod 777 /root/.profile /root/.cshrc
fi
/var/tmp/btimer.sh end S99benchconfig $IRPERFIP

if [ -x /lib/svc/bin/svc.startd -a "$remotelab" != "JLT" ]; then
	#greenline stop nis and keyserv:
	svcadm disable network/nis/client
	svcadm disable network/rpc/keyserv
#	svcadm enable system/metainit # hangs in snv_119
fi
/var/tmp/watchdog -p $IRPERFIP -t s99benchconfig_$sysname -c
rsh $IRPERF2IP rm /export/bench/tmp/S99benchconfig/$sysname

 #Some Debugging stuff - Colm
 mkdir /var/tmp/network_setup.afterBenchConfig
 cp /etc/hosts /var/tmp/network_setup.afterBenchConfig
 cp /etc/netmasks /var/tmp/network_setup.afterBenchConfig
 cp /etc/hostname* /var/tmp/network_setup.afterBenchConfig


datestamp=\`date '+%Y%m%d-%H%M%S'\`
df -l -F zfs / > /dev/null 2>&1
if [ \$? -eq 0 ]; then
	zfs_list=\`zfs list -H | awk '{print \$1}' | grep -v -E 'swap|dump'\`;
	for zfs in \$zfs_list; do
		echo "Snapshotting \$zfs"
		zfs snapshot \${zfs}@post_genfin_\$datestamp
	done
fi

#set install count to 0
rsh -n $IRPERFIP "mv /dom/install_count/$sysname /dom/install_count/install_count_history/$sysname.\$BUILD.\$datestamp"
rsh -n $IRPERFIP "echo 0 > /dom/install_count/$sysname"
EOF_C



##########################################################################################
# Work Around for osol bug:  10542 Distribution Constructor Leaves Artifacts in /dev     #
#                            http://defect.opensolaris.org/bz/show_bug.cgi?id=10542      #
##########################################################################################
cat >>/a/etc/rc3.d/S99benchconfig <<EOF_devfsadm

[ \$OSOL -gt 0 ] && devfsadm -Cv > /auto/Results/.devfsadm-Cv.out 2>&1

EOF_devfsadm

# Another Bloody Check for the iommu damn thing
##########################################################################################
# Work Around for CR: 6800809                                                            #
##########################################################################################
IOMMU_BUILD=0
[ `echo $OSver |grep -c snv` -gt 0 ] && IOMMU_BUILD=`echo $OSver |sed "s/[a-z,_]//g"`
[ `echo $OSver |grep -c osol` -gt 0 ] && IOMMU_BUILD=`echo $OSver |awk -F\- '{print $NF}' |sed "s/[a-z,_]//g"`
IOMMU_SYS=`rsh $IRPERF2IP "grep -c $sysname /dom/workarounds/IOMMU_CR_6800809"`

if [ $IOMMU_SYS -gt 0 -a $IOMMU_BUILD -gt 100  -a $IOMMU_BUILD -lt 133 ]; then
	cat >>/a/etc/rc3.d/S99benchconfig <<EOF_D

echo "Adding Workaround for IOMMU hang"
sed -e 's/^kernel.*\$/& -B intel-iommu=no/g' /boot/grub/menu.lst > /tmp/menu.iommu
cat /tmp/menu.iommu > /boot/grub/menu.lst

EOF_D

fi

if [ $IOMMU_SYS -gt 0 -a $IOMMU_BUILD -eq 133 ]; then
	cat >>/a/etc/rc3.d/S99benchconfig <<EOF_D

echo "Adding Workaround for IOMMU hang"
sed -e 's/^kernel.*\$/& -B immu-enable=false/g' /boot/grub/menu.lst > /tmp/menu.iommu
cat /tmp/menu.iommu > /boot/grub/menu.lst

EOF_D

fi


################################################################################
# Workaround for 6901913 Hard hang on v20z with snv_124 shortly after boot
################################################################################
#6969659 P4 sun4v picl_initialize failed: Daemon not responding
if [ "$remotelab" != "JLT" ] && [ `prtdiag | grep "System Configuration:" | grep -E -ci "v20z|v40z"` -ge 1 ] ; then
	echo "This is a stinger applying workaround for 6901913, disable gdm/dtlogin"
	cat >> /a/etc/rc3.d/S99benchconfig <<EOF_stinger
		svcadm disable svc:/application/graphical-login/gdm:default
		svcadm disable svc:/application/graphical-login/cde-login:default

		if [ -x /etc/init.d/dtlogin ]; then
			/etc/init.d/dtlogin stop
		fi
EOF_stinger
fi


if [ $InstOS =  "Linux" ] ;then

	echo "rm -f /tmp/*running" >>/a/etc/rc3.d/S99benchconfig
	echo "/sbin/reboot" >>/a/etc/rc3.d/S99benchconfig
	rm -rf /a/root/.bash_logout
	# add rup support for linux boxes
	echo "enabling rstatd"	
	chkconfig rstatd on

else

	cat >>/a/etc/rc3.d/S99benchconfig <<EOF_fastboot
rcp ${IRPERF2IP}:/export/install/config/scripts/fastboot_check.sh /tmp
sh /tmp/fastboot_check.sh ${IRPERF2IP}
EOF_fastboot

	echo "/usr/sbin/reboot" >>/a/etc/rc3.d/S99benchconfig
fi

	echo "Set watchdog timer to check that rig reboots when genfin finishes. Running $unamea" |tee -a /var/tmp/reboot_after_genfin_check
	rsh $IRPERFIP "/export/bench/autobench/5.x/bin/watchdog -t reboot_after_genfin_check_${sysname} -n 120 -m \"${sysname} has not restarted two hours after running genfin. Check console to see what is wrong with it\""
}


workarounds() {

	rcp $IRPERF2IP:/auto/nextrun/NEXTRUN.${sysname} /tmp/nr
	nr=`cat /tmp/nr`

	rcp $IRPERF2IP:/dom/workarounds/${sysname}.sh  /tmp/workaround.sh 2>/dev/null 
	rcp $IRPERF2IP:/dom/workarounds/${nr}.sh  /tmp/workaround2.sh 2>/dev/null 
	[ -f /tmp/workaround.sh ] && sh /tmp/workaround.sh
	[ -f /tmp/workaround2.sh ] && sh /tmp/workaround2.sh

}
##############################################################################
###
###	Main Things run from here
###
##############################################################################

if [ -n "$remotelab" ] ; then
	echo "Leaving root password at default"
elif [ ${InstOS} != "Linux" ] ; then
	set_root
else
	# linux type fecking thing.
	echo "root:TQiKAxQMXzwsM:13952:0:99999:7:::" >> /a/etc/shadow
fi

system_setting
savecorefiles
[ "$remotelab" != "JLT" ] && changedumpdir
workarounds
start_rc_script
copy_testfile_benchmarks
if [ -z "$remotelab" ] ; then
	copy_powermeter_things
fi
install_time
end_rc_script

chmod +x /a/etc/rc3.d/S99benchconfig
rsh $IRPERF2IP rm /export/bench/tmp/generic/$sysname

#######################################################################################
# workaround for 6859068
#######################################################################################
[ "$OSver" = "snv_118" -o "$OSver" = "snv_119" ] && echo "this is $OSver! applying workaround for 6859068" && cp /a/lib/svc/seed/global.db /a/etc/svc/repository.db 

if [ $arch = i86pc ]; then
	xen
	x86_reboot_hack
elif [ "$arch" = "sun4" ]; then
	if [ -f /etc/release ]; then
		#if grep OpenSolaris /etc/release > /dev/null ; then
		if grep -E -ice '(opensolaris|solaris next|solaris 11 express)' /etc/release > /dev/null ; then
			echo "rebooting in 10 seconds since we are opensolaris..."
			sleep 10
			reboot
		fi
	fi
fi

exit 0

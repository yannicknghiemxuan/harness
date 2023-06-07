#!/usr/bin/env bash
set -euxo pipefail
. /etc/os-release
. /etc/autoenv
#firstremoteuser=rocky
firstremoteuser=tnx
remoteuser=ansible
remotecmdscript=remote_install_remotecmds.sh
targethost=$1


prepare_payload()
{
    targetip=$(grep $targethost /etc/hosts \
		   | awk '{print $1}' \
		   | egrep '[0-9]*[.][0-9]*[.][0-9]*[.][0-9]*')
    cat > "/$tmpdir/networkinfo.sh" <<EOF
ip=$targetip
host=$targethost
EOF
    chmod +x "/$tmpdir/networkinfo.sh"
    cat $AUTOROOT/rigs/*/sshpub/*.pub | sort -u \
	       > "/$tmpdir/authorized_keys"
    gpg --decrypt \
	~tnx/.password-store/machines/ssh-keys/${targethost}_tnx.gpg \
	> "/$tmpdir/id_rsa"
    cp $AUTOROOT/rigs/*/sshpub/${targethost}_tnx.pub "/$tmpdir/id_rsa.pub"
}


wait_for_reboot()
{
    sleep 10 # giving the machine some time to reboot
    for i in {1..50}; do
	if ping -c 1 "$targethost"; then
	    break
	fi
	sleep 1
    done
    for i in {1..50}; do
	if ssh "$remoteuser@$targethost" echo ok; then
	    break
	fi
	sleep 1
    done
}


main ()
{
    tmpdir=$(mktemp -d)
    prepare_payload
    scp -r /$tmpdir/authorized_keys \
	/$tmpdir/id_rsa \
	/$tmpdir/id_rsa.pub \
	/$tmpdir/networkinfo.sh \
	$remotecmdscript \
	"$AUTOROOT/harness" \
	"$firstremoteuser@$targethost:/var/tmp" || true
    ssh -t "$firstremoteuser@$targethost" \
	bash -c "/var/tmp/harness/setup/ansible/create_ansible_user.sh" || true
    ssh -t "$firstremoteuser@$targethost" \
	'sudo chmod -R 775 /var/tmp/*.sh /var/tmp/harness'
    ssh -t "$remoteuser@$targethost" \
	'bash -c "/var/tmp/'$remotecmdscript' step_1"'
    scp -r /home/tnx/{.gnupg,.password-store} \
	"tnx@$targethost:/home/tnx" || true
    ssh -t "$remoteuser@$targethost" \
	'bash -c "/var/tmp/'$remotecmdscript' reboot"' || true
    wait_for_reboot
    ssh -t "$remoteuser@$targethost" \
	'bash -c "/var/tmp/'$remotecmdscript' step_2"'
    rm -rf "$tmpdir"
}


main

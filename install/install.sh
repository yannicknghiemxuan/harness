#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
os=$(uname -s)
hostname=$(uname -n)
[[ $os == Linux ]] && . /etc/os-release || true
targetuser=root
if [[ -z ${remoteuser-} ]]; then
    remoteuser=$USER
fi
[[ $USER == root ]] && remoteuser=tnx || true


check_requirements()
{
    if [[ ! -f /etc/autoenv ]]; then
	cat 2>&1 <<EOF
error: /etc/autoenv does not exist
create it from the template and customise it:
vi autoenv.template
sudo cp autoenv.template /etc/autoenv
sudo chown root /etc/autoenv
sudo chmod 664 /etc/autoenv
EOF
	exit 1
    fi
}


install_base_Linux()
{
    if [[ -z ${ID_LIKE-} ]]; then
	ID_LIKE=$ID
    fi
    case $ID_LIKE in
	debian|ubuntu)
	    sudo apt-get update
	    sudo apt-get install -yqq \
		 tmux \
		 vim \
		 emacs-nox \
		 rsync \
		 git \
		 openssh-server \
		 htop \
		 p7zip-full \
		 wget \
		 ipv6calc \
		 zsh
	    ;;
	*rhel*)
	    sudo dnf -y install epel-release
	    sudo dnf install -y \
		 tmux \
		 vim \
		 emacs-nox \
		 git \
		 openssh-server \
		 htop \
		 p7zip \
		 p7zip-plugins \
		 wget \
		 rsync \
		 ipv6calc \
		 zsh
	    ;;
    esac
    case $ID in
	steamos)
	    brew install \
		 tmux \
		 emacs \
		 vim \
		 ipv6calc
	;;
    esac
}


install_base_MacOS()
{
    if [[ ! -x /usr/local/bin/brew ]]; then
	case $(sw_vers -productVersion) in
	    # brew minimum requirements:
	    # - https://docs.brew.sh/Installation
	    10.4.*|10.5.*|10.6.*|10.7.*|10.8.*)
		echo "installing tigerbrew for older versions of Mac OS X"
		ruby -e "$(curl -fsSkL raw.github.com/mistydemeo/tigerbrew/go/install)"
		brew uninstall git || true
		brew reinstall curl
		brew link --force curl
		brew reinstall --build-from-source git
		# so that brew can use the new version of git
		export PATH=/usr/local/bin:$PATH
		brew update
		;;
	    10.9.*|10.10.*|10.11.*|10.12.*|10.13.*|10.14.*|10.15.*)
		echo "installing brew"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
		;;
	esac
    fi
    brew install \
	 git \
	 tmux \
	 vim \
	 emacs \
	 htop \
	 p7zip \
	 gnu-tar \
	 wget \
	 ipv6calc \
	 zsh || true
}


install_base_Solaris()
{
    pkgadd -d http://get.opencsw.org/now || true
    /opt/csw/bin/pkgutil -U || true
    /opt/csw/bin/pkgutil -y -i sudo tmux vim emacs-nox git wget || true
}


install_base_FreeBSD()
{
    if [[ ! -x $(which sudo) ]]; then
	cat <<EOF
On FreeBSD you need to install sudo first.
su
pkg install sudo
mkdir -p /usr/local/etc/sudoers.d
chown root:wheel /usr/local/etc/sudoers.d
chmod 755 /etc/sudoers.d
echo "$USER ALL=(ALL) NOPASSWD: ALL" > /usr/local/etc/sudoers.d/$USER
chmod 600  /usr/local/etc/sudoers.d/$USER
EOF
	exit 1
    fi
    sudo pkg install -y \
	 tmux \
	 vim \
	 emacs-nox \
	 git \
	 wget \
	 p7zip \
	 ipv6calc || true
}

install_base()
{
    case $os in
	Linux)
	    install_base_Linux
	    ;;
	Darwin)
	    install_base_MacOS
	    ;;
	SunOS)
	    install_base_Solaris
	    ;;
	FreeBSD)
	    install_base_FreeBSD
	    ;;
	*)
	    exit 1
	    ;;
    esac
}


install_repos()
{
    sudo mkdir -p $AUTOROOT || true
    sudo chown $(whoami) $AUTOROOT
    cd $AUTOROOT
    mkdir -p harness rigs log/{auto,zfs,var,$hostname} || true
    cd $AUTOROOT/harness
    [[ ! -d harness ]] && \
	git clone ssh://$remoteuser@$SERVERURL:$SERVERPORT/galaxy/git/harness . || true
    if [[ ${ISGALAXY-} == true ]]; then
	mkdir -p $AUTOROOT/rigs/galaxy || true
	cd $AUTOROOT/rigs/galaxy
	[[ ! -d galaxy ]] && \
	    git clone ssh://$remoteuser@$SERVERURL:$SERVERPORT/galaxy/git/rigs/galaxy . || true
    fi
    if [[ ${ISTHEPROJ-} == true ]]; then
	mkdir -p $AUTOROOT/rigs/theproj || true
	cd $AUTOROOT/rigs/theproj
	[[ ! -d theproj ]] && \
	    git clone ssh://$remoteuser@$SERVERURL:$SERVERPORT/galaxy/git/rigs/theproj . || true
    fi
    $AUTOROOT/harness/auto/fixautoperms
    echo "you can configure which repos are kept in sync from the server:"
    echo "sudo vi /etc/autorepos"
}


main()
{
    check_requirements
    . /etc/autoenv
    install_base
    install_repos
}


main

#!/usr/bin/env bash
set -x
echo "installing brew and tools"
# source: https://www.howtogeek.com/211541/homebrew-for-os-x-easily-installs-desktop-apps-and-terminal-utilities/
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
xcode-select --install
brew doctor
brew install gnu-tar p7zip \
     emacs bash zsh tmux \
     wakeonlan rsync openvpn openssh wget telnet nmap \
     tree pstree htop git mercurial ipv6calc \
     ansible octant tag gnu-sed
sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
chsh -s /usr/local/bin/bash tnx
if [[ ! -f ~/.bashrc ]]; then
    tee ~/.bashrc <<EOF
export PATH=/usr/local/bin:/usr/local/sbin:\$PATH
EOF
fi

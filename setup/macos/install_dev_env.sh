#!/usr/bin/env bash
set -x
echo "installing brew and tools"
# source: https://www.howtogeek.com/211541/homebrew-for-os-x-easily-installs-desktop-apps-and-terminal-utilities/
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
xcode-select --install
brew doctor
brew install gnu-tar p7zip \
     emacs bash zsh tmux gnupg pass \
     wakeonlan rsync openvpn openssh wget telnet nmap \
     tree pstree htop git mercurial ipv6calc \
     ansible
sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'
chsh -s /usr/local/bin/bash tnx
if [[ ! -f ~/.bashrc ]]; then
    tee ~/.bashrc <<EOF
export PATH=/galaxy/logic/bin:/usr/local/bin:$PATH
EOF
fi
if [[ ! -d /usr/local/matterhorn ]]; do
    # check https://github.com/matterhorn-chat/matterhorn/releases for latest release
    cd /tmp
    wget https://github.com/matterhorn-chat/matterhorn/releases/download/50200.4.0/matterhorn-50200.4.0-Darwin-x86_64.tar.bz2
    bunzip2 matterhorn-*-Darwin-x86_64.tar.bz2 | tar xf -
    sudo mkdir /usr/local/matterhorn
    sudo chown tnx:staff /usr/local/matterhorn
    sudo chmod 775 /usr/local/matterhorn
    rsync -av matterhorn-*-Darwin-x86_64/ /usr/local/matterhorn/
    ln -s /usr/local/matterhorn/matterhorn /usr/local/bin/matterhorn
fi

cd ~/
ln -s ~/Nextcloud/informations/gnupg .gnupg
ln -s ~/Nextcloud/informations/password-store .password-store

#!/usr/bin/env bash
set -x
# source:
# - https://gist.github.com/uyjulian/105397c59e95f79f488297bb08c39146


enable_sshd()
{
    echo "enabling sshd so please change the default password"
    passwd
    sudo systemctl enable --now sshd
}


install_brew_steamdeck()
{
    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
	return
    fi
    if ! grep linuxbrew ~/.bash_profile >/dev/null 2>&1; then
        echo 'if [ $(basename $(printf "%s" "$(ps -p $(ps -p $$ -o ppid=) -o cmd=)" | cut --delimiter " " --fields 1)) = konsole ] ; then '$'\n''eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'$'\n''fi'$'\n' >> ~/.bash_profile
    fi
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
}


enable_sshd
install_brew_steamdeck
echo 'now type: '
echo "  exec bash"
echo "  export remoteuser=tnx and run the install script"

#!/usr/bin/env bash
# ED25519: This is the most secure encryption option nowadays, as it has a very strong mathematical algorithm.

set -ex
[[ ! -d ~/.password-store/machines/ssh-keys ]] && exit 1
for m in $(grep -v -E '#' /galaxy/logic/machines/hardware | awk -F\; '{print $1}'); do
    if [[ ! -f ~/.password-store/machines/ssh-keys/$m.gpg ]]; then
	ssh-keygen -t ssh-ed25519 -b 4096 -N "" -C $m -f ~/.password-store/machines/ssh-keys/$m
	gpg --encrypt -r tnx ~/.password-store/machines/ssh-keys/$m
	[[ $? -eq 0 ]] && rm ~/.password-store/machines/ssh-keys/$m
    fi
done

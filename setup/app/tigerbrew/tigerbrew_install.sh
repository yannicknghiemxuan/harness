#!/usr/bin/env bash
# source: https://github.com/mistydemeo/tigerbrew
set -x
ruby -e "$(curl -fsSkL raw.github.com/mistydemeo/tigerbrew/go/install)"
brew update
brew install curl git bash zsh emacs wget python python3 vim gnu-tar p7zip pstree xz gnu-sed gnu-time grep nmap gawk hexedit tmux tree autoconf automake m4 cmake

#!/usr/bin/env bash
# Purpose: Install all dotfiles on clean system

if [[ "/home/$USER/dotfiles" != $PWD]]; then
    echo "Must be run from expected dir: ~/dotfiles" >&2
    return 1
fi

ret=$(which stow &>/dev/null)
if [[ $? -ne 0 ]]; then
    echo "Error: package stow doesn't exist" >&2
    echo "Please run: sudo apt-get install stow" >&2 && exit 1
fi

for pkg in $(ls .); do
    if [[ -d $pkg ]]; then
	    set -x
	    stow $pkg
	    { set +x; } &>/dev/null
    fi
done

sed -i "s/^\(# Configuration:\) MACHINE_NAME.*/\1 ${HOSTNAME}/" bash/.bashrc
if [[ ! -f ~/.machine ]]; then
    echo "# [${HOSTNAME}] Machine-Specific Configs" > ~/.machine
fi

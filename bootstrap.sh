#!/usr/bin/env bash
# Purpose: Install all dotfiles on clean system

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

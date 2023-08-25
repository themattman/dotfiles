#!/usr/bin/env bash
# Purpose: Install all dotfiles on clean system
# Usage:   `source boostrap.sh`

if [[ "/home/$USER/dotfiles" != $PWD ]]; then
    echo "Must be run from expected dir: ~/dotfiles" >&2
    return 1
fi

which stow &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "Error: package stow doesn't exist" >&2
    sudo apt-get -y install stow
    if [[ $? -ne 0 ]]; then
        echo "Please run: sudo apt-get install stow OR sudo apt-get update" >&2 && exit 1
    fi
fi

mv ~/.bashrc ~/.bashrc.bk
for pkg in $(ls .); do
    if [[ -d $pkg ]]; then
	    set -x
	    stow $pkg
            ret=$?
	    { set +x; } &>/dev/null

#        if [[ $ret -ne 0 ]]; then
#            set -x
#            stow --adopt $pkg
#            { set +x; } &>/dev/null
#            for existing_pkg in $(git diff --name-only -- $pkg); do
#                set -x
#                mv ${existing_pkg} ${existing_pkg}.bk
#                { set +x; } &>/dev/null
#            done
#            git reset --hard -- $pkg
#            stow $pkg
#        fi
    fi
done

sed -i "s/^\(# Configuration:\) MACHINE_NAME.*/\1 ${HOSTNAME}/" bash/.bashrc
if [[ ! -f ~/.machine ]]; then
    echo "# [${HOSTNAME}] Machine-Specific Configs" > ~/.machine
fi

echo
echo "[Install dependencies]"
dependencies=(emacs screen source-highlight)
for dep in ${dependencies[@]}; do
    set -x
    sudo apt-get -y install $dep
    { set +x; } &>/dev/null
done

echo
echo "[Emacs setup]"
set -x
emacs --batch --script ~/.emacs.d/init.el &> emacs-compile.$(date "+%Y_%m_%d__%H_%M_%S")
source ~/.bashrc
{ set +x; } &>/dev/null

echo
echo "done."


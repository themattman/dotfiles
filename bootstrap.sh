#!/usr/bin/env bash
# Purpose: Install all dotfiles on clean system
# Usage:   `source boostrap.sh`


if [[ -f ~/.bashrc ]]; then
    set -x
    mv ~/.bashrc ~/.bashrc.bk
    { set +x; } &>/dev/null
fi

if [[ -f ~/.bash_profile ]]; then
    set -x
    mv ~/.bash_profile ~/.bash_profile.bk
    { set +x; } &>/dev/null
fi

echo
echo "#########################"
echo "# Updating machine name #"
echo "#########################"
sed -i' ' "s/^\(# Configuration:\) MACHINE_NAME.*/\1 ${HOSTNAME}/" bash/.bashrc
if [[ ! -f ~/.machine ]]; then
    echo "# [${HOSTNAME}] Machine-Specific Configs" > ~/.machine
fi

# Platform-specific setup
case $OSTYPE in
linux*|msys*)
    if [[ "/home/$USER/dotfiles" != $PWD ]]; then
	    echo "Must be run from expected dir: ~/dotfiles" >&2
	    return 1
    fi
    source linux_bootstrap.sh
;;
darwin*)
    if [[ "/Users/${USER}/dotfiles" != $PWD ]]; then
	    echo "Must be run from expected dir: ~/dotfiles" >&2
	    return 1
    fi
    source mac_bootstrap.sh
;;
esac


echo
echo "####################"
echo "# Stowing Dotfiles #"
echo "####################"
for pkg in $(ls .); do
    if [[ -d $pkg ]]; then
	    set -x
	    stow $pkg
            ret=$?
	    { set +x; } &>/dev/null
    fi
done

echo
echo "###############"
echo "# Emacs setup #"
echo "###############"
set -x
emacs --batch --script ~/.emacs.d/init.el &> emacs-compile.$(date "+%Y_%m_%d__%H_%M_%S")
source ~/.bashrc
{ set +x; } &>/dev/null
emacs_version=$(emacs --version | head -n 1)
echo "Emacs Version: [${emacs_version}]"

echo
echo "###################################################"
echo "# Check .git-completion file against upstream tip #
echo "###################################################"
if [[ $(wget -q --spider http://github.com) -eq 0 ]]; then
    wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
    if [[ $(diff -q git-completion.bash git/.git-completion 1>/dev/null) -ne 0 ]]; then
        echo "Warning: .git-completion needs updating. Updating it now..." >&2
	    mv -f git-completion.bash git/.git-completion
    fi

    wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
    if [[ $(diff -q git-prompt.sh git/.git-prompt 1>/dev/null) -ne 0 ]]; then
        echo "Warning: .git-prompt needs updating. Updating it now..." >&2
	    mv -f git-prompt.sh git/.git-prompt
    fi
else
    echo "Skipping check, no network connection to github.com." >&2
fi

echo
echo "##############"
echo "# Git Config #"
echo "##############"
read -p "Git Email Address: " _email
git config --global user.email "${_email}"

echo
echo "##############"
echo "# SSH Keygen #"
echo "##############"
echo -en "Is this the right identity for ssh [${_email}]? "
read -p "[y/n]: " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    set -x
    ssh-keygen -t ed25519 -C "${_email}"
    { set +x; } &>/dev/null

    if [[ $OSTYPE =~ "darwin" ]]; then
        set -x
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519
        { set +x; } &>/dev/null
    fi
fi


echo
echo "dotfiles installation done."

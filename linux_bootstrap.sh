#!/usr/bin/env bash

echo
echo "##########################"
echo "# Install Linux Packages #"
echo "##########################"
which stow &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "Error: required package stow doesn't exist" >&2
    exit 1
fi

pkgs=(bash-completion colorized-logs dos2unix emacs htop moreutils screen source-highlight stow xclip)
# linux-tools-common linux-tools-generic linux-tools-`uname -r`
# bear build-essential clangd colordiff graphviz linux-tools-aws numactl pax-utils repytr
for pkg in ${pkgs[@]}; do
    set -x
    sudo apt-get -y install $pkg
    { set +x; } &>/dev/null
done

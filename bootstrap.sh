#!/usr/bin/env bash
# Install dotfiles
#
# Author: Matthew Kneiser
# Date:   01/11/2015

VERSION="1.3.1"
EXTENSION=".tar.bz2"
AUTO_COMPLETE="auto-complete-${VERSION}"
AUTO_COMPLETE_PKG="${AUTO_COMPLETE}${EXTENSION}"
INSTALL_FROM_SOURCE=0
NO_BACKUP=0
GREEN=""
CYAN=""
RED=""
ENDCOLOR=""

# Command-line Parsing
usage() { echo "Usage: $0 [-h] [-ns]" 1>&2; exit 1; }
print_help() {
    echo "bootstrap.sh, Install Dotfiles";
    echo "";
    echo "Usage: $0 [-h] [-ns]";
    echo "";
    echo -e "\th : this help menu";
    echo -e "\tn : no backup - overwrite previous dotfiles";
    echo -e "\ts : source - install everything from the source";
    exit 1;
}

while getopts "hsn" flag; do
    case "${flag}" in
	h)
	    print_help
	    ;;
	s)
	    INSTALL_FROM_SOURCE=1
	    ;;
	n)
	    NO_BACKUP=1
	    ;;
	*)
	    usage
	    ;;
    esac
done

case $OSTYPE in
    linux*)
	GREEN="\e[1;32m"
	CYAN="\e[1;36m"
	RED="\e[1;31m"
	ENDCOLOR="\e[0m"
	;;
    darwin*)
	GREEN="\033[0;92m"
	CYAN="\033[0;96m"
	RED="\033[0;91m"
	ENDCOLOR="\033[0m"
	;;
esac


set -e

pushd "$(dirname "${BASH_SOURCE}")"

if [[ "$INSTALL_FROM_SOURCE" -eq 1 ]]; then
    echo "Installing dotfiles from source..."
    set -x
    curl -O "http://cx4a.org/pub/auto-complete/${AUTO_COMPLETE_PKG}"
    tar xvf "${AUTO_COMPLETE_PKG}"
    pushd "${AUTO_COMPLETE}"
    CURRENT_DATETIME=$(date +"%F_at_%T")
    mkdir "$HOME/.emacs.d" || :
    make install DIR=$HOME/.emacs.d/ $> "makeoutput.$CURRENT_DATETIME"
    popd
    rm -rf "${AUTO_COMPLETE_PKG}"
    set +x
fi

for DOTFILE in $(find . -maxdepth 1 -name '.?*'); do
    DOTFILE=${DOTFILE#./} #strip leading ./ from paths
    if [[ "${DOTFILE}" != ".gitignore" && "${DOTFILE}" != ".git" ]]; then
	echo "${DOTFILE}"
	if [[ "${NO_BACKUP}" -eq 1 || -h "${HOME}/${DOTFILE}" ]]; then
	    echo -ne "\t${RED}removing ${HOME}/${DOTFILE}${ENDCOLOR} "
	    rm -r "${HOME}/${DOTFILE}" && echo " ...done"
	elif [[ -e "${HOME}/${DOTFILE}" ]]; then
	    echo -ne "\t${CYAN}backing up ${HOME}/${DOTFILE}${ENDCOLOR} "
	    CURRENT_DATETIME=$(date +"%F_at_%T")
	    mv "${HOME}/${DOTFILE}" "${HOME}/${DOTFILE}.${CURRENT_DATETIME}" && echo "...done"
	fi
	echo -ne "\tsoftlinking dotfile "
	ln -s "${PWD}/${DOTFILE}" "${HOME}/${DOTFILE}" && echo "...done"
    fi
done

popd

echo -e "${GREEN}Dotfiles installation succesful.${ENDCOLOR}"

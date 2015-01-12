#!/usr/bin/env bash
# Install dotfiles from source
# Author: Matthew Kneiser
# Date:   01/11/2015

VERSION="1.3.1"
EXTENSION=".tar.bz2"
AUTO_COMPLETE="auto-complete-${VERSION}"
AUTO_COMPLETE_PKG="${AUTOCOMPLETE}${EXTENSION}"
INSTALL_FROM_SOURCE=0
NO_BACKUP=0
GREEN=""
ENDCOLOR=""

# Command-line Parsing
usage() { echo "Usage: $0 [-h] [-cn]" 1>&2; exit 1; }

while getopts "hs" flag; do
    case "${flag}" in
	h)
	    usage
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
	GREEN="\e[0;36m"
	ENDCOLOR="\e[0m"
	;;
    darwin*)
	GREEN="\033[0;92m"
	ENDCOLOR="\033[0m"
	;;
esac


set -e

pushd "$(dirname "${BASH_SOURCE}")"

if [[ "$INSTALL_FROM_SOURCE" ]]; then
    echo "Installing dotfiles from source..."
#     wget "http://cx4a.org/pub/auto-complete/${AUTO_COMPLETE_PKG}"
#     tar xvf "${AUTO_COMPLETE_PKG}"
#     cd "${AUTO_COMPLETE}"
#     make install DIR=$HOME/.emacs.d/
fi

for DOTFILE in $(find . -maxdepth 1 -name '.?*'); do
    if [[ "${DOTFILE}" != "./.gitignore" ]]; then
# 	echo "dotfile: ${DOTFILE}"
	if [[ "${NO_BACKUP}" ]]; then
	    rm -r "${HOME}/${DOTFILE}"
	else
	    CURRENT_DATETIME=$(date +"%F_at_%T")
	    mv "${HOME}/${DOTFILE}" "${HOME}/${DOTFILE}.${CURRENT_DATETIME}"
	fi
	ln -s "${HOME}/${DOTFILE}" "${PWD}/${DOTFILE}"
    fi
done

popd

echo -e "${GREEN}Dotfiles installation succesful.${ENDCOLOR}"

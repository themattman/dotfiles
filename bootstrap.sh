#!/usr/bin/env bash
# Install dotfiles
#
# Author:       Matthew Kneiser
# Date Created: 01/11/2015
#
# Softlinks all dotfiles in current directory to
#  the user's home directory, except git files.

#
# Emacs Packages
#
# Auto-Complete
version="1.3.1"
extension=".tar.bz2"
auto_complete="auto-complete-${version}"
auto_complete_pkg="${auto_complete}${extension}"
auto_complete_url="http://cx4a.org/pub/auto-complete/${auto_complete_pkg}"
# Python-mode
python_mode_url="http://bazaar.launchpad.net/~python-mode-devs/python-mode/python-mode/download/head:/2%40fb98634b-d22b-0410-a57a-e996bee27b70:trunk%252Fpython-mode:python-mode.el/python-mode.el"
emacs_packages=($auto_complete_url $python_mode_url)

install_from_source=0
no_backup=0
declare green cyan red endcolor

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
	    install_from_source=1
	    ;;
	n)
	    no_backup=1
	    ;;
	*)
	    usage
	    ;;
    esac
done

case $ostype in
    linux*)
	green="\e[1;32m"
	cyan="\e[1;36m"
	red="\e[1;31m"
	endcolor="\e[0m"
	;;
    darwin*)
	green="\033[0;92m"
	cyan="\033[0;96m"
	red="\033[0;91m"
	endcolor="\033[0m"
	;;
esac

safely_softlink_file() {
    # Softlinks $1 to $2
    #  or $1 to ${HOME}/$1 if only one argument is given
    # Backs up the target ($2 or ${HOME}/$1) if $no_backup is 0.
    local file=$1
    local to_location=$2

    # Set default softlink target if needed
    if [[ -z $to_location ]]; then
	to_location="${HOME}/${file}"
    else
	to_location="${to_location}/${file}"
    fi

    echo "${file}"
    # If user specifies "no backup" or the current target is a symlink
    if [[ $no_backup -eq 1 || -h $to_location ]]; then
	echo -ne "\t${red}removing ${to_location}${endcolor} "
	rm -r "${to_location}" && echo " ...done"
    elif [[ -e $to_location ]]; then
	echo -ne "\t${cyan}backing up ${to_location}${endcolor} "
	current_datetime=$(date +"%F_at_%T")
	mv "${to_location}" "${to_location}.${current_datetime}" && echo "...done"
    fi

    echo -ne "\tsoftlinking file "
    ln -s "${PWD}/${file}" "${to_location}" && echo "...done"
}


set -e
pushd "$(dirname "${bash_source}")"

# Ensure two dirs exist
#  Ignore failure of these mkdir's by OR'ing with a no-op
mkdir "$HOME/.emacs.d" || :
mkdir "$HOME/tmp" || :

#
# Install Emacs Packages
#
set -x
if [[ $install_from_source -eq 1 ]]; then
    echo "Installing emacs packages from source..."
    for pkg in $emacs_packages; do
	curl -LO $pkg
	tar xvf $pkg
	pushd $pkg
	current_datetime=$(date +"%F_at_%T")
	make install DIR=$HOME/.emacs.d/ &> "makeoutput.$current_datetime"
	popd
	rm -rf "${auto_complete_pkg}"
    done
else
    for pkg in $emacs_packages; do
	if [[ -d $pkg ]]; then
	    cp -r ${auto_complete}/* "${HOME}/.emacs.d"
	fi
    done
fi
set +x

#
# Install dotfiles except .git and .gitignore
#
echo -ne "\n"
hostname=$(hostname)
for dotfile in $(find . -maxdepth 1 -name '.?*'); do
    dotfile=${dotfile#./} #strip leading ./ from paths
    if [[ $dotfile != ".gitignore" && $dotfile != ".git" ]]; then
	safely_softlink_file ${dotfile}
	if [[ $dotfile == ".bashrc" &&  -n $hostname ]]; then
	    sed -e "s/MACHINE_NAME .*/${hostname}/" $dotfile
	fi
    fi
done

#
# Install non-dotfiles
#
safely_softlink_file template.py ${HOME}/tmp


echo -ne "\n"
popd

echo -e "\nNow run: $ . ~/.bash_profile"
echo -e "${green}Dotfiles installation succesful.${endcolor}"

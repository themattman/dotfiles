##
# .bashrc
#
# Author:        Matt Kneiser
# Created:       03/19/2014
# Last updated:  01/11/2015
# Configuration: MACHINE_NAME # a script should update this
#
# To refresh bash environment with changes to this file:
#  $ source ~/.bashrc
# or alternatively:
#  $ sb
#
# Ubuntu Colors:
#  Purple: 119,41,83
#  Orange: 221,72,20
#
# dotfiles on GitHub:
#  http://dotfiles.github.io/
#
# Different behavior based on OS and detected environment
#  OSX & Ubuntu 12.04 LTS supported
#
# Table of Contents:
# 1) Polyfills
# 2) My world famous aliases
# 3) Prompt String
# 4) Bash Functions
# 5) Miscellaneous
# 6) Machine-Specific


## 1) Polyfills
# Tree
if [ ! -x "$(which tree 2>/dev/null)" ]
then
  alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
fi
# Readlink replacement (for non-Ubuntu)
alias realpath="python -c 'import os, sys; print os.path.realpath(sys.argv[1])'"
# Bash Polyfills
alias wget="curl -O"
alias icurl="curl -I"


## 2) My world famous aliases
#   a) OS-specific
#   b) Basic bash
#   c) Short program
#   d) Common

## 2a) OS-specific aliases
case $OSTYPE in
linux*)
    # tree
    if [[ "$(type -P tree)" ]]; then
	alias ll="tree --dirsfirst -aLpughDFiC 1"
	alias lsd="ll -d"
    fi
    # ls
    alias sl="ls -F --color"
    alias s="ls -F --color"
    alias ls="ls -F --color"
    alias lsl="ls -F --color -lh"
    alias lh="ls -F --color -alh"
    alias l="ls -F --color -alth"
    alias als="ls -F --color -alth"
    alias asl="ls -F --color -alth"
    alias las="ls -F --color -alth"
    alias lsa="ls -F --color -alth"
    alias sal="ls -F --color -alth"
    alias sla="ls -F --color -alth"
    alias lg="ls -F --color -alth --group-directories-first"

    # Disk Usage
    alias dush="du -sh ./* | sort -h"

    # Ubuntu Package Management
    alias acs="sudo apt-cache search"
    alias agi="sudo apt-get install"

    # System Info
    alias cores="cat /proc/cpuinfo | grep -c processor"
    alias os="lsb_release -d | cut -d: -f 2 | sed 's/^\s*//'" # Linux Distro
;;
darwin*)
    # ls
    alias sl="ls -FGS" # sorted by size
    alias s="ls -FG"
    alias lsl="ls -lh -FG"
    alias lh="ls -alh -FGS"
    alias l="ls -alth -FG"
    alias als="ls -alth -FG"
    alias asl="ls -alth -FG"
    alias las="ls -alth -FG"
    alias lsa="ls -alth -FG"
    alias sla="ls -alth -FG"
    alias sla="ls -alth -FG"
    alias lg="ls -alth -FG"

    # System Info
    alias cores="sysctl hw.ncpu | awk '{print \$2}'"
;;
esac

## 2b) Basic bash aliases
alias body="cat -n \$1,\$2p \$3"
alias rem="remove_trailing_spaces"
alias !="sudo !!"
alias c="cd -"    # Use Ctrl-L instead of aliasing this to clear
alias d="diff"
alias a="alias"
alias pu="pushd"
alias po="popd"
alias wh="which"
alias m="man"
alias tlf="tail -f"
alias chax="chmod a+x"
alias chux="chmod u+x"
alias bell="tput bel"
alias y="yes"
# Job Control
# http://www.tldp.org/LDP/gs/node5.html#secjobcontrol
alias f="fg"       # Yes, I'm really lazy
alias v="fg -"
alias j="jobs -l"  # Switched these two logically, because
alias jl="jobs"    #  I always want to see the jobs' pids
alias kl="kill %%" # Kill most recent background job
# Optional Shell Behavior
shopt -s cdable_vars
shopt -s cdspell
shopt -s checkwinsize # Make bash check its window size after a process completes
#shopt -s dirspell
shopt -s histappend   # append history to ~\.bash_history when exiting shell
shopt -s interactive_comments # on by default, but want to ensure comments are ok
#shopt -s nocaseglob # eh? windows?
shopt -s progcomp # on by default
# https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html#Programmable-Completion
# Death
alias k="kill -9"    # SIGKILL
alias ke="kill -15"  # SIGTERM
# Machine Control
alias reboot="shutdown -r now"
alias sleep="shutdown -s now"
case $OSTYPE in
linux*)
    alias afk="gnome-screensaver-command -l"
;;
darwin*)
    alias afk=""
;;
esac

## 2c) Short program aliases
# CD
alias .="dot #" # My epic cd alias
                #  The trailing hash is meant to comment out the rest of the
                #  command. The dots that follow the original dot will be used
                #  when searching through the history.
alias ..="cd .."
alias ...="cd ../.."
# ECHO
alias ec="echo"
alias ep="echo \$PATH"
alias epp="echo \$PYTHONPATH"
alias el="echo \$LD_LIBRARY_PATH"
# Emacs
alias e="\emacs -nw"     # Escape emacs so that -nw only
alias emasc="\emacs -nw" #  gets appended once
alias emacs="\emacs -nw"
# Git
alias g="git rev-parse --abbrev-ref HEAD | xargs -I{} git pull origin {}"
alias gp="git push"
alias gb="git branch"
alias gba="git branch -a"
alias gvv="git branch -vv"
alias gbl="git blame"
alias ga="git add"
alias gco="git commit"
alias gm="git commit -m"
alias gss="git status"
alias gs="git status -s"
alias gsu="git status -s -uno" # Don't show untracked files
alias gd="git diff"
alias gds="git diff --staged"
alias gdss="git diff --stat"
alias gl="git log"
alias gls="git log --stat"
alias gll='git log --graph --pretty=oneline --abbrev-commit'
alias gg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias ggs="gg --stat"
alias gsl="git shortlog -sn"            # All authors in this branch's history
alias gnew="git log HEAD@{1}..HEAD@{0}" # Show commits since last pull
alias gc="git checkout"
alias gch="git checkout -- ."
alias gcl="git clone"
alias gpo="git rev-parse --abbrev-ref HEAD | xargs -I{} git push origin {}"
alias gbr="git rev-parse --abbrev-ref HEAD" # Works on 1.7.x & 1.8.x
alias gsh="git show"
alias gshh="git show HEAD"
alias gv="git remote -v"
alias gr="git reset"
alias grh="git reset HEAD~1"
alias g--="git --version"
alias ge="git config user.email"
alias gu="git config user.name"
alias gcon="git config"
alias gconl="git config --list"
alias findgit="git rev-parse --git-dir"
alias findgits="find . -name .git -type d"
# GREP
alias gre="grep -Iirsn --color=always" # case-insensitive
alias gree="grep -Irsn --color=always"
# HISTORY
alias h="history"
alias hist="history | grep -P --color=always \"^.*?]\" | less -FRX +G"
alias hisd="history -d"
export HISTCONTROL="erasedups"
# Give history timestamps
export HISTTIMEFORMAT="[%F %T] "
# Johannes Gutenberg's Bible
export HISTSIZE=10000
export HISTFILESIZE=10000
 # Easily re-execute the last history command
alias r="fc -s"
# LESS
alias less="less -FXR" # I don't like aliasing program names
# Node.js
alias n="node"
alias nd="node server"
# Pip
alias de="deactivate"
alias pi="pip install"
alias vv="virtualenv"
# PS
alias psa="ps aux"
alias p="ps aux | grep -v grep | grep `echo \$USER`"
alias psm="ps aux | grep mongo"
alias pse="ps fe -o \"%c %p %P\""
alias pe="ps fe -o \"%p\" --no-headers --ppid"
alias pid="ps fe --pid"
alias ppid="ps fe --ppid"
# PWD
alias pdw="pwd"
alias wdp="pwd"
alias wpd="pwd"
alias dpw="pwd"
alias dwp="pwd"
# Python
alias py="python"
alias pys="python -m SimpleHTTPServer"
alias pyk="pkill -9 python"
# TAR
alias tarv="tar tvf"  # View an archive
alias tarc="tar caf"  # Compress an archive
alias untar="tar xvf" # Uncompress an archive
# Vim
alias vmi="vim"
alias mvi="vim"
alias miv="vim"
alias imv="vim"
alias ivm="vim"

## 2d) Common
alias ed="\emacs -nw ~/.diary" # Programmer's Diary
alias eb="\emacs -nw ~/.bashrc"
alias ebb="\emacs -nw ~/.bash_profile"
alias ee="\emacs -nw ~/.emacs"
alias es="\emacs -nw ~/.ssh/config"
alias vb="vim ~/.bashrc"
alias sb="source ~/.bashrc"
alias sbb="source ~/.bash_profile"


## 3) Prompt String
case $OSTYPE in
linux*)
    # Bash Colors
    # Modifiers
    PS_PRE="\["  # Needed for prompt string
    PS_POST="\]" # Needed for prompt string
    PRE="\e["
    DELIM=";"
    POST="m"
    ENDCOLOR="${PRE}0${POST}"

    # Regular
    BLACK="${PRE}0${DELIM}30${POST}"
    BLUE="${PRE}0${DELIM}34${POST}"
    GREEN="${PRE}0${DELIM}32${POST}"
    CYAN="${PRE}0${DELIM}36${POST}"
    RED="${PRE}0${DELIM}31${POST}"
    PURPLE="${PRE}0${DELIM}35${POST}"
    BROWN="${PRE}0${DELIM}33${POST}"
    LIGHTGRAY="${PRE}0${DELIM}37${POST}"
    DARKGRAY="${PRE}1${DELIM}30${POST}"
    LIGHTBLUE="${PRE}1${DELIM}34${POST}"
    LIGHTGREEN="${PRE}1${DELIM}32${POST}"
    LIGHTCYAN="${PRE}1${DELIM}36${POST}"
    BOLDRED="${PRE}1${DELIM}31${POST}"
    LIGHTPURPLE="${PRE}1${DELIM}35${POST}"
    YELLOW="${PRE}1${DELIM}33${POST}"
    WHITE="${PRE}1${DELIM}37${POST}"

    # Prompt String
    STARTCOLOR="${CYAN}"
    export PS1="${PS_PRE}${STARTCOLOR}[\D{%m/%d/%y %r}] \u@\h:\W\$${ENDCOLOR}${PS_POST} "
    alias ps1="export PS1=\"${PS_PRE}${STARTCOLOR}[\D{%m/%d/%y %r}] \u@\h:\W\$${ENDCOLOR}${PS_POST} \""
    alias ps2="export PS1=\"${PS_PRE}${STARTCOLOR}\u:\w\$${ENDCOLOR}${PS_POST} \""
;;
darwin*)
    # Bash Colors
    # Modifiers
    PS_PRE="\["  # Needed for prompt string
    PS_POST="\]" # Needed for prompt string
    PRE="\033["
    REG="${PRE}0;"
    BOLD="${PRE}1;"
    UNDERLINE="${PRE}4;"
    POST="m"
    ENDCOLOR="${PRE}0${POST}"

    # Regular
    BLACK="${REG}30${POST}"
    RED="${REG}31${POST}"
    GREEN="${REG}32${POST}"
    YELLOW="${REG}33${POST}"
    BLUE="${REG}34${POST}"
    PURPLE="${REG}35${POST}"
    CYAN="${REG}36${POST}"
    WHITE="${REG}37${POST}"

    # High Intensity
    HBLACK="${REG}90${POST}"
    HRED="${REG}91${POST}"
    HGREEN="${REG}92${POST}"
    HYELLOW="${REG}93${POST}"
    HBLUE="${REG}94${POST}"
    HPURPLE="${REG}95${POST}"
    HCYAN="${REG}96${POST}"
    HWHITE="${REG}97${POST}"

    # Background
    BBLACK="${PRE}40${POST}"
    BRED="${PRE}41${POST}"
    BGREEN="${PRE}42${POST}"
    BYELLOW="${PRE}43${POST}"
    BBLUE="${PRE}44${POST}"
    BPURPLE="${PRE}45${POST}"
    BCYAN="${PRE}46${POST}"
    BWHITE="${PRE}47${POST}"

    # High Intensity Backgorund
    HBBLACK="${REG}100${POST}"
    HBRED="${REG}101${POST}"
    HBGREEN="${REG}102${POST}"
    HBYELLOW="${REG}3103${POST}"
    HBBLUE="${REG}104${POST}"
    HBPURPLE="${REG}105${POST}"
    HBCYAN="${REG}106${POST}"
    HBWHITE="${REG}107${POST}"

    # Prompt String
    STARTCOLOR="${GREEN}"
    export PS1="${PS_PRE}${STARTCOLOR}[\D{%m/%d/%y %r}] \u@\h:\W\$${ENDCOLOR}${PS_POST} "
    alias ps1="export PS1=\"${PS_PRE}${STARTCOLOR}[\D{%m/%d/%y %r}] \u@\h:\W\$${ENDCOLOR}${PS_POST} \""
    alias ps2="export PS1=\"${PS_PRE}${STARTCOLOR}\u:\w\$${ENDCOLOR}${PS_POST} \""
;;
esac


## 4) Bash Functions

# Kill Child Processes
# Input: PID
# Usage: $ kcp 9540
function kcp() {
    echo "Killing children of: ${1}."
    command="ps fe -o %p --no-headers --ppid ${1}"
    ${command} | xargs kill -15
    echo "Done."
    echo "Killing: ${1}."
    command="ps fe -o %p --no-headers --pid ${1}"
    ${command} | xargs kill -9
    echo "Done."
}
export -f kcp

# Generate "Random Enough" Password
# Input: Number of chars for password length (optional)
# Usage: $ genpasswd [num_chars=16]
function genpasswd() {
    local l=$1
    [ "$l" == "" ] && l=16
    LC_CTYPE=C tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
    # LC_TYPE=C is necessary for Mac OSX.
}
export -f genpasswd
alias gen="genpasswd"

# Better `mkdir`
# Input: list of directories, separated by a space
# Usage: $ mkd dir_to_create0 dir_to_create1 dir_to_create_and_cd_into
# help: https://stackoverflow.com/questions/1853946/getting-the-last-argument-passed-to-a-shell-script
function mkd() { mkdir -p $@ && cd ${@: -1}; }
export -f mkd

# 80 Char Line Checker
# Input: Max number of chars per line and the name of the file to check
# Usage: $ longer line_length filename
function longer() {
    if [ ! -n "$2" ]; then
	echo "usage: $ longer <length_of_line> <file>" && return 1
    fi
    command="sed -n /^.\{$1\}/p $2"
    ${command}
}
export -f longer

# Trailing Whitespace Remover
# Input: Filename
# Usage: $ rem filename
function remove_trailing_spaces() {
    if [ ! -n "$1" ]; then
	echo "usage: $ rem <file>" && return 1
    fi
    sed -i 's/[ \t]*$//' $1
} # aliased, no need to export

# Generic `cd` alias function
# Input: Number of dots that represent number of directories to go down
# Usage: $ . .+
# Example:
#  $ . ...
#  ++ cd ../../../
#
# TODO: BROKEN WITH THE NEW HISTORY FORMAT
#
function dot() {
    command="cd "
    str="`history 1 | perl -pe 's/^ *[0-9]+ +[^ ]+ //'`"
    for (( i=0; i<${#str}; i++)); do
	command="$command../"
    done
    echo "+ ${command}"
    ${command}
} # aliased, no need to export

# Git Hook Checker
# Input: None
# Usage: $ hooks
function hooks() {
    if [[ `git rev-parse --is-bare-repository` == "false" ]]; then
	if [[ `git rev-parse --is-inside-work-tree` == "true" ]]; then
	    gitdir=`git rev-parse --git-dir`
	    echo $(realpath "${gitdir}/hooks/")
	    ls -lh "${gitdir}/hooks/"
	fi
    fi
}
export -f hooks
HOOK_SRC="/path/to/hook" #modifyme
alias hook="cp \${HOOK_SRC} \`findgit\`/hooks"

# Rapid Python Prototyping
function safely_call() {
    local temp_dir="${HOME}/tmp"
    if [[ -d "${temp_dir}" ]]; then
       $1
    else
        echo "Error: ${temp_dir} doesn't exist" >&2
    fi
}
function create_temp_py_file() {
    local temp_dir="${HOME}/tmp"
    local tmpfile="$(mktemp ${temp_dir}/XXXXXXXXXX.py)" || exit 1;
    # These sed's are designed to be cross-platform
    sed -e "s/# Created:/# Created: $(date)/" ${temp_dir}/template.py \
	| sed -e "s/# Author:/# Author:  $(echo $USER)/" > ${tmpfile}
    emacs -nw ${tmpfile}
}
function tmp() {
    safely_call create_temp_py_file
}
export -f tmp
function remove_all_empty_temp_files() {
    local temp_dir="${HOME}/tmp"
    for file in $(\ls "${temp_dir}"); do
        file="${temp_dir}/${file}"
        if [[ $file != "${temp_dir}/template.py" ]]; then
            if [[ ( -z $(\diff "${temp_dir}/template.py" "${file}") ) || ( ! -s "${file}" ) ]]; then
		echo -n "removing ${file}..."
		rm -rf ${file}
		echo -e "\tDone."
            fi
        fi
    done
}
function rmp() {
    safely_call remove_all_empty_temp_files
}
export -f rmp

alias temp="\emacs -nw ${HOME}/tmp/template.py"


## 5) Miscellaneous
# SSH auto-completion based on entries in known_hosts.
if [[ -e ~/.ssh/known_hosts ]]; then
    complete -o default -W "$(cat ~/.ssh/known_hosts | sed 's/[, ].*//' | sort | uniq | grep -v '[0-9]\.' | grep -v '\[')" ssh scp
fi
# Git auto-completion of branch names, need to know which git dir you're *currently* in
#complete -o default -W "$(git for-each-ref --format='%(refname:short)' refs/heads/)" git push
# Set XTERM window name
case "$TERM" in
xterm*|rxvt*)
   PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}| ${USER}@${HOSTNAME}\007"'
   ;;
*)
   ;;
esac

## 6) Machine-Specific

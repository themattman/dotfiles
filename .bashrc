##
# .bashrc
#
# Author:        Matt Kneiser
# Created:       03/19/2014
# Last updated:  12/08/2015
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
# 0) Bashrc Guard
# 1) Internal Functions
# 2) Polyfills
# 3) My world famous aliases
# 4) Prompt String
# 5) Bash Functions
# 6) Bash Completion
# 7) Miscellaneous
# 8) Machine-Specific
# 9) Cleanup


## 0) Bashrc Guard
# The prompt string only gets set on interactive shells.
# Don't apply custom configs if this is the case.
if [ -z "$PS1" ]; then
    return
fi


## 1) Internal Functions
function source_file() {
    if [[ -f $1 ]]; then
        # Printing anything to stdout from a .bashrc breaks scp
        # (and probably other things as well)
        # https://en.wikipedia.org
        #  /wiki
        #  /Secure_copy
        #  #Issues_using_talkative_shell_profiles
        if [[ -n "${SSH_TTY}" ]]; then
            # echo "SSH_TTY - [${SSH_TTY}]"
            source $1 && echo ".:Success! Sourced $1 configs:."
        else
            source $1
        fi
    fi
}


## 2) Polyfills
# Tree
if [[ ! -x $(which tree 2>/dev/null) ]]; then
    alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
fi
# Readlink replacement (for non-Ubuntu)
alias realpath="python -c 'import os, sys; print os.path.realpath(sys.argv[1])'"
# Bash Polyfills
if [[ ! -x $(which wget 2>/dev/null) ]]; then
    alias wget="curl -LO"
fi
alias icurl="curl -I"


## 3) My world famous aliases
#   a) OS-specific
#   b) Basic bash
#   c) Short program
#   d) Common

## 3a) OS-specific aliases
case $OSTYPE in
linux*)
    # tree
    if [[ $(type -P tree) ]]; then
        alias ll="tree --dirsfirst -aLpughDFiC 1"
        alias lk="tree --dirsfirst -LpughDFiC 1"
        alias lsd="ll -d"
        alias treel="tree | less -iFXR"
    fi
    # ls
    alias sl="ls -F --color"
    alias ls="ls -F --color"
    alias lsl="ls -F --color -lh"
    alias lh="ls -F --color -alh"
    alias l="ls -F --color -lh"
    alias als="ls -F --color -alth"
    alias asl="ls -F --color -alth"
    alias las="ls -F --color -alth"
    alias lsa="ls -F --color -alth"
    alias lsar="ls -F --color -alth -r"
    alias sal="ls -F --color -alth"
    alias sla="ls -F --color -alth"
    alias lg="ls -F --color -alth --group-directories-first"

    # Disk Usage
    alias dush="du -sh ./* | sort -h"

    # Ubuntu Package Management
    alias acs="sudo apt-cache search"
    alias agi="sudo apt-get install"

    alias wa="watch -n 1"

    # System Info
    alias cores="cat /proc/cpuinfo | grep -c processor"
    alias os="lsb_release -d | cut -d: -f 2 | sed 's/^\s*//'" # Linux Distro

    # Tabs -> Spaces
    alias tab="expand -i --tabs=4"
;;
darwin*)
    # ls
    alias sl="ls -FGS" # sorted by size
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
    alias os="sw_vers" # -productVersion

    # Tabs -> Spaces
    alias tab="expand -t 4"
;;
esac

## 3b) Basic bash aliases
DATE_FORMAT="+%Y_%m_%d__%H_%M_%S"
alias rem="remove_trailing_spaces"
#alias !="sudo !!" # This is a terrible alias and breaks a lot of stuff
alias c="cd -"     # Use Ctrl-L instead of aliasing this to clear
alias cp="cp -i"   # Warn when overwriting
alias mv="mv -i"   # Warn when overwriting
alias d="diff -U 0"
alias dw="diff -U 0 -w" # Ignore whitespace differences
alias dff="diff --changed-group-format='%<' --unchanged-group-format=''"
alias s="source"
alias a="alias"
alias un="unalias"
alias rd="readlink -f"
alias dx="dos2unix"
alias sum="paste -sd+ - | bc" # A column of numbers should be piped into this one
# Prepare Build Environment
alias pb="ps2 && unsf && una && echo -e '${YELLOW}Build Environment Ready${ENDCOLOR}'"
# Clear all aliases, useful when they get in the way
alias una="unalias -a && alias sbb=\"source ~/.bash_profile\""
alias pu="pushd"
alias po="popd"
alias wh="which"
alias m="man"
alias tlf="tail -f"
alias tl="tail -f"
alias t="tail"
alias chax="chmod a+x"
alias chux="chmod u+x"
alias bell="tput bel"
alias y="yes"
alias no="yes | tr 'y' 'n'"
alias tmake="(\time -v make -j\$(cores)) &> \$(date $DATE_FORMAT)"
alias cdate="date $DATE_FORMAT"
alias nof="find ./ -maxdepth 1 -type f | wc -l" # Faster than: alias nof="ls -l . | egrep -c '^-'"
# Job Control
# http://www.tldp.org/LDP/gs/node5.html#secjobcontrol
alias f="fg"       # Yes, I'm really lazy
alias v="fg -"
alias j="jobs -l"  # Switched these two logically, because
alias jl="jobs"    #  I always want to see the jobs' pids
alias kl="kill %%" # Kill most recent background job
# Print out definition of bash function
alias func="declare -f"  # could also be "type" but more succinct output.
alias funcu="declare -f" # only useful for auto-complete. See `7) Miscellaneous`
alias comp="complete -p"
# Optional Shell Behavior
shopt -s cdable_vars
shopt -s cdspell
shopt -s checkwinsize # Make bash check its window size after a process completes
#shopt -s dirspell
shopt -s histappend   # append history to ~\.bash_history when exiting shell
shopt -s interactive_comments # on by default, but want to ensure comments are ok
#shopt -s nocaseglob # eh? windows?
shopt -s progcomp # on by default
# https://www.gnu.org/software/bash/manual/html_node
#  /Programmable-Completion.html#Programmable-Completion
# Death
alias k="kill -9"    # SIGKILL
alias ke="kill -15"  # SIGTERM
# Machine Control
alias reboot="shutdown -r now"
alias sleep="shutdown -s now"
case $OSTYPE in
linux*)
    # Ctrl-Alt-l also locks screen in Ubuntu or use this alias
    alias afk="gnome-screensaver-command -l"
;;
darwin*)
    # Ctrl-Shift- (<Power Button> or <Eject Button>) locks screen in OSX
    alias afk=""
;;
esac

## 3c) Short program aliases
# CD
#  See `5) Bash Functions`
alias ..="cd .."
# ECHO
alias ec="echo"
alias ep="echo \$PATH"
alias epp="echo \$PYTHONPATH"
alias el="echo \$LD_LIBRARY_PATH"
# Emacs
alias e="\emacs -nw"     # Escape emacs so that -nw only
alias emasc="\emacs -nw" #  gets appended once
alias emacs="\emacs -nw"
# Repo
alias rs="repo sync -j\$(cores)"
# Screen
alias scr="screen -r"
alias sc="screen -S"
alias scl="screen -ls"
alias scd="screen -D -R" # Re-attach to screen that is attached
alias detach="screen -d -m" # Run a command inside screen
# Git
source_file ~/.git-completion
if [[ -f ~/.git-completion ]]; then
    __git_complete ga _git_add
    __git_complete gb _git_branch
    __git_complete gc _git_checkout
    __git_complete gcl _git_clone
    __git_complete gd _git_diff
    __git_complete gdr _git_diff
    __git_complete gl _git_log
    __git_complete g _git_pull
    __git_complete gp _git_push
    __git_complete gpo _git_push
    __git_complete gr _git_reset
    __git_complete gsh _git_show
fi

alias g="git pull origin \$(git rev-parse --abbrev-ref HEAD)"
alias gp="git push"
alias gb="git branch"
alias gba="git branch -a"
alias gvv="git branch -vv"
alias gbl="git blame"
alias ga="git add"
alias gco="git commit"
alias gm="git commit -m"
alias gma="git commit --amend"
alias gmn="git commit --no-verify -m"
alias gmna="git commit --no-verify --amend"
alias gss="git status"
alias gsu="git status -s"
alias gs="git status -s -uno" # Don't show untracked files
alias gd="git diff"
alias gds="git diff --staged"
alias gdss="git diff --stat"
alias gdsss="git diff --staged --stat"
alias gdr="git diff -R"      # Reverse the diff so you can see removed whitespace
alias gdrs="git diff -R --staged"
alias gdbb="git diff -b"
alias gdsb="git diff --staged -b"
alias gdc="echo 'Staged files:' && git diff --name-only --cached"
alias gl="git log"
alias gls="git log --stat"
alias gll='git log --graph --pretty=oneline --abbrev-commit'
alias gg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cblue%an %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias ggs="gg --stat"
alias gsl="git shortlog -sn"            # All authors in this branch's history
alias gnew="git log HEAD@{1}..HEAD@{0}" # Show commits since last pull
alias gc="git checkout"
alias gch="git checkout -- ."
alias gcf="git config --list" # List all inherited Git config values
alias gcl="git clone"
alias gpo="git push origin \$(git rev-parse --abbrev-ref HEAD)"
alias gbr="git rev-parse --abbrev-ref HEAD" # Works on 1.7.x & 1.8.x
alias grf="git reflog" # List all commits current branch points to
alias gsh="git show"
alias gshh="git show HEAD"
alias gshhs="git show HEAD --stat"
alias gshhn="git show HEAD --name-only"
alias gshn="git show --name-only"
alias gshs="git show --stat"
alias gv="git remote -v"
alias gr="git reset"
alias grh="git reset HEAD"
alias grhh="git reset HEAD~1"
alias g--="git --version"
alias ge="git config user.email"
alias gu="git config user.name"
alias gcon="git config"
alias gconl="git config --list"
alias findgit="git rev-parse --git-dir"
alias gitdir="git rev-parse --git-dir"
alias toplevel="dirname \$(git rev-parse --git-dir)"
alias findgits="find . -name .git -type d"
# GREP
alias gre="grep -Iirsn --color=always"   # case-insensitive
alias grel="grep -Iirsnl --color=always" # case-insensitive
alias gree="grep -Irsn --color=always"
alias greel="grep -Irsnl --color=always"
# HISTORY
alias h="history"
alias hist="history | grep -P --color=always \"^.*?]\" | less -iFRX +G"
alias hisd="history -d"
export HISTCONTROL="erasedups"
# Give history timestamps
export HISTTIMEFORMAT="[%F %T] "
# Johannes Gutenberg's Bible
export HISTSIZE=100000
export HISTFILESIZE=100000
 # Easily re-execute the last history command
alias r="fc -s"
# LESS
alias less="\less -iFXR" # I typically don't like aliasing program names
alias les="\less -iFXR +G" # +G goes to end of file

# Node.js
alias n="node"
alias nd="node server"
# Pip
alias de="deactivate"
alias pi="pip install"
alias vv="virtualenv"
# PS
alias psa="ps aux"
alias p="ps aux | grep -v grep | grep \$(echo \$USER)"
alias psm="ps aux | grep mongo | grep -v grep"
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
alias ppwd="echo \${HOSTNAME}:\$(pwd)"
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

## 3d) Common
alias ed="\$EDITOR ~/.diary" # Programmer's Diary
alias eb="\$EDITOR ~/.bashrc"
alias ebb="\$EDITOR ~/.bash_profile"
alias em="\$EDITOR ~/.machine"
alias ee="\$EDITOR ~/.emacs"
alias eg="\$EDITOR ~/.gitconfig"
alias es="\$EDITOR ~/.ssh/config"
alias vb="vim ~/.bashrc"
alias sb="source ~/.bashrc"
alias sbb="source ~/.bash_profile"


## 4) Prompt String
source_file ~/.git-prompt
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
    # For colorizing your prompt, please use $PS_PRE and $PS_POST around the
    #  beginning of all color definitions and at the very end of the prompt
    #  string around the final terminating $ENDCOLOR.
    # It took me over 6 months to figure this out. If you don't have the proper
    #  escaping in your prompt string using $PS_PRE and $PS_POST, scrolling up
    #  for at least 20 commands causes all sorts of issues with getting bash to
    #  write the correct prompt string. Ctrl-l will clear the screen and re-draw
    #  the prompt string correctly in that case.
    PS_STARTCOLOR="${PS_PRE}${STARTCOLOR}${PS_POST}"
    PS_ENDCOLOR="${PS_PRE}${ENDCOLOR}${PS_POST}"
    PS_BRANCHCOLOR="${PS_PRE}${LIGHTCYAN}${PS_POST}"
    PS_STYCOLOR="${PS_PRE}${LIGHTPURPLE}${PS_POST}"
    if [[ ! -f ~/.git-prompt ]]; then
        if [[ -z $SSH_CONNECTION ]]; then
            if [[ -n "$STY" ]]; then
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\ ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            else
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\ ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            fi
        else
            if [[ -n "$STY" ]]; then
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\ ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            else
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\ ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            fi
        fi
    else
        if [[ -z $SSH_CONNECTION ]]; then
            if [[ -n "$STY" ]]; then
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            else
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            fi
        else
            if [[ -n "$STY" ]]; then
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            else
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            fi
        fi
    fi
    alias ps1="export PS1='${PS1}'" # Intentionally not escaping $PS1 varname
    alias ps2="export PS1=\"${PS_STARTCOLOR}\u:\w\$${PS_ENDCOLOR} \""
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
    # ~~See note above in the `Prompt String' section for Linux~~
    PS_STARTCOLOR="${PS_PRE}${STARTCOLOR}${PS_POST}"
    PS_ENDCOLOR="${PS_PRE}${ENDCOLOR}${PS_POST}"
    PS_BRANCHCOLOR="${PS_PRE}${CYAN}${PS_POST}"
    PS_STYCOLOR="${PS_PRE}${HPURPLE}${PS_POST}"
    if [[ ! -f ~/.git-prompt ]]; then
        if [[ -z $SSH_CONNECTION ]]; then
            if [[ -n "$STY" ]]; then
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\ ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            else
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\ ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            fi
        else
            if [[ -n "$STY" ]]; then
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\ ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            else
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\ ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            fi
        fi
    else
        if [[ -z $SSH_CONNECTION ]]; then
            if [[ -n "$STY" ]]; then
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            else
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            fi
        else
            if [[ -n "$STY" ]]; then
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            else
                export PS1="${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            fi
        fi
    fi
    alias ps1="export PS1='${PS1}'" # Intentionally not escaping $PS1 varname
    alias ps2="export PS1='${PS_STARTCOLOR}\u:\w\$${PS_ENDCOLOR} '"
;;
esac
if [[ -z $SSH_CONNECTION ]]; then
    export GIT_PS1_SHOWUNTRACKEDFILES=1
    export GIT_PS1_SHOWDIRTYSTATE=1
    export GIT_PS1_SHOWCOLORHINTS=1
    export GIT_PS1_SHOWUPSTREAM="auto"
fi


## 5) Bash Functions

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
# help: https://stackoverflow.com
#        /questions
#        /1853946
#        /getting-the-last-argument-passed-to-a-shell-script
function mkd() { mkdir -p "${@}" && cd "${@: -1}"; }
function mkdd() {
    local dir=$(date $DATE_FORMAT);
    mkdir -p "${dir}" && cd "${dir}";
}
export -f mkd
export -f mkdd

# 80 Char Line Checker
# Input: Max number of chars per line and the name of the file to check
# Usage: $ longer line_length filename
function longer() {
    if [[ -z $2 ]]; then
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
    if [[ -z $1 ]]; then
        echo "usage: $ rem <file>" && return 1
    fi
    sed -i 's/[ \t]*$//' $1
} # aliased, no need to export

# Generic `cd` alias function
# Input: Number of dots that represent number of directories to go down
# Usage: $ cd [.]+
# Source:
#  http://www.quora.com
#   /What-are-some-time-saving-tips-that-every-Linux-user-should-know
#   /answer
#   /Sasha-Matijasic
function cd() {
local -ri n=${#*};
  # Don't modify cd's behavior if
  #  $ cd
  #  $ cd <dir>
  #  $ cd -
  if [ "$n" -eq 0 -o -d "${!n}" -o "${!n}" == "-" ]; then
    builtin cd "$@";
    # Condense dotted paths to dots
  else
    local e="s:\.\.\.:../..:g";
    builtin cd "${@:1:$n-1}" $(sed -e$e -e$e -e$e <<< "${!n}");
  fi
}
export -f cd

# Git Hook Checker
# Input: None
# Usage: $ hooks
function hooks() {
    if [[ $(git rev-parse --is-bare-repository) == "false" ]]; then
    if [[ $(git rev-parse --is-inside-work-tree) == "true" ]]; then
        gitdir=$(git rev-parse --git-dir)
        echo $(realpath "${gitdir}/hooks/")
        ls -lh "${gitdir}/hooks/"
    fi
    fi
}
export -f hooks
HOOK_SRC="\$(git config --get init.templatedir)"
if [ -n "${HOOK_SRC}" ]; then
    alias hook="cp -rp \${HOOK_SRC}/hooks \$(findgit)/hooks"
fi

# Rapid Python Prototyping
# Usage: $ tmp    # creates temp python file
#        $ rmp    # removes it
function safely_call() {
    local temp_dir="${HOME}/tmp"
    if [[ -d $temp_dir ]]; then
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
    ${EDITOR} ${tmpfile}
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
alias temp="${EDITOR} ${HOME}/tmp/template.py"

function search_file() {
    \grep --color=always -in $1 $2
}
function se() {
    if [ -n "$1" ]; then
        search_file $1 ~/.bashrc
    else
        echo "Error: Missing argument to search for."
    fi
}
export -f se

function unset_custom_functions() {
    counter=0
    if [[ $1 == "f" ]]; then
        echo -n "unsetting all..."
        for i in $(compgen -A function); do
            unset $i
            counter=$((counter+1))
        done
    else
        echo -n "unsetting non-essential..."
        for i in $(compgen -A function); do
            if [[ ! $i =~ "_git" ]]; then
                unset $i
                counter=$((counter+1))
            fi
        done
    fi
    echo " done. ($counter functions unset)"
}
function uns() { unset_custom_functions; }
function unsf() { unset_custom_functions f; }
export -f uns
export -f unsf

# Git Push to all remotes
function gpa() {
        if [[ "function" = $(type -t __git_remotes) ]]; then
        local current_branch=$(git rev-parse --abbrev-ref HEAD)
        for ith_remote in $(__git_remotes); do
            set -x
            git push "${ith_remote}" "${current_branch}"
            { set +x; } 2>/dev/null
        done
    else
        echo "Error: You need to have the well-known ~/.git-completion file." >&2
        echo "It is located at:" >&2
        echo "  https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash" >&2 && return 1
    fi
}
export -f gpa

function create_shortcut() {
    if [[ $# -ne "1" ]]; then
        echo "usage: $ short <shortcut_alias>"
        return
    fi
    echo "alias $1=\"cd ${PWD}\" #generated by alias 'short'" >> ~/.machine
    source_file ~/.machine
    echo "alias $1=\"cd ${PWD}\" #generated by alias 'short'"
}
function short() { create_shortcut "$@"; }
export -f short

#TODO: error check number of args, print usage, --help
function body() {
    sed -n ${1},${2}p ${3}
}
export -f body

#TODO: error check number of args, print usage, --help
function line() {
    sed -n ${1},${1}p ${2}
}
export -f line

case $OSTYPE in
linux*)
    function tabs() {
        if [[ $# -ne 1 ]]; then
            echo "Usage: tabs FILE" >&2 && return 1
        elif [[ ! -f $1 ]]; then
            echo "Error: $1 is not a regular file." >&2 && return 1
        fi
        diff --changed-group-format='%<' --unchanged-group-format='' <(expand -i --tabs=4 "${1}") "${1}"
    }
    export -f tabs

    function numtabs() {
        if [[ $# -ne 1 ]]; then
            echo "Usage: numtabs FILE" >&2 && return 1
        elif [[ ! -f $1 ]]; then
            echo "Error: $1 is not a regular file." >&2 && return 1
        fi
        diff --changed-group-format='%<' --unchanged-group-format='' <(expand -i --tabs=4 "${1}") "${1}" | wc -l
    }
    export -f numtabs

    function untabify() {
        if [[ $# -eq 1 ]]; then
            echo -e "Usage: untabify FILE" >&2 && return 1
        fi
        echo "There are [$(numtabs ${1})] tabs in [${1}]"
        echo "Tabs -> 4 spaces in [${1}]..."
        local tmpfilename="${1}.expanded4.$(date $DATE_FORMAT)"
        tab "${1}" > "${tmpfilename}"
        \mv -i "${tmpfilename}" "${1}"
    }
    export -f untabify
esac

function search_file() { \grep --color=always -in $1 $2; }
# 1: Number of args to calling script
# 2: First arg to calling script (search term)
# 3: File to search
function search_file_wrapper() {
    if [[ $1 -ne 1 ]]; then
        echo "Usage: ${FUNCNAME[1]} SEARCH_TERM" >&2 && return 1
    elif [[ ! -f "$3" ]]; then
        echo "Error: $3 is not a regular file" >&2 && return 1
    fi
    search_file $2 $3
}
function se() { search_file_wrapper $# $1 ~/.bashrc; }
export -f se

# Tell if something is a new alias
function al() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: al ALIAS" >&2 && return 1
    fi
    is_defined=$(type -t $1)
    if [[ -n "${is_defined}" ]]; then
        echo "Yes"
    else
        echo "No"
    fi
}
export -f al

# Generate a TAGS file for emacs
function gentags() {
    if [[ 'c' = $1 ]]; then
        time find . -iname "*.[ch]" -o -iname "*.cc" 2>/dev/null | xargs etags -a 2>/dev/null &
    else
        time find . -iname "*.[ch]" -o -iname "*.cc" -o -iname "*.[ch]pp" 2>/dev/null | xargs etags -a 2>/dev/null &
    fi
}
export -f gentags


## 6) Bash Completion
# enable bash completion in interactive shells
# recursively sources everything in /etc/bash_completion.d/
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
   . /etc/bash_completion
fi

function _add_completion_function() {
    for i in ${@}; do
        # echo "${i}"
        # echo "*${_custom_user_functions[@]}*"
        _custom_user_functions=("${_custom_user_functions[@]}" "${i}")
        # echo "=${_custom_user_functions[@]}="
    done
    alias cust="echo \${_custom_user_functions[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
}
export -f _add_completion_function

function remove_all_completion_functions() {
    # echo "REMOVING ALL [${_custom_user_functions[@]}]"
    if [[ "${#_custom_user_functions}" -gt 0 ]]; then
        for i in "${_custom_user_functions[@]}"; do
            # echo "r - $i"
            complete -r $i 2>/dev/null
        done
    fi
    unset _custom_user_functions
}
export -f remove_all_completion_functions

# Auto-complete only the most recently modified file
function _complete_tl() {
    # echo -e "\nArgs:[$@] C:[${COMP_CWORD}] 1:[$1] 2:[$2]" # For debugging
    if [[ ("${COMP_CWORD}" -eq 1) && (-n "${2}") ]]; then
        local latest_filename=$(find "${2}" -maxdepth 1 -type f -printf '%T@ %f\n' 2>/dev/null | sort -n 2>/dev/null | cut -d' ' -f2- 2>/dev/null | tail -n 1 2>/dev/null)
        if [[ -n "${latest_filename}" ]]; then
            if [[ "${2}" == */ ]]; then
                COMPREPLY="${2}${latest_filename}"
            else
                COMPREPLY="${2}/${latest_filename}"
            fi
        fi
    elif [[ "${COMP_CWORD}" -eq 1 ]]; then
        COMPREPLY=$(\ls -t --color=never | head -n 1)
    fi
}
export -f _complete_tl
complete -o default -F _complete_tl tl l les dx \
    && _add_completion_function tl l les dx

_mkneiser_ssh_completion () {
    # SSH auto-completion based on entries in known_hosts.
    if [[ -f ~/.ssh/known_hosts && -f ~/.ssh/config ]]; then
        ssh_complete="$(cat <(sed 's/[, ].*//' ~/.ssh/known_hosts | grep -v '[0-9]\.' | grep -v '\[') <(grep "^Host" ~/.ssh/config | cut -d ' ' -f 2-) | sort | uniq)"
        alias hosts="echo \${ssh_complete}"
    fi
}

complete -o default -W '$(compgen -A function | grep -v ^_)' func && _add_completion_function func
# Include functions that are prefixed with an underscore
complete -o default -W '$(compgen -A function | grep ^_)' funcu && _add_completion_function funcu

# Add bash auto-completion to `screen -r` alias
function _complete_scr() {
    local does_screen_exist=$(type -t _screen_sessions)
    local cur=$2 # Needed by _screen_sessions
    if [[ "function" = "${does_screen_exist}" ]]; then
        _screen_sessions "Detached"
    fi
}
export -f _complete_scr
complete -F _complete_scr scr && _add_completion_function scr
# Add bash auto-completion to `screen -D -R` alias
function _complete_scd() {
    local does_screen_exist=$(type -t _screen_sessions)
    local cur=$2 # Needed by _screen_sessions
    if [[ "function" = "${does_screen_exist}" ]]; then
        _screen_sessions "Attached"
    fi
}
export -f _complete_scd
complete -F _complete_scd scd && _add_completion_function scd

# Man page auto-completion
complete -W "$(find /usr/share/man/man* -type f | cut -d'/' -f6- | cut -d'.' -f1 | sort | uniq)" man m && _add_completion_function m


## 7) Miscellaneous
# Auto-complete only the most recently modified file
function _complete_tl() {
    # For debugging:
    # echo -e "\nArgs:[$@] C:[${COMP_CWORD}] 1:[$1] 2:[$2]"
    if [[ ("${COMP_CWORD}" -eq 1) && (-n "${2}") ]]; then
        latest_filename=$(find "${2}" -maxdepth 1 -type f -printf '%T@ %f\n' 2>/dev/null | sort -n 2>/dev/null | cut -d' ' -f2- 2>/dev/null | tail -n 1 2>/dev/null)
        if [[ -n "${latest_filename}" ]]; then
            if [[ "${2}" == */ ]]; then
                COMPREPLY="${2}${latest_filename}"
            else
                COMPREPLY="${2}/${latest_filename}"
            fi
        fi
    elif [[ "${COMP_CWORD}" -eq 1 ]]; then
        COMPREPLY=$(ls -t | head -n 1)
    fi
}
export -f _complete_tl
complete -o default -F _complete_tl tl
complete -o default -F _complete_tl l
complete -o default -F _complete_tl les

# SSH auto-completion based on entries in known_hosts.
if [[ -f ~/.ssh/known_hosts && -f ~/.ssh/config ]]; then
    ssh_complete="$(cat <(cat ~/.ssh/known_hosts | sed 's/[, ].*//' | grep -v '[0-9]\.' | grep -v '\[') <(grep "^Host" ~/.ssh/config | cut -d ' ' -f 2-) | sort | uniq)"
    complete -o default -W "${ssh_complete}" ssh scp host
    alias hosts="echo \${ssh_complete}"
fi

complete -o default -W "$(compgen -A function | grep -v ^_)" func
# Include functions that are prefixed with an underscore
complete -o default -W "$(compgen -A function)" funcu

# Set XTERM window name
case "$TERM" in
xterm*|rxvt*)
   PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}| ${USER}@${HOSTNAME}\007"'
   ;;
*)
   ;;
esac


## 8) Machine-Specific
source_file ~/.machine
function sem() { search_file_wrapper $# $1 ~/.machine; }
export -f sem


## 9) Cleanup
unset DATE_FORMAT

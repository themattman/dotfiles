##
# .bashrc
#
# Author:        Matt Kneiser
# Created:       03/19/2014
# Last updated:  08/10/2016
# Configuration: MACHINE_NAME # TODO a script should update this
#
# To refresh bash environment with changes to this file:
#  $ source ~/.bashrc
# or alternatively:
#  $ sb
#
# Notes:
# * Only tested on:
#   * Bash version:
#     * 4.x
#   * Platforms:
#     * Mac OS X 10.11
#     * Ubuntu 12.04
# * TODOs exist for areas of code smell or customizable fields
#
#
# Table of Contents:
# 0) Bashrc Guard
# 1) Internal Functions
# 2) Polyfills
# 3) Aliases
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

# Not doing much at the moment (remember, .bashrc should only be sourced
#  within bash), might want to try something else here
if [[ ! $SHELL =~ "bash" ]]; then
    echo "Not running bash. Exiting. Shell=[${SHELL}]"
    return
fi


## 1) Internal Functions
source_file() {
    if [[ -f $1 ]]; then
        # Printing anything to stdout from a .bashrc breaks scp
        # (and probably other things as well)
        # https://en.wikipedia.org
        #  /wiki
        #  /Secure_copy
        #  #Issues_using_talkative_shell_profiles
        if [[ ((-n "${SSH_TTY}") || (-n "${DESKTOP_SESSION}")) && (-z $2) ]]; then
            # echo "TTY - [${SSH_TTY}], DESKTOP - [${DESKTOP_SESSION}]"
            source $1 && echo ".:Success! Sourced $1 configs:."
        else
            source $1
        fi
    fi
}

declare -A _custom_user_functions
_add_function() {
    local _func="${1}"
    if [[ $# -ne 1 ]]; then
        echo "bad function: $@"
        echo "Usage: ${FUNCNAME[0]} FUNCTION_NAME" >&2 && return 1
    fi
    export -f "${_func}"
    _custom_user_functions["${_func}"]=""
}
_add_function _add_function

declare -A _custom_user_auto_alias_completion_functions
_add_auto_alias_completion_function() {
    local _alias
    for _alias in "${@}"; do
        _custom_user_auto_alias_completion_functions["${_alias}"]=""
    done
}
_add_function _add_auto_alias_completion_function

_optionally_add_completion_function_to_alias() {
    local _alias _second _third _potential_prog _completion_function
    _alias=$1
    _second="${@:2}"
    _third="${@:3}"
    _potential_prog="${_second%% *}"
    if [[ "sudo" = $_potential_prog ]]; then
        if [[ $# -ne 3 ]]; then
            return 1
        else
            _potential_prog="${_third%% *}"
        fi
    else
        if [[ $# -ne 2 ]]; then
            return 1
        fi
    fi
    type -t $_potential_prog >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        return 1
    else
        complete -p $_potential_prog >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            # Chop off name of command, so alias can be appended
            #  to end of completion command
            _completion_function=$(complete -p $_potential_prog | rev | cut -d' ' -f2- | rev)
            ${_completion_function} ${_alias}
            _add_auto_alias_completion_function "${_alias}"
            # echo "auto-detected completion function for alias: [${_alias}] -> [${_completion_function}]"
        else
            return 1
        fi
    fi
}
_add_function _optionally_add_completion_function_to_alias

declare -A _custom_user_aliases
_add_alias() {
    local _alias _cmd _location
    # TODO: Should hostname be part of .machine aliases?? This would help with the error message below
    # TODO: Check for "$" in aliased cmd, and print the evaluated value as well as variable name
    if [[ $# -lt 2 ]]; then
        echo "bad alias: $@"
        echo "Usage: ${FUNCNAME[0]} ALIAS COMMAND" >&2 && return 1
    fi
    _alias="${1}"
    _cmd="${@:2}"
    if [[ -z "${_cmd}" ]]; then
        echo "$(basename -- ${0}): Error: alias [${_alias}] doesn't have a target. You need something to alias this word to" >&2
        return 1
    fi
    type -t "${_alias}" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "$(basename -- ${0}): Error: alias [${_alias}] already exists" >&2
        return 1
    fi
    if [[ ${2% *} = "cd" ]]; then
        _location="${2#* }"
        if [[ ! -d ${_location} && ${_location:0:1} != "$" ]]; then
            echo "$(basename -- ${0}): Error: location [${2#* }] for alias [${1}] is broken and does not exist" >&2
            return 1
        fi
        _cmd="echo -e \"alias [\${PURPLE}${1}\${ENDCOLOR}] cd [\${PURPLE}${2#* }\${ENDCOLOR}]\"; ${_cmd}"
    else
        _cmd="echo -e \"alias [\${PURPLE}${1}\${ENDCOLOR}] to [\${PURPLE}${_cmd//$/\\$}\${ENDCOLOR}]\"; ${_cmd}"
    fi
    alias ${_alias}="${_cmd}"
    _custom_user_aliases["${_alias}"]=""
    _optionally_add_completion_function_to_alias $@
}
_add_function _add_alias

declare -A _custom_user_completion_functions
_add_completion_function() {
    local _completion_func
    for _completion_func in "${@}"; do
        _custom_user_completion_functions["${_completion_func}"]=""
    done
}
_add_function _add_completion_function

declare -A _custom_user_variables
_add_variable() {
    local _variable value
    if [[ $# -lt 2 ]]; then
        echo "bad variable: $@"
        echo "Usage: ${FUNCNAME[0]} VARIABLE VALUE" >&2 && return 1
    fi
    _variable="${1}"
    value="${@:2}"
    export "${_variable}=${value}"
    _custom_user_variables["${_variable}"]=""
}
_add_function _add_variable

_add_alias functions "echo \${!_custom_user_functions[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias auto_added_alias_completion_functions "echo \${!_custom_user_auto_alias_completion_functions[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias aliases "echo \${!_custom_user_aliases[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias completion_functions "echo \${!_custom_user_completion_functions[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias variables "echo \${!_custom_user_variables[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias _everything "echo \${!_custom_user_functions[@]} \${!_custom_user_auto_alias_completion_functions[@]} \${!_custom_user_aliases[@]} \${!_custom_user_completion_functions[@]} \${!_custom_user_variables[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias _num_everything "echo \${!_custom_user_functions[@]} \${!_custom_user_auto_alias_completion_functions[@]} \${!_custom_user_aliases[@]} \${!_custom_user_completion_functions[@]} \${!_custom_user_variables[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' | wc -w"

_remove_all_functions() {
    local counter=0
    echo -n "unsetting all custom user functions..."
    for _func in "${!_custom_user_functions[@]}"; do
        unset $_func &> /dev/null || unset -f $_func
        counter=$((counter+1))
    done
    unset _custom_user_functions
    echo " done. ($counter functions unset)"
}
_add_function _remove_all_functions

_remove_all_aliases() {
    local counter=0
    echo -n "unsetting all custom user aliases..."
    for _alias in "${!_custom_user_aliases[@]}"; do
        unalias "${_alias}"
        counter=$((counter+1))
    done
    unset _custom_user_aliases
    echo " done. ($counter aliases unset)"
}
_add_function _remove_all_aliases

_remove_all_auto_alias_completion_functions() {
    local counter _alias
    counter=0
    echo -n "unsetting all auto-detected alias completion functions..."
    for _alias in "${!_custom_user_auto_alias_completion_functions[@]}"; do
        complete -r $_alias 2>/dev/null
        counter=$((counter+1))
    done
    unset _custom_user_auto_alias_completion_functions
    echo " done. ($counter auto-detected alias completion functions unset)"
}
_add_function _remove_all_auto_alias_completion_functions

_remove_all_completion_functions() {
    local counter=0
    echo -n "unsetting all custom user completion functions..."
    for _completion_func in "${!_custom_user_completion_functions[@]}"; do
        complete -r $_completion_func 2>/dev/null
        counter=$((counter+1))
    done
    unset _custom_user_completion_functions
    echo " done. ($counter completion functions unset)"
}
_add_function _remove_all_completion_functions

_remove_all_variables() {
    local counter=0
    echo -n "unsetting all custom user variables..."
    for _variable in "${!_custom_user_variables[@]}"; do
        if [[ "PS1" != $_variable ]]; then
            unset $_variable
            counter=$((counter+1))
        fi
    done
    unset _custom_user_variables
    echo " done. ($counter variables unset)"
}
_add_function _remove_all_variables

_clear_environment() {
    _remove_all_auto_alias_completion_functions
    _remove_all_aliases
    _remove_all_completion_functions
    _remove_all_variables
    _remove_all_functions
}
_add_function _clear_environment
# _add_alias _all "echo -e \"::Custom User Environment::\"\nFunctions: functions\nAliases: aliases\nCompletion Functions: completion_functions"

_rename_function() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: ${FUNCNAME[0]} ALIAS FUNCTION_NAME" >&2 && return 1
    fi
    if [[ "function" != $(type -t $2) ]]; then
        echo "$(basename -- ${0}): Error: ${2} not a valid function" >&2 && return 1
    fi
    # TODO: Confirm that this technique works cross-platform...
    source /dev/stdin <<EOF
${1}() {
    ${2} \${@};
}
EOF
    _add_function $1
}
_add_function _rename_function


## 2) Polyfills
# Tree
if [[ ! -x $(which tree 2>/dev/null) ]]; then
    _add_alias tree "find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
fi
# Readlink replacement (for non-Ubuntu)
_add_alias realpath "python -c 'import os, sys; print os.path.realpath(sys.argv[1])'"
# Bash Polyfills
if [[ ! -x $(which wget 2>/dev/null) ]]; then
    _add_alias wget "curl -LO"
fi
_add_alias icurl "curl -I"


## 3) Aliases
#   a) OS-specific
#   b) Basic bash
#   c) Short program
#   d) Common

## 3a) OS-specific aliases
case $OSTYPE in
linux*)
    # tree
    if [[ $(type -P tree) ]]; then
        _add_alias ll "tree --dirsfirst -aLpughDFiC 1"
        _add_alias lk "tree --dirsfirst -LpughDFiC 1"
        _add_alias lsd "ll -d"
        _add_alias treel "tree | \less -iFXR"
    fi
    # ls
    _add_alias sl "ls -Slh"
    _add_alias lsl "ls -F --color -lh"
    _add_alias lh "ls -F --color -alh"
    _add_alias l "ls -F --color -lh"
    _add_alias als "ls -F --color -alth"
    _add_alias asl "ls -F --color -alth"
    _add_alias las "ls -F --color -alth"
    _add_alias lsa "ls -F --color -alth"
    _add_alias lsar "ls -F --color -alth -r"
    _add_alias sal "ls -F --color -alth"
    _add_alias sla "ls -F --color -alth"
    _add_alias lg "ls -F --color -alth --group-directories-first"

    # Disk Usage
    _add_alias dush "du -sh ./* | sort -h"

    # Ubuntu Package Management
    _add_alias acs "sudo apt-cache search"
    _add_alias agi "sudo apt-get install"

    _add_alias wa "watch -n 1"

    # System Info
    _add_alias cores "cat /proc/cpuinfo | grep -c processor"
    _add_alias os "lsb_release -d | cut -d: -f 2 | sed 's/^\s*//'" # Linux Distro

    # Tabs -> spaces
    _add_alias tab "expand -i --tabs=4"
;;
darwin*)
    # ls
    _add_alias sl "ls -FGS" # sorted by size
    _add_alias lsl "ls -lh -FG"
    _add_alias lh "ls -alh -FGS"
    _add_alias l "ls -alth -FG"
    _add_alias als "ls -alth -FG"
    _add_alias asl "ls -alth -FG"
    _add_alias las "ls -alth -FG"
    _add_alias lsa "ls -alth -FG"
    _add_alias sla "ls -alth -FG"
    _add_alias sla "ls -alth -FG"
    _add_alias lg "ls -alth -FG"

    # System Info
    _add_alias cores "sysctl hw.ncpu | awk '{print \$2}'"
    _add_alias os "sw_vers" # -productVersion

    # Tabs -> spaces
    _add_alias tab "expand -t 4"
;;
esac

## 3b) Basic bash aliases
DATE_FORMAT="+%Y_%m_%d__%H_%M_%S"
_add_alias rem "remove_trailing_spaces"
#_add_alias ! "sudo !!" # This is a terrible alias and breaks a lot of stuff
_add_alias c "cd \${OLDPWD}" # Use Ctrl-L instead of aliasing this to clear
_add_alias cp "cp -i"        # Warn when overwriting
_add_alias mv "mv -i"        # Warn when overwriting
_add_alias ln "ln -i"        # Warn when overwriting
_add_alias d "diff -U 0"
_add_alias dr "diff -r"
_add_alias dw "diff -U 0 -w" # Ignore whitespace differences
_add_alias dff "diff --changed-group-format='%<' --unchanged-group-format=''"
_add_alias s "source"
_add_alias a "alias"
_add_alias un "unalias"
_add_alias rd "readlink -f"
_add_alias dx "dos2unix"
_add_alias sum "paste -sd+ - | bc" # A column of numbers should be piped into this one
_add_alias pu "pushd"
_add_alias po "popd"
_add_alias wh "which"
_add_alias m "man"
_add_alias tlf "tail -f"
_add_alias tl "tail -f"
_add_alias t "tail"
_add_alias chax "chmod a+x"
_add_alias chux "chmod u+x"
_add_alias bell "tput bel"
_add_alias y "yes"
_add_alias no "yes | tr 'y' 'n'"
_add_alias tmake "(\time -v make -j\$(cores)) &> \$(date $DATE_FORMAT)"
_add_alias cdate "date $DATE_FORMAT"
_add_alias nof "find ./ -maxdepth 1 -type f | wc -l" # Faster than: _add_alias nof "ls -l . | egrep -c '^-'"
_add_alias o "echo \$OLDPWD"
# Job Control
# http://www.tldp.org/LDP/gs/node5.html#secjobcontrol
_add_alias f "fg"       # Yes, I'm really lazy
_add_alias v "fg -"     #  ...stupidly so.
_add_alias j "jobs -l"  # Switched these two logically, because
_add_alias jl "jobs"    #  I always want to see the jobs' pids
_add_alias kl "kill %%" # Kill most recent background job
# Print out definition of bash function
_add_alias func "declare -f"  # could also be "type" but more succinct output.
_add_alias funcu "declare -f" # only useful for auto-complete. See `7) Miscellaneous`
_add_alias comp "complete -p"
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
_add_alias k "kill -9"    # SIGKILL
_add_alias ke "kill -15"  # SIGTERM
# Machine Control
_add_alias reboot_pc "sudo shutdown -r now"
_add_alias sleep_pc "sudo shutdown -s now"
case $OSTYPE in
linux*)
    # Ctrl-Alt-l also locks screen in Ubuntu or use this alias
    _add_alias afk "gnome-screensaver-command -l"
;;
darwin*)
    # Ctrl-Shift- (<Power Button> or <Eject Button>) locks screen in OSX
    _add_alias afk ""
;;
esac

## 3c) Short program aliases
# CD
_add_alias .. "cd .."
# ECHO
_add_alias ec "echo"
_add_alias ep "echo \$PATH"
_add_alias epp "echo \$PYTHONPATH"
_add_alias el "echo \$LD_LIBRARY_PATH"
# Emacs
_add_alias e "\emacs -nw"     # Escape emacs so that -nw only
_add_alias emasc "\emacs -nw" #  gets appended once
_add_alias emacs "\emacs -nw"
# Repo
_add_alias rf "repo forall -c"
_add_alias rfs "repo forall -c 'pwd && git status -s -uno'"
_add_alias rfps "repo forall -c 'pwd && git status -s'"
_add_alias rfg "repo forall -c 'pwd && git remote | xargs -I{} git pull {}'"
#_add_alias rfg "repo forall -c 'pwd && git rev-parse --abbrev-ref HEAD | xargs -I{} git pull origin {}'"
_add_alias rs "repo sync -j\$(cores)"
# Screen
_add_alias scr "screen -r"
_add_alias sc "screen -S"
_add_alias scl "screen -ls"
_add_alias scd "screen -D -R" # Re-attach to screen that is attached
_add_alias detach "screen -d -m" # Run a command inside screen
# Git
source_file ~/.git-completion no_output # Will have to re-source this file later
if [[ -f ~/.git-completion ]]; then
    # TODO: auto-detect git aliases for completions
    __git_complete ga _git_add && _add_completion_function ga
    __git_complete gaf _git_add && _add_completion_function gaf
    __git_complete gau _git_add && _add_completion_function gau
    __git_complete gb _git_branch && _add_completion_function gb
    __git_complete gc _git_checkout && _add_completion_function gc
    __git_complete gcl _git_clone && _add_completion_function gcl
    __git_complete gt _git_stash && _add_completion_function gt
    __git_complete gd _git_diff && _add_completion_function gd
    __git_complete gdbb _git_diff && _add_completion_function gdbb
    __git_complete gdsb _git_diff && _add_completion_function gdsb
    __git_complete gdr _git_diff && _add_completion_function gdr
    __git_complete gdrs _git_diff && _add_completion_function gdrs
    __git_complete gds _git_diff && _add_completion_function gds
    __git_complete gdss _git_diff && _add_completion_function gdss
    __git_complete gdsss _git_diff && _add_completion_function gdsss
    __git_complete gl _git_log && _add_completion_function gl
    __git_complete gls _git_log && _add_completion_function gls
    __git_complete gll _git_log && _add_completion_function gll
    __git_complete gg _git_log && _add_completion_function gg
    __git_complete g _git_pull && _add_completion_function g
    __git_complete gp _git_push && _add_completion_function gp
    __git_complete gpo _git_push && _add_completion_function gpo
    __git_complete gr _git_reset && _add_completion_function gr
    __git_complete gsh _git_show && _add_completion_function gsh
    __git_complete gshh _git_show && _add_completion_function gshh
    __git_complete gshn _git_show && _add_completion_function gshn
    __git_complete gshs _git_show && _add_completion_function gshs
    __git_complete gshhs _git_show && _add_completion_function gshhs
    __git_complete gshhn _git_show && _add_completion_function gshhn
    __git_complete gbd _git_branch && _add_completion_function gbd
fi

_add_alias branches "for k in \$(git branch -r | perl -pe 's/^..(.*?)( ->.*)?\$/\1/'); do echo -e \$(git show --pretty=format:\"%Cgreen%ci %Cblue%cr%Creset \" \$k -- | head -n 1)\\\t\$k; done | sort -r"
_add_alias g "git pull origin \$(git rev-parse --abbrev-ref HEAD)"
_add_alias gf "git fetch"
_add_alias gp "git push"
_add_alias gb "git branch"
_add_alias gba "git branch -a"
_add_alias gvv "git branch -vv"
_add_alias gbl "git blame"
_add_alias ga "git add"
_add_alias gau "git add -u"
_add_alias gaf "git add -f"
_add_alias gco "git commit"
_add_alias gcon "git commit --no-verify"
_add_alias gm "git commit -m"
_add_alias gma "git commit --amend"
_add_alias gmn "git commit --no-verify -m"
_add_alias gmna "git commit --no-verify --amend"
_add_alias gmam "git commit --amend -C HEAD"
_add_alias gmamn "git commit --amend -C HEAD --no-verify"
_add_alias gt "git stash"
_add_alias gtc "git stash clear"
_add_alias gtd "git stash drop"
_add_alias gtl "git stash list"
_add_alias gts "git stash show"
_add_alias gss "git status"
_add_alias gssi "git status --ignored"   # Show ignored files
_add_alias gsu "git status -s --ignored" # Show ignored files
_add_alias gs "git status -s -uno"       # Don't show untracked files
_add_alias gd "git diff"
_add_alias gds "git diff --staged"
_add_alias gdss "git diff --stat"
_add_alias gdsss "git diff --staged --stat"
_add_alias gdr "git diff -R"      # Reverse the diff so you can see removed whitespace
_add_alias gdrs "git diff -R --staged"
_add_alias gdbb "git diff -b"
_add_alias gdsb "git diff --staged -b"
_add_alias gdc "echo 'Staged files:' && git diff --name-only --cached"
_add_alias gl "git log"
_add_alias gls "git log --stat"
_add_alias gll "git log --graph --pretty=oneline --abbrev-commit"
_add_alias gg "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cblue%an %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
_add_alias ggs "gg --stat"
_add_alias gsl "git shortlog -sn"            # All authors in this branch's history
_add_alias gnew "git log HEAD@{1}..HEAD@{0}" # Show commits since last pull
_add_alias gc "git checkout"
_add_alias gch "git checkout -- ."
_add_alias gcf "git config --list" # List all inherited Git config values
_add_alias gpo "git push origin \$(git rev-parse --abbrev-ref HEAD)"
_add_alias gbr "git rev-parse --abbrev-ref HEAD" # Works on 1.7.x & 1.8.x
_add_alias grf "git reflog" # List all commits current branch points to
_add_alias gsh "git show"
_add_alias gshh "git show HEAD"
_add_alias gshhs "git show HEAD --stat"
_add_alias gshhn "git show HEAD --name-only"
_add_alias gshn "git show --name-only"
_add_alias gshs "git show --stat"
_add_alias gv "git remote -v"
_add_alias gr "git reset"
_add_alias grh "git reset HEAD"
_add_alias grhh "git reset HEAD~1"
_add_alias grhhs "git reset HEAD~1 --soft"
_add_alias g-- "git --version"
_add_alias ge "git config user.email"
_add_alias gu "git config user.name"
_add_alias gcn "git config"
_add_alias gconl "git config --list"
_add_alias findgit "git rev-parse --git-dir"
_add_alias gitdir "git rev-parse --git-dir"
_add_alias toplevel "dirname \$(git rev-parse --git-dir)"
_add_alias findgits "find . -name .git -type d -prune | tee gits.txt" # Once found, don't continue to descend under git dir
_add_alias findtags "find . -name .git -type d -prune | xargs -I % sh -c 'echo -en \"%: \"; git --git-dir=% describe --tags --abbrev=0'"
_add_alias authors "git log --format='%ce' | sort | uniq -c"
# GREP
_add_alias gre "grep -iInrs --color=always"   # case-insensitive
_add_alias lgre "grep -iIlnrs --color=always" # case-insensitive
_add_alias hgre "grep -hiIrs --color=always"  # case-insensitive
_add_alias gree "grep -Inrs --color=always"
_add_alias lgree "grep -Ilnrs --color=always"
_add_alias hgree "grep -hIrs --color=always"
# HISTORY
_add_alias h "history"
_add_alias hist "history | grep -P --color=always \"^.*?]\" | \less -iFRX +G"
_add_alias hisd "history -d"
_add_variable HISTCONTROL "erasedups"
# Give history timestamps
_add_variable HISTTIMEFORMAT "[%F %T] "
# Johannes Gutenberg's Bible
_add_variable HISTSIZE 100000
_add_variable HISTFILESIZE 100000
 # Easily re-execute the last history command
_add_alias r "fc -s"
# Networking
_add_alias getip "nslookup"
# LESS
_add_alias less "\less -iFXR" # I typically don't like aliasing program names
_add_alias les "\less -iFXR +G" # +G goes to end of file
# Node.js
_add_alias n "node"
_add_alias nd "node server"
# Pip
_add_alias de "deactivate"
_add_alias pi "pip install"
_add_alias vv "virtualenv"
# PS
_add_alias psa "ps aux"
_add_alias p "ps aux | grep -v grep | grep \$(echo \$USER)"
_add_alias psm "ps aux | grep mongo | grep -v grep"
_add_alias pse "ps fe -o \"%c %p %P\""
_add_alias pe "ps fe -o \"%p\" --no-headers --ppid"
_add_alias pid "ps fe --pid"
_add_alias ppid "ps fe --ppid"
_add_alias psj "ps -jl" # Show ps of all jobs in current shell
# PWD
_add_alias pdw "pwd"
_add_alias wdp "pwd"
_add_alias wpd "pwd"
_add_alias dpw "pwd"
_add_alias dwp "pwd"
_add_alias ppwd "echo \${HOSTNAME}:\$(pwd)"
# Python
_add_alias py "python"
_add_alias pys "python -m SimpleHTTPServer"
_add_alias pyk "pkill -9 python"
# TAR
_add_alias tarv "tar tvf"  # View an archive
_add_alias tarc "tar caf"  # Compress an archive
_add_alias untar "tar xvf" # Uncompress an archive
# Vim
_add_alias vmi "vim"
_add_alias mvi "vim"
_add_alias miv "vim"
_add_alias imv "vim"
_add_alias ivm "vim"
# Android
_add_alias gass "./gradlew assemble"
_add_alias gid "./gradlew installDebug"
_add_alias gaid "./gradlew assemble installDebug"

## 3d) Common
_add_alias ed "\$EDITOR ~/.diary" # Programmer's Diary
_add_alias eb "\$EDITOR ~/.bashrc"
_add_alias ebb "\$EDITOR ~/.bash_profile"
_add_alias em "\$EDITOR ~/.machine"
_add_alias ee "\$EDITOR ~/.emacs"
_add_alias eg "\$EDITOR ~/.gitconfig"
_add_alias es "\$EDITOR ~/.ssh/config"
_add_alias vb "vim ~/.bashrc"
_add_alias sb "ps2; _clear_environment; source ~/.bashrc"
# This command should wipe out the previous environment and start over
_add_alias sbb "ps2; _clear_environment; source ~/.bash_profile"
# Clear all aliases, useful when they get in the way
_add_alias una "ps2; _clear_environment; unalias -a; alias sbb=\"source ~/.bash_profile\""
# Prepare Build Environment
_add_alias pb "una; echo -e '${YELLOW}Build Environment Ready${ENDCOLOR}'"


## 4) Prompt String
source_file ~/.git-prompt
case $OSTYPE in
linux*)
    # Bash Colors
    # Modifiers
    _add_variable PS_PRE "\["  # Needed for prompt string
    _add_variable PS_POST "\]" # Needed for prompt string
    _add_variable PRE "\e["
    _add_variable DELIM ";"
    _add_variable POST "m"
    _add_variable ENDCOLOR "${PRE}0${POST}"

    # Regular
    _add_variable BLACK "${PRE}0${DELIM}30${POST}"
    _add_variable BLUE "${PRE}0${DELIM}34${POST}"
    _add_variable GREEN "${PRE}0${DELIM}32${POST}"
    _add_variable CYAN "${PRE}0${DELIM}36${POST}"
    _add_variable RED "${PRE}0${DELIM}31${POST}"
    _add_variable PURPLE "${PRE}0${DELIM}35${POST}"
    _add_variable BROWN "${PRE}0${DELIM}33${POST}"
    _add_variable LIGHTGRAY "${PRE}0${DELIM}37${POST}"
    _add_variable DARKGRAY "${PRE}1${DELIM}30${POST}"
    _add_variable LIGHTBLUE "${PRE}1${DELIM}34${POST}"
    _add_variable LIGHTGREEN "${PRE}1${DELIM}32${POST}"
    _add_variable LIGHTCYAN "${PRE}1${DELIM}36${POST}"
    _add_variable BOLDRED "${PRE}1${DELIM}31${POST}"
    _add_variable LIGHTPURPLE "${PRE}1${DELIM}35${POST}"
    _add_variable YELLOW "${PRE}1${DELIM}33${POST}"
    _add_variable WHITE "${PRE}1${DELIM}37${POST}"

    # Prompt String
    _add_variable STARTCOLOR "${CYAN}"
    # For colorizing your prompt, please use $PS_PRE and $PS_POST around the
    #  beginning of all color definitions and at the very end of the prompt
    #  string around the final terminating $ENDCOLOR.
    # It took me over 6 months to figure this out. If you don't have the proper
    #  escaping in your prompt string using $PS_PRE and $PS_POST, scrolling up
    #  for at least 20 commands causes all sorts of issues with getting bash to
    #  write the correct prompt string. Ctrl-l will clear the screen and re-draw
    #  the prompt string correctly in that case.
    _add_variable PS_STARTCOLOR "${PS_PRE}${STARTCOLOR}${PS_POST}"
    _add_variable PS_ENDCOLOR "${PS_PRE}${ENDCOLOR}${PS_POST}"
    _add_variable PS_BRANCHCOLOR "${PS_PRE}${LIGHTCYAN}${PS_POST}"
    _add_variable PS_STYCOLOR "${PS_PRE}${LIGHTPURPLE}${PS_POST}"
    # _add_variable PS4 "${LIGHTPURPLE}+${ENDCOLOR} " #messes up scripts :/
    if [[ ! -f ~/.git-prompt ]]; then
        if [[ -z $SSH_CONNECTION ]]; then
            if [[ -n "$STY" ]]; then
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR} ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            else
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR} ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            fi
        else
            if [[ -n "$STY" ]]; then
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR} ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            else
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR} ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            fi
        fi
    else
        if [[ -z $SSH_CONNECTION ]]; then
            if [[ -n "$STY" ]]; then
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            else
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            fi
        else
            if [[ -n "$STY" ]]; then
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            else
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            fi
        fi
    fi
    _add_alias ps1 "_add_variable PS1 '${PS1}'" # Intentionally not escaping $PS1 varname
    _add_alias ps2 "_add_variable PS1 '${PS_STARTCOLOR}\u:\w\$${PS_ENDCOLOR} '"
;;
darwin*)
    # Bash Colors
    # Modifiers
    _add_variable PS_PRE "\["  # Needed for prompt string
    _add_variable PS_POST "\]" # Needed for prompt string
    _add_variable PRE "\033["
    _add_variable REG "${PRE}0;"
    _add_variable BOLD "${PRE}1;"
    _add_variable UNDERLINE "${PRE}4;"
    _add_variable POST "m"
    _add_variable ENDCOLOR "${PRE}0${POST}"

    # Regular
    _add_variable BLACK "${REG}30${POST}"
    _add_variable RED "${REG}31${POST}"
    _add_variable GREEN "${REG}32${POST}"
    _add_variable YELLOW "${REG}33${POST}"
    _add_variable BLUE "${REG}34${POST}"
    _add_variable PURPLE "${REG}35${POST}"
    _add_variable CYAN "${REG}36${POST}"
    _add_variable WHITE "${REG}37${POST}"

    # High Intensity
    _add_variable HBLACK "${REG}90${POST}"
    _add_variable HRED "${REG}91${POST}"
    _add_variable HGREEN "${REG}92${POST}"
    _add_variable HYELLOW "${REG}93${POST}"
    _add_variable HBLUE "${REG}94${POST}"
    _add_variable HPURPLE "${REG}95${POST}"
    _add_variable HCYAN "${REG}96${POST}"
    _add_variable HWHITE "${REG}97${POST}"

    # Background
    _add_variable BBLACK "${PRE}40${POST}"
    _add_variable BRED "${PRE}41${POST}"
    _add_variable BGREEN "${PRE}42${POST}"
    _add_variable BYELLOW "${PRE}43${POST}"
    _add_variable BBLUE "${PRE}44${POST}"
    _add_variable BPURPLE "${PRE}45${POST}"
    _add_variable BCYAN "${PRE}46${POST}"
    _add_variable BWHITE "${PRE}47${POST}"

    # High Intensity Backgorund
    _add_variable HBBLACK "${REG}100${POST}"
    _add_variable HBRED "${REG}101${POST}"
    _add_variable HBGREEN "${REG}102${POST}"
    _add_variable HBYELLOW "${REG}3103${POST}"
    _add_variable HBBLUE "${REG}104${POST}"
    _add_variable HBPURPLE "${REG}105${POST}"
    _add_variable HBCYAN "${REG}106${POST}"
    _add_variable HBWHITE "${REG}107${POST}"

    # Prompt String
    _add_variable STARTCOLOR "${GREEN}"
    # ~~See note above in the `Prompt String' section for Linux~~
    _add_variable PS_STARTCOLOR "${PS_PRE}${STARTCOLOR}${PS_POST}"
    _add_variable PS_ENDCOLOR "${PS_PRE}${ENDCOLOR}${PS_POST}"
    _add_variable PS_BRANCHCOLOR "${PS_PRE}${CYAN}${PS_POST}"
    _add_variable PS_STYCOLOR "${PS_PRE}${HPURPLE}${PS_POST}"
    if [[ ! -f ~/.git-prompt ]]; then
        if [[ -z $SSH_CONNECTION ]]; then
            if [[ -n "$STY" ]]; then
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR} ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            else
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR} ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            fi
        else
            if [[ -n "$STY" ]]; then
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR} ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            else
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR} ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            fi
        fi
    else
        if [[ -z $SSH_CONNECTION ]]; then
            if [[ -n "$STY" ]]; then
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            else
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
            fi
        else
            if [[ -n "$STY" ]]; then
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            else
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}][\${?:0:1}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u@\h:\W\$${PS_ENDCOLOR} "
            fi
        fi
    fi
    _add_alias ps1 "_add_variable PS1 '${PS1}'" # Intentionally not escaping $PS1 varname
    _add_alias ps2 "_add_variable PS1 '${PS_STARTCOLOR}\u:\w\$${PS_ENDCOLOR} '"
;;
esac
if [[ -z $SSH_CONNECTION ]]; then
    _add_variable GIT_PS1_SHOWUNTRACKEDFILES 1
    _add_variable GIT_PS1_SHOWDIRTYSTATE 1
    _add_variable GIT_PS1_SHOWCOLORHINTS 1
    _add_variable GIT_PS1_SHOWUPSTREAM "auto"
fi


## 5) Bash Functions
# Kill Child Processes
kcp() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} PID" >&2 && return 1
    fi
    echo "Killing children of: ${1}."
    local command="ps fe -o %p --no-headers --ppid ${1}"
    ${command} | xargs kill -15
    echo "Done."
    echo "Killing: ${1}."
    command="ps fe -o %p --no-headers --pid ${1}"
    ${command} | xargs kill -9
    echo "Done."
}
_add_function kcp

# Generate "Random Enough" Password
genpasswd() {
    if [[ $# -gt 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} [LENGTH]" >&2 && return 1
    fi
    local l=$1
    [ "$l" == "" ] && l=16
    LC_CTYPE=C tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
    # LC_TYPE=C is necessary for Mac OSX.
}
_add_function genpasswd
_rename_function gen "genpasswd"

# Better `mkdir`
# Input: list of directories, separated by a space
# Usage: $ mkd dir_to_create0 dir_to_create1 dir_to_create_and_cd_into
# help: https://stackoverflow.com
#        /questions
#        /1853946
#        /getting-the-last-argument-passed-to-a-shell-script
mkd() { mkdir -p "${@}" && cd "${@: -1}"; }
_add_function mkd

mkdd() {
    local dir=$(date $DATE_FORMAT);
    mkdir -p "${dir}" && cd "${dir}";
}
_add_function mkdd

# 80 Char Line Checker. Prints lines that have more than LINE_LENGTH characters
longer() {
    if [[ $# -ne 2 ]]; then
        if [[ $# -eq 1 ]]; then
            line_length=80
            file=$1
        else
            echo "Usage: ${FUNCNAME[0]} LINE_LENGTH FILE" >&2 && return 1
        fi
    else
        line_length=$1
        file=$2
    fi
    if [[ ! -f $file ]]; then
        echo "$(basename -- ${0}): Error: $file is not a regular file" >&2 && return 1
    fi
    grep -nE ^.{82} $file | cut -f1 -d: | xargs -I{} sh -c "echo -n "{}:" && sed -n {},{}p $file | grep --color=always -E ^.{81}"
}
_add_function longer

# Trailing Whitespace Remover
remove_trailing_spaces() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} FILE" >&2 && return 1
    elif [[ ! -f $1 ]]; then
        echo "$(basename -- ${0}): Error: $1 is not a regular file" >&2 && return 1
    fi
    sed -i 's/[ \t]*$//' $1
}
_add_function remove_trailing_spaces

# Generic `cd` alias function
# Input: Number of dots that represent number of directories to go down
# Usage: $ cd [.]+
# Source:
#  http://www.quora.com
#   /What-are-some-time-saving-tips-that-every-Linux-user-should-know
#   /answer
#   /Sasha-Matijasic
cd() {
    local -ri n=${#*};
    # Don't modify cd's behavior if
    #  $ cd
    #  $ cd <dir>
    #  $ cd -
    if [ "$n" -eq 0 -o -d "${!n}" -o "${!n}" == "-" ]; then
        builtin cd "$@";
    else
        # Condense dotted paths to dots
        local e="s:\.\.\.:../..:g";
        builtin cd "${@:1:$n-1}" $(sed -e$e -e$e -e$e <<< "${!n}");
    fi
}
_add_function cd

# Git Hook Checker
hooks() {
    if [[ $(git rev-parse --is-bare-repository) == "false" ]]; then
        if [[ $(git rev-parse --is-inside-work-tree) == "true" ]]; then
            local gitdir=$(git rev-parse --git-dir)
            echo $(realpath "${gitdir}/hooks/")
            ls -lh "${gitdir}/hooks/"
        else
            echo "$(basename -- ${0}): Error: not inside working tree." >&2 && return 1
        fi
    else
        echo "$(basename -- ${0}): Error: cannot be in a bare repository." >&2 && return 1
    fi
}
_add_function hooks
HOOK_SRC="\$(git config --get init.templatedir)"
if [[ -n "${HOOK_SRC}" ]]; then
    _add_alias hook "cp -rp \${HOOK_SRC}/hooks \$(findgit)/hooks"
fi

# Rapid Python Prototyping
# Usage: $ tmp    # creates temp python file
#        $ rmp    # removes it
safely_call() {
    local temp_dir="${HOME}/tmp"
    if [[ ! -d $temp_dir ]]; then
        echo "$(basename -- ${0}): Error: ${temp_dir} doesn't exist" >&2 && return 1
    fi
    $1
}
_add_function safely_call

create_temp_py_file() {
    local temp_dir="${HOME}/tmp"
    local tmpfile="$(mktemp ${temp_dir}/XXXXXXXXXX.py)" || return 1;
    # These sed's are designed to be cross-platform
    sed -e "s/# Created:/# Created: $(date)/" ${temp_dir}/template.py \
        | sed -e "s/# Author:/# Author:  $(echo $USER)/" > ${tmpfile}
    ${EDITOR} ${tmpfile}
}
_add_function create_temp_py_file

tmp() {
    safely_call create_temp_py_file
}
_add_function tmp

remove_all_empty_temp_files() {
    local temp_dir="${HOME}/tmp"
    for _file in $(\ls "${temp_dir}"); do
        _file="${temp_dir}/${_file}"
        if [[ $_file != "${temp_dir}/template.py" ]]; then
            if [[ ( -z $(\diff "${temp_dir}/template.py" "${_file}") ) || ( ! -s "${_file}" ) ]]; then
                echo -n "removing ${_file}..."
                rm -rf ${_file}
                echo -e "\tDone."
            fi
        fi
    done
}
_add_function remove_all_empty_temp_files

rmp() {
    safely_call remove_all_empty_temp_files
}
_add_function rmp
_add_alias temp "\${EDITOR} \${HOME}/tmp/template.py"

# Git Push to all remotes
gpa() {
    if [[ "function" = $(type -t __git_remotes) ]]; then
        local current_branch=$(git rev-parse --abbrev-ref HEAD)
        for _ith_remote in $(__git_remotes); do
            set -x
            git push "${_ith_remote}" "${current_branch}"
            { set +x; } 2>/dev/null
        done
    else
        echo "$(basename -- ${0}): Error: You need to have the well-known ~/.git-completion file." >&2
        echo "It is located at:" >&2
        echo "  https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash" >&2 && return 1
    fi
}
_add_function gpa

create_shortcut() {
    if [[ $# -ne "1" ]]; then
        echo "Usage: ${FUNCNAME[0]} NEW_ALIAS" >&2 && return 1
    fi

    is_alias=$(type -t $1)
    if [[ "${is_alias}" = "alias" ]]; then
        echo "$(basename -- ${0}): Error: $1 is already an alias." >&2 && return 1
    fi
    echo "_add_alias $1 \"cd ${PWD// /\\ }\" #generated by alias 'short'" >> ~/.machine
    source_file ~/.machine
    echo "_add_alias $1 \"cd ${PWD// /\\ }\" #generated by alias 'short'"
}
_add_function create_shortcut
_rename_function short "create_shortcut"

body() {
    if [[ $# -ne 3 ]]; then
        echo "Usage: ${FUNCNAME[0]} START FINISH FILE" >&2 && return 1
    elif [[ $3 != "-" && ! -f $3 ]]; then
        echo "$(basename -- ${0}): Error: $3 is not a regular file." >&2 && return 1
    fi
    if [[ $3 = "-" ]]; then
        sed -n ${1},${2}p
    else
        sed -n ${1},${2}p ${3}
    fi
}
_add_function body

line() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: ${FUNCNAME[0]} LINE_NUMBER_TO_ECHO FILE" >&2 && return 1
    elif [[ ! -f $2 ]]; then
        echo "$(basename -- ${0}): Error: $2 is not a regular file." >&2 && return 1
    fi
    sed -n ${1},${1}p ${2}
}
_add_function line

case $OSTYPE in
linux*)
    tabs() {
        if [[ $# -ne 1 ]]; then
            echo "Usage: ${FUNCNAME[0]} FILE" >&2 && return 1
        elif [[ ! -f $1 ]]; then
            echo "$(basename -- ${0}): Error: $1 is not a regular file." >&2 && return 1
        fi
        diff --changed-group-format='%<' --unchanged-group-format='' <(expand -i --tabs=4 "${1}") "${1}"
    }
    _add_function tabs

    numtabs() {
        if [[ $# -ne 1 ]]; then
            echo "Usage: ${FUNCNAME[0]} FILE" >&2 && return 1
        elif [[ ! -f $1 ]]; then
            echo "$(basename -- ${0}): Error: $1 is not a regular file." >&2 && return 1
        fi
        diff --changed-group-format='%<' --unchanged-group-format='' <(expand -i --tabs=4 "${1}") "${1}" | wc -l
    }
    _add_function numtabs

    untabify() {
        if [[ $# -eq 1 ]]; then
            echo -e "Usage: ${FUNCNAME[0]} FILE" >&2 && return 1
        fi
        echo "There are [$(numtabs ${1})] tabs in [${1}]"
        echo "Tabs -> 4 spaces in [${1}]..."
        local tmpfilename="${1}.expanded4.$(date $DATE_FORMAT)"
        tab "${1}" > "${tmpfilename}"
        \mv -i "${tmpfilename}" "${1}"
    }
    _add_function untabify
esac

search_file() { \grep --color=always -in "$1" $2; }
_add_function search_file

# 1: Number of args to calling script
# 2: First arg to calling script (search term)
# 3: File to search
_search_file_wrapper() {
    echo -e "searching for [${LIGHTCYAN}${2}${ENDCOLOR}] in [${LIGHTCYAN}${3}${ENDCOLOR}]" >&2
    if [[ $1 -ne 1 ]]; then
        echo "Usage: ${FUNCNAME[1]} SEARCH_TERM" >&2 && return 1
    elif [[ ! -f "$3" ]]; then
        echo "$(basename -- ${0}): Error: $3 is not a regular file" >&2 && return 1
    fi
    search_file "$2" $3
}
_add_function _search_file_wrapper

se() { _search_file_wrapper $# "$1" ~/.bashrc; }
_add_function se

seb() { _search_file_wrapper $# "$1" ~/.emacs; }
_add_function seb

# 1: Number of args to calling script
# 2: First arg to calling script (search term)
# 3: File to search
_search_file_occur_wrapper() {
    echo -e "occurences of [${LIGHTCYAN}${2}${ENDCOLOR}] in [${LIGHTCYAN}${3}${ENDCOLOR}]:" >&2
    if [[ $1 -ne 1 ]]; then
        echo "Usage: ${FUNCNAME[1]} SEARCH_TERM" >&2 && return 1
    elif [[ ! -f "$3" ]]; then
        echo "$(basename -- ${0}): Error: $3 is not a regular file" >&2 && return 1
    fi
    search_file "$2" $3 | wc -l
}
_add_function _search_file_occur_wrapper

sel() { _search_file_occur_wrapper $# "$1" ~/.bashrc; }
_add_function sel

sebl() { _search_file_occur_wrapper $# "$1" ~/.emacs; }
_add_function sebl

# Tell if something is a new alias
al() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} ALIAS" >&2 && return 1
    fi
    local is_defined=$(type -t $1)
    if [[ -n "${is_defined}" ]]; then
        echo "Yes"
    else
        echo "No"
    fi
}
_add_function al

# Generate a TAGS file for emacs
gentags() {
    if [[ 'c' = $1 ]]; then
        \time -v find . -iname "*.[ch]" -o -iname "*.cc" 2>/dev/null | xargs etags -a 2>/dev/null &
    else
        \time -v find . -iname "*.[ch]" -o -iname "*.cc" -o -iname "*.[ch]pp" 2>/dev/null | xargs etags -a 2>/dev/null &
    fi
}
_add_function gentags

# Similar to mkd() but for Git Clone
gcl() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} URL" >&2 && return 1
    fi
    # echo "\$#: [$#] \$@: [$@] \${!#%.git}: ${!#%.git} basename: $(basename -- ${!#%.git})"
    git clone $@
    if [[ $# -gt 1 ]]; then
        cd $(basename -- ${!#%.git})
    else
        cd $(basename -- ${1%.git})
    fi
}
_add_function gcl

# Similar to mkd() but for unzip(1)
unz() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} URL" >&2 && return 1
    fi
    unzip $1 -d ${1%.zip}
    cd $(basename -- ${1%.zip})
}
_add_function unz

bk() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} PATH" >&2 && return 1
    fi
    set -x
    cp -ipr ${1%/} ${1%/}.bk
    { set +x; } 2>/dev/null
}
_add_function bk

rtrav() {
    test -e $2/$1 && echo $2 || { test $2 != / && rtrav $1 `dirname $2`;};
}
_add_function rtrav

wow() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} COMMAND" >&2 && return 1
    fi
    \ls  $(which "$1")
}
_add_function wow

wowz() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: ${FUNCNAME[0]} COMMAND" >&2 && return 1
    fi
    ls -alh $(which "$1")
}
_add_function wowz

_git_branch_delete() {
    local _branch="${1}"
    if [[ $# -ne 1 ]]; then
        echo "$(basename -- ${0}): Error: only one argument allowed" >&2
        echo "Usage: ${FUNCNAME[0]} BRANCH" >&2
        return 1
    fi
    git rev-parse --verify --quiet "${_branch}" >/dev/null
    if [[ $? -ne 0 ]]; then
        echo "$(basename -- ${0}): Error: branch ${_branch} doesn't exist" >&2
        return 1
    fi
    read -p "Are you sure you want to delete branch [${_branch}]? [y/n]: " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -en "\nDeleting branch [${_branch}] from local and remote..."
        set -x
        git branch -d "${_branch}"
        git push origin ":${_branch}"
        { set +x; } 2>/dev/null
        echo " Done!"
    else
        echo -e "\nExiting."
    fi
}
_add_function _git_branch_delete
_rename_function gbd _git_branch_delete


## 6) Bash Completion
# Enable bash completion in interactive shells
# recursively sources everything in /etc/bash_completion.d/
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
   . /etc/bash_completion
fi
source_file ~/.git-completion # This needs to be re-sourced after
                              #  the previous line. TODO: Consider moving above line
# SSH auto-completion based on entries in known_hosts.
if [[ -f ~/.ssh/known_hosts ]]; then
    ssh_complete="$(sed 's/[, ].*//' ~/.ssh/known_hosts | grep -v '\[' | sort | uniq)"
    _add_alias hosts "echo \${ssh_complete}"
fi
if [[ -f ~/.ssh/config ]]; then
    ssh_complete="$(cat <(echo $ssh_complete) <(grep \"^Host\" ~/.ssh/config | cut -d ' ' -f 2- | tr ' ' '\n') | sort | uniq)"
fi

_complete_most_recently_modified_file() {
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
_add_function _complete_most_recently_modified_file
complete -o default -F _complete_most_recently_modified_file tl l les dx unz \
    && _add_completion_function tl l les dx unz

# Add bash auto-completion to `screen -r` alias
_complete_scr() {
    local does_screen_exist=$(type -t _screen_sessions)
    local cur=$2 # Needed by _screen_sessions
    if [[ "function" = "${does_screen_exist}" ]]; then
        _screen_sessions "Detached"
    fi
}
_add_function _complete_scr
complete -F _complete_scr scr && _add_completion_function scr

# Add bash auto-completion to `screen -D -R` alias
_complete_scd() {
    local does_screen_exist=$(type -t _screen_sessions)
    local cur=$2 # Needed by _screen_sessions
    if [[ "function" = "${does_screen_exist}" ]]; then
        _screen_sessions "Attached"
    fi
}
_add_function _complete_scd
complete -F _complete_scd scd && _add_completion_function scd

_apt_get_install() {
    local cur prev special i;
    COMPREPLY=();
    _get_comp_words_by_ref cur prev;
    if [[ ${#COMP_WORDS[@]} -gt 2 ]]; then
        # Once one package name has been completed, stop
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($( compgen -W '-d -f -h -v -m -q -s -y -u -t -b -c -o \
            --download-only --fix-broken --help --version --ignore-missing \
            --fix-missing --no-download --quiet --simulate --just-print \
            --dry-run --recon --no-act --yes --assume-yes --show-upgraded \
            --only-source --compile --build --ignore-hold --target-release \
            --no-upgrade --force-yes --print-uris --purge --reinstall \
            --list-cleanup --default-release --trivial-only --no-remove \
            --diff-only --no-install-recommends --tar-only --config-file \
            --only-upgrade --option --auto-remove' -- "$cur" ));
    else
        COMPREPLY=($( apt-cache --no-generate pkgnames "$cur" ))
    fi
}
_add_function _apt_get_install
complete -F _apt_get_install agi acs && _add_completion_function agi acs

_mail_addresses() {
    local cur prev special i;
    COMPREPLY=();
    _get_comp_words_by_ref cur prev;
    if [[ -z $USER_EMAIL ]]; then
        return
    fi
    email_address="${USER_EMAIL}"
    email_host="@${USER_EMAIL#*@}"
    # If you have typed a "@" in the most recent word, autocomplete the domain
    # Also if you have typed a subset of my email address, autocomplete the rest
    if [[ $cur == *"@"* ]]; then
        COMPREPLY=("${cur%@*}${email_host}")
    # elif [[ $cur != $email_address && $prev != $email_address ]]; then
    elif [[ (-z $cur || $email_address =~ $cur) && $prev != $email_address ]]; then
        COMPREPLY=($email_address)
    fi
}
_add_function _mail_addresses
complete -F _mail_addresses mail && _add_completion_function mail

_grep_completion() {
    _longopt grep
}
_add_function _grep_completion
complete -F _grep_completion gre gree && _add_completion_function gre gree

complete -W '$(echo ${ssh_complete})' ssh scp host getip && _add_completion_function ssh scp host getip
complete -o default -W '$(compgen -A function | grep -v ^_)' func && _add_completion_function func
complete -o default -W '$(compgen -A function | grep ^_)' funcu && _add_completion_function funcu
complete -f bk && _add_completion_function bk
complete -W "\$(complete -p | rev | cut -d' ' -f1 | rev)" comp && _add_completion_function comp
complete -F _command wow wowz && _add_completion_function wow wowz


## 7) Miscellaneous
# Set XTERM window name
case "$TERM" in
xterm*|rxvt*)
    _add_variable PROMPT_COMMAND 'echo -ne "\033]0;${PWD##*/}| ${USER}@${HOSTNAME}\007"'
;;
*)
;;
esac
_add_variable EDITOR "emacs -nw"
_add_variable GIT_EDITOR "emacs -nw"
_add_variable MAN_PAGER "less -i"
# _add_variable USER_EMAIL "<EMAIL_ADDRESS>" # TODO


## 8) Machine-Specific
source_file ~/.machine
sem() { _search_file_wrapper $# "$1" ~/.machine; }
_add_function sem

seml() { _search_file_occur_wrapper $# "$1" ~/.machine; }
_add_function seml


## 9) Cleanup
unset DATE_FORMAT

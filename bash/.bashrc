##
# .bashrc
#
# Author:        Matt Kneiser
# Created:       03/19/2014
# Last updated:  07/08/2022
#
# To refresh bash environment with changes to this file:
#  $ source ~/.bashrc
# or alternatively:
#  $ sb
#
# Notes:
# * Only tested on:
#   * Bash version:
#     * 4.x, 4.4.x, 5.1.x
#   * Platforms:
#     * Mac OS X 10.11, 12.3
#     * Ubuntu 12.04/14.04/18.04
#
#
# Table of Contents:
# 0) Bashrc Guard
# 1) Internal Functions
# 2) PATH
# 3) Polyfills
# 4) Aliases
# 5) Prompt String
# 6) Bash Functions
# 7) Bash Completion
# 8) Miscellaneous
# 9) Machine-Specific
# 10) Cleanup
# 11) SSH


## 0) Bashrc Guard
# The prompt string only gets set on interactive shells.
# Don't apply custom configs if this is the case.
if [ -z "$PS1" ]; then
    return
fi

# See ~/.screenrc for usage.
if [ "$DISABLE_STARTUP" = "true" ]; then
    PS1="[\D{%m/%d/%y %r}][\${?:0:1}][\${STY}] \u:\W\$ "

    if [[ -n $SSH_AGENT_PID ]] && ps -p $SSH_AGENT_PID >/dev/null; then
        return
    else
        if ls ~/.ssh/id_* &>/dev/null; then
            eval "$(ssh-agent -s)"
            if [[ -x $(which keychain 2>/dev/null) && -f ~/.ssh/id_rsa ]]; then
                if [[ ! -d ~/.keychain ]]; then
                    set -x
                    mkdir -p ~/.keychain
                    { set +x; } &>/dev/null
                fi
                set -x
                keychain id_rsa
                . ~/.keychain/`uname -n`-sh
                { set +x; } &>/dev/null
            fi
        fi
    fi

    return
fi

# Not doing much at the moment (remember, .bashrc should only be sourced
#  within bash), might want to try something else here
if [[ ! $SHELL =~ bash ]]; then
    echo "Not running bash. Exiting. Shell=[${SHELL}]"
    return
fi


## 1) Internal Functions
source_file() {
    if [[ -r $1 ]]; then
        # Printing anything to stdout from a .bashrc breaks scp
        # (and probably other things as well)
        # https://en.wikipedia.org
        #  /wiki
        #  /Secure_copy
        #  #Issues_using_talkative_shell_profiles
        if [[ ((-n "${SSH_TTY}") || (-n "${DESKTOP_SESSION}")) && (-z $2) ]]; then
            # echo "TTY - [${SSH_TTY}], DESKTOP - [${DESKTOP_SESSION}]"
            source "$1" && echo -e ".:${GREEN}Success!${ENDCOLOR} Sourced $1:."
        else
            source "$1"
        fi
    fi
}

declare -A _custom_user_functions
_add_function() {
    local _func="${1}"
    if [[ $# -ne 1 ]]; then
        echo "bad function: $*"
        return $(_error "" "<function_name>")
    fi
    export -f "${_func}"
    _custom_user_functions["${_func}"]=""
}
_add_function _add_function

_error() {
    local _error_msg="${1}"
    local _usage_msg="${2}"
    if [[ -x $(which basename 2>/dev/null) ]]; then
        echo -e "${RED}$(basename -- ${0}): Error:${ENDCOLOR} ${_error_msg}" >&2
    else
        echo -e "${RED}Error:${ENDCOLOR} ${_error_msg}" >&2
    fi
    if [[ -n "${_usage_msg}" ]]; then
        echo -e "${RED}Usage:${ENDCOLOR} ${FUNCNAME[1]} ${_usage_msg}" >& 2
    fi
    return 1
}
_add_function _error

_warning() {
    local _warn_msg="${1}"
    if [[ -x $(which basename 2>/dev/null) ]]; then
        echo -e "${YELLOW}$(basename -- ${0}): Warning:${ENDCOLOR} ${_warn_msg}" >&2
    else
        echo -e "${YELLOW}Warning:${ENDCOLOR} ${_warn_msg}" >&2
    fi
    return 1
}
_add_function _warning

declare -A _custom_user_auto_alias_completion_functions
_add_auto_alias_completion_function() {
    local _alias
    for _alias in "${@}"; do
        _custom_user_auto_alias_completion_functions["${_alias}"]=""
    done
}
_add_function _add_auto_alias_completion_function

# TODO: Add a usage to this function
# Alias shall inherit completion function of the base program it's aliasing
_optionally_add_completion_function_to_alias() {
    local _alias _second _third _potential_prog _prog_type _completion_function
    _alias=$1
    _second="${@:2}"
    _third="${@:3}"
    _potential_prog="${_second%% *}"
    if [[ "sudo" = "$_potential_prog" ]]; then
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
    _prog_type=$(type -t "${_potential_prog}") # >/dev/null 2>&1)
    if [[ $? -ne 0 ]]; then
        # Not a program, thus no completion spec
        return 1
    elif [[ "${_prog_type}" = "alias" ]]; then
        # Recursive aliases
        return 1
    else
        complete -p "${_potential_prog}" >/dev/null 2>&1
        if [[ $? -eq 0 && "${_potential_prog}" != "git" ]]; then
            # Chop off name of command, so alias can be appended
            #  to end of completion command
            _completion_function=$(complete -p "${_potential_prog}" | rev | cut -d' ' -f2- | rev)
            ${_completion_function} "${_alias}"
            _add_auto_alias_completion_function "${_alias}"
            # echo "auto-detected completion function for alias: [${_alias}] -> [${_completion_function}]"
        else
            return 1
        fi
    fi
}
_add_function _optionally_add_completion_function_to_alias

declare -A _custom_user_aliases
declare -A _custom_user_aliases_broken
_add_alias() {
    local _alias _already_exists _cmd _full_cmd _location _host _add_comp_func
    # TODO: Check for "$" in aliased cmd, and print the evaluated value as well as variable name
    #
    # ~~Interface~~
    # [__HOSTNAME__|f]: (optional) ignore machine configs not for current machine,
    #                   or force 'cd' aliases if path doesn't exist
    #            ALIAS: name of alias
    #             [no]: (optional) the string "no" here indicates to NOT prepend the alias with the
    #                    pretty-printed echo. This is for aliases intended to take stdin piped to it
    #          COMMAND: the command to map to the alias
    if [[ $# -lt 2 ]]; then
        return $(_error "bad alias: $*" "[__hostname__] <alias> [no] <command>")
    fi

    # Extract "alias" & "cmd"
    _alias="${1}"
    if [[ ${2} = "no" ]]; then
        _cmd="${@:3}"
    elif [[ ${1:0:2} = "__" ]]; then
        target_hostname=${1:2:-2}
        if [[ "${HOSTNAME}" = "${target_hostname}" ]]; then
            _alias="${2}"
            _cmd="${@:3}"
        else
            return $(_warning "Wrong hostname: [${CYAN}${target_hostname}${ENDCOLOR}], not applying")
        fi
    elif [[ ${1} = "f" && $# -gt 2 ]]; then
        _alias="${2}"
        _cmd="${@:3}"
    else
        _cmd="${@:2}"
    fi

    if [[ -z "${_cmd}" ]]; then
        _custom_user_aliases_broken[${_alias}]="${_cmd}"
        return $(_error "alias [${CYAN}${_alias}${ENDCOLOR}] doesn't have a target. You need something to alias this word to")
    fi

    # Handle alias collision
    _already_exists=$(type -t "${_alias}" 2>&1)
    if [[ $? -eq 0 ]]; then
        if [[ "file" = "${_already_exists}" ]]; then
            _already_exists=$(type -p "${_alias}" 2>&1)
        fi
        if [[ ${_cmd} != ${_custom_user_aliases[${_alias}]} ]]; then
            _custom_user_aliases_broken[${_alias}]="${_cmd}"
        fi
        _warning "alias [${CYAN}${_alias}${ENDCOLOR}] \t already exists as [${PURPLE}${_already_exists}${ENDCOLOR}]"
    fi


    # Wrap "cmd" with pretty-printing
    #
    # 4 classes of aliases:
    # 1: CD commands with a location to be checked
    if [[ ${_cmd% *} = "cd" ]]; then
        _location="${_cmd#* }"
        if [[ ${_cmd} != "cd" && ! -d ${_location} && ${_location:0:1} != "$" && ${_location:0:1} != "." ]]; then
            if [[ ${1} = "f" ]]; then
                # f == --force (typically reserved for relative path aliases)
                _warning "forcing broken cd! => [${CYAN}${_alias}${ENDCOLOR}] to [${PURPLE}${_cmd}${ENDCOLOR}]"
            elif [[ ${1:0:2} = "__" ]]; then
                _host=${1:2:-2}
                if [[ ${_host} == "${HOSTNAME}" ]]; then
                    return $(_error "location [${_location}] for alias [${_alias}] is broken and does not exist due to wrong host, expected host [${_host}]")
                else
                    # ignore, wrong host, not expected to exist
                    return 1
                fi
            else
                return $(_error "location [${_location}] for alias [${_alias}] is broken and does not exist")
                _custom_user_aliases_broken[${_alias}]="${_cmd}"
                return 1
            fi
        fi
        _full_cmd="echo -e \"alias [\${PURPLE}${_alias}\${ENDCOLOR}] cd [\${PURPLE}${_cmd#* }\${ENDCOLOR}]\"; ${_cmd}"


    # 2: Bare commands that accept stdin
    elif [[ ${2} = "no" ]]; then
        _full_cmd="${@:3}"

    # # 3: Echo's that need special escaping
    # elif [[ ${_cmd% *} = "echo" ]]; then #&& ${3:0:1} = '"' ]]; then
    #     echo "HEYYYYYYYYYYYYYYOOOOOOOOOOOOOOOOOOOOOO [${_cmd}]"
    #     _escaped_parens=${_cmd//\"/\\\"} # global substitution - escaping double quotes (" to \")
    #     _full_cmd="echo -e \"alias [\${PURPLE}${_alias}\${ENDCOLOR}] to [\${PURPLE}${_cmd//$/\\$}\${ENDCOLOR}]\"; ${_cmd}"

    # 4: All other aliases that should be wrapped with a pretty-print describing the alias
    #     so the user doesn't get confused by the non-standard behavior of the shell (executing an alias)
    else
        _full_cmd="echo -e \"alias [\${PURPLE}${_alias}\${ENDCOLOR}] to [\${PURPLE}${_cmd//$/\\$}\${ENDCOLOR}]\"; ${_cmd}"
    fi

    # Add alias and cmd to database
    alias ${_alias}="${_full_cmd}"
    _custom_user_aliases["${_alias}"]="${_cmd}"
    if [[ -z ${_add_comp_func+x} ]]; then
        _optionally_add_completion_function_to_alias "$@"
    fi
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
    local _variable _value _contents_of_variable
    if [[ $# -lt 2 ]]; then
        return $(_error "bad variable: $*" "<variable> <value>")
    fi
    _variable="${1}"
    _value="${@:2}"
    eval _contents_of_variable="\$${_variable}"
    if [[ (-n ${_contents_of_variable}) && ("${_variable}" != "PS1") ]]; then
        _warning "variable [${_variable}] \t already exists as [${_contents_of_variable}]"
    fi
    export "${_variable}=${_value}"
    _custom_user_variables["${_variable}"]=""
}
_add_function _add_variable

case $OSTYPE in
linux*|msys*)
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

    # High Intensity Background
    _add_variable HBBLACK "${REG}100${POST}"
    _add_variable HBRED "${REG}101${POST}"
    _add_variable HBGREEN "${REG}102${POST}"
    _add_variable HBYELLOW "${REG}3103${POST}"
    _add_variable HBBLUE "${REG}104${POST}"
    _add_variable HBPURPLE "${REG}105${POST}"
    _add_variable HBCYAN "${REG}106${POST}"
    _add_variable HBWHITE "${REG}107${POST}"
;;
esac

declare -A _custom_user_path_variables
_append_variable_with_path_separator() {
    local _variable _value _contents_of_variable _platform
    if [[ $# -lt 2 || $# -gt 3 ]]; then
        return $(_error "" "<variable> <value> [<platform>]")
    fi
    _variable="${1}"
    _value="${2}"
    _platform="${3}"
    if [[ -n $_platform ]]; then
        local _ostype=$OSTYPE
        if [[ $_ostype =~ "darwin" ]]; then
            _ostype=mac
        fi
        if [[ ! $_platform =~ $_ostype ]]; then
            return $(_error "variable ${_variable} set for os ${_platform} not set for this os ${_ostype}")
        fi
    fi
    if [[ ! -d ${_value} ]]; then
        return $(_error "location ${_value} doesn't exist and won't be appended to ${_variable}")
    fi
    eval _contents_of_variable="\$${_variable}"
    if [[ -z "${_custom_user_path_variables[${_variable}]+x}" ]]; then
        # Variable isn't tracked yet in custom env
        _custom_user_path_variables["${_variable}"]="${_contents_of_variable}"
        if [[ -z "${_contents_of_variable}" ]]; then
            export "${_variable}=${_value}"
        else
            export "${_variable}=${_contents_of_variable}:${_value}"
        fi
    else
        export "${_variable}=${_contents_of_variable}:${_value}"
    fi
}
_add_function _append_variable_with_path_separator

_prepend_variable_with_path_separator() {
    local _variable _value _contents_of_variable _platform
    if [[ $# -lt 2 || $# -gt 3 ]]; then
        return $(_error "" "<variable> <value> [<platform>]")
    fi
    _variable="${1}"
    _value="${2}"
    _platform="${3}"
    if [[ -n $_platform ]]; then
        local _ostype=$OSTYPE
        if [[ $_ostype =~ "darwin" ]]; then
            _ostype=mac
        fi
        if [[ ! $_platform =~ $_ostype ]]; then
            return $(_error "variable ${_variable} set for os ${_platform} not set for this os ${_ostype}")
        fi
    fi
    if [[ ! -d ${_value} ]]; then
        return $(_error "location ${_value} doesn't exist and won't be appended to ${_variable}")
    fi
    eval _contents_of_variable="\$${_variable}"
    if [[ -z "${_custom_user_path_variables[${_variable}]+x}" ]]; then
        # Variable isn't tracked yet in custom env
        _custom_user_path_variables["${_variable}"]="${_contents_of_variable}"
        if [[ -z "${_contents_of_variable+x}" ]]; then
            export "${_variable}=${_value}"
        else
            export "${_variable}=${_value}:${_contents_of_variable}"
        fi
    else
        export "${_variable}=${_value}:${_contents_of_variable}"
    fi
}
_add_function _prepend_variable_with_path_separator

_add_alias functions "echo \${!_custom_user_functions[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias auto_added_alias_completion_functions "echo \${!_custom_user_auto_alias_completion_functions[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias aliases "echo \${!_custom_user_aliases[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias completion_functions "echo \${!_custom_user_completion_functions[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias variables "echo \${!_custom_user_variables[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias _everything "echo \${!_custom_user_functions[@]} \${!_custom_user_auto_alias_completion_functions[@]} \${!_custom_user_aliases[@]} \${!_custom_user_completion_functions[@]} \${!_custom_user_variables[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' && echo"
_add_alias _num_everything "echo \${!_custom_user_functions[@]} \${!_custom_user_auto_alias_completion_functions[@]} \${!_custom_user_aliases[@]} \${!_custom_user_completion_functions[@]} \${!_custom_user_variables[@]} | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//' | wc -w"

check_all_aliases() {
    for _alias in "${!_custom_user_aliases[@]}"; do
        #echo "alias [$_alias] -> ${_custom_user_aliases[${_alias}]}"
        if [[ ${_custom_user_aliases[${_alias}]%% *} = "cd" ]]; then
            echo "${_custom_user_aliases[${_alias}]}"
        fi
    done
}
_add_function check_all_aliases

_remove_all_of() {
    local _counter=0
    local _name="${1,,}"
    local _name_lowercase="${_name,,}"
    local _objects="${@:2}"
    local _num_objects=$(($#-1))
    echo -n "unsetting all ${_name} (${_num_objects} set)..."
    for _object in ${_objects[@]}; do
        #echo "unset: ${_object}"
        if [[ "${_name}" = "aliases" ]]; then
            unalias "${_object}"
        elif [[ "${_name}" =~ "completion" ]]; then
            complete -r $_object 2>/dev/null
        elif [[ "${_name}" = "PATH variables" ]]; then
            if [[ -n ${_object+x} ]]; then
                # echo "  [${_custom_user_path_variables[${_var}]}]"
                # Reset to original value
                export ${_object}="${_custom_user_path_variables[${_var}]}"
            fi
        else
            unset $_object &> /dev/null || unset -f $_object
        fi
        _counter=$((_counter+1))
    done
    eval "unset _custom_user_${_name_lowercase// /_}"
    echo " done. (${_counter} unset)"
}
_add_function _remove_all_of

_remove_path() {
    local _counter=0
    echo -n "unsetting all custom user paths (${#_custom_user_path_variables[@]} set)..."
    for _var in "${!_custom_user_path_variables[@]}"; do
        # echo "var: [${_var}] = "
        _counter=$((_counter+1))
    done
    unset _custom_user_path_variables
    echo " done. (${_counter} unset)"
}

_clear_environment() {
    echo -en "${LIGHTGRAY}"
    _remove_all_of "auto alias completion functions" "${!_custom_user_auto_alias_completion_functions[@]}"
    _remove_all_of "aliases" "${!_custom_user_aliases[@]}"
    _remove_all_of "aliases_broken" "${!_custom_user_aliases_broken[@]}"
    _remove_all_of "completion functions" "${!_custom_user_completion_functions[@]}"
    _remove_all_of "variables" "${!_custom_user_variables[@]}"
    _remove_all_of "PATH variables" "${!_custom_user_path_variables[@]}"
    _remove_all_of "functions" "${!_custom_user_functions[@]}"
    PS1=${PS1_prev:-"$ "}
    echo -e "${YELLOW}${ENDCOLOR}[${CYAN}${FUNCNAME[0]}${ENDCOLOR}] done."
}
_add_function _clear_environment
# _add_alias _all "echo -e \"::Custom User Environment::\"\nFunctions: functions\nAliases: aliases\nCompletion Functions: completion_functions"

_rename_function() {
    if [[ $# -ne 2 ]]; then
        return $(_error "Requires 2 arguments" "<function_name> <alias>")
    fi
    local _function_name=$1
    local _alias=$2
    if [[ "function" != $(type -t "$_function_name") ]]; then
        return $(_error "${_function_name} not a valid function")
    fi
    # TODO: Confirm that this technique works cross-platform...
    source /dev/stdin <<EOF
${_alias}() {
    ${_function_name} \${@};
}
EOF
    _add_function "$_alias"
}
_add_function _rename_function

_add_variable DOTFILES_LOCATION ~/dotfiles # TODO
dba() {
    {
        for _dotfile in $(\ls -a "${DOTFILES_LOCATION}" | grep "^\." | grep -Ev "^(\.|\.\.|\.git)$"); do
            echo "+ diff ${_dotfile}"
            \diff -u --color "${DOTFILES_LOCATION}/${_dotfile}" ~/"${_dotfile}" | grep -v "Only in"
        done
    } 2>&1 | \less -iFRX
}
_add_function dba

cpa() {
    _dotfiles=$(find "${DOTFILES_LOCATION}" -type f -path "${DOTFILES_LOCATION}/.*" \
                     -not -path "${DOTFILES_LOCATION}/.git*" -a -not -path "${DOTFILES_LOCATION}/templates*" \
                     -printf "%P\n")
                     # -printf "%h/%f\n" \
                     #   | sed -e "s/^${DOTFILES_LOCATION//\//\\/}\///" -)
    for _dotfile in ${_dotfiles}; do
        echo "${_dotfile}"
        if [[ -d "${DOTFILES_LOCATION}/${_dotfile}" ]]; then
            \diff -qr ~/"${_dotfile}" "${DOTFILES_LOCATION}/${_dotfile}" 2>/dev/null 2>&1
        elif [[ -f "${DOTFILES_LOCATION}/${_dotfile}" ]]; then
            \diff -q ~/"${_dotfile}" "${DOTFILES_LOCATION}/${_dotfile}" 2>/dev/null 2>&1
        fi
        if [[ $? -ne 0 ]]; then
            if [[ -d "${DOTFILES_LOCATION}/${_dotfile}" ]]; then
                echo "+ cp -ir ~/${_dotfile} ${DOTFILES_LOCATION}/${_dotfile}"
                \cp -ir ~/"${_dotfile}" "${DOTFILES_LOCATION}/${_dotfile}"
            elif [[ -f "${DOTFILES_LOCATION}/${_dotfile}" ]]; then
                echo "+ cp -i ~/${_dotfile} ${DOTFILES_LOCATION}/${_dotfile}"
                \cp -i ~/"${_dotfile}" "${DOTFILES_LOCATION}/${_dotfile}"
            fi
        fi
    done
}
_add_function cpa


## 2) PATH
# Basic PATHs
_append_variable_with_path_separator PATH "/usr/local/bin"
_append_variable_with_path_separator PATH "/usr/bin"
_append_variable_with_path_separator PATH "/bin"
_append_variable_with_path_separator PATH "/opt/homebrew/bin" mac

_append_variable_with_path_separator PATH "${HOME}/.cargo/bin"

# Android Studio/Intellij Paths
# _append_variable_with_path_separator PATH /usr/lib/jvm/java-1.7.0-openjdk-amd64/bin
# _add_variable JAVA_HOME /usr/lib/jvm/java-1.7.0-openjdk-amd64
# _append_variable_with_path_separator PATH "$JAVA_HOME"

# Icecream distributed compiler cluster
#_prepend_variable_with_path_separator PATH /usr/lib/icecc/bin

# local binaries
# _append_variable_with_path_separator PATH $HOME/bin #begin
# _append_variable_with_path_separator PATH /usr/bin
# _append_variable_with_path_separator PATH /bin

_append_variable_with_path_separator PATH /usr/local/sbin
_append_variable_with_path_separator PATH /usr/sbin
_append_variable_with_path_separator PATH /sbin

_add_variable EMACS_INIT_FILE "~/.emacs.d/configuration.org"

# Make sure IFS is set correctly
unset IFS

# Make backspace work in Emacs
# TODO: make these work conditionally based on OS/Environ
#stty erase ^H
_add_variable LANG C
stty ixany       # Turn off Ctrl-S XOFF "feature", particularly helpful for
stty ixoff -ixon #  GNU screen sessions.
                 #  https://raamdev.com
                 #   /2007
                 #   /recovering-from-ctrls-in-putty
#stty ek

case $OSTYPE in
linux*)
    source_file /etc/bash_completion
;;
darwin*)
    source_file $(brew --prefix)/etc/profile.d/bash_completion.sh
;;
esac

## 3) Polyfills
# Tree
if [[ ! -x $(which tree 2>/dev/null) ]]; then
    _add_alias tree "find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
    # TODO exclude .git tree
fi
# Readlink replacement (for non-Ubuntu)
if [[ -x $(which python 2>/dev/null) ]]; then
    _add_variable PYTHON_VERSION $(python -c 'import sys; print(sys.version_info[0])')
    case $PYTHON_VERSION in
    2*)
        _add_alias pys "python -m SimpleHTTPServer"
        _add_alias realpath "python -c 'import os.path, sys; print os.path.realpath(sys.argv[1])'"
    ;;
    3*)
        _add_alias pys "python -m http.server"
        _add_alias realpath "python -c 'import os.path, sys; print os.path.realpath(sys.argv[1])'"
    ;;
    esac
fi

# Bash Polyfills
if [[ ! -x $(which wget 2>/dev/null) ]]; then
    _add_alias wget "curl -LO"
fi
_add_alias icurl "curl -I"
# TODO: check "_longopt" or something else to check for bash_completion


## 4) Aliases
#   a) OS-specific
#   b) Basic bash
#   c) Short program
#   d) Common

## 4a) OS-specific aliases
case $OSTYPE in
linux*|msys*)
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
    _add_alias lsa "ls -F --color -alh"
    _add_alias lsah "ls -F --color -althH" # Follow symlinks
    _add_alias lsar "ls -F --color -alth -r"
    _add_alias sal "ls -F --color -alth"
    _add_alias sla "ls -F --color -alth"
    _add_alias lg "ls -F --color -alth --group-directories-first"
    _add_alias ll "ls --color -ldh */" # Only list dirs

    # Disk Usage
    _add_alias dush "du -sh ./* | sort -h"
    _add_alias dut "du -shx ./* | sort -rh | head"

    # Ubuntu Package Management
    _add_alias acs "sudo apt-cache search"
    # _add_alias agi "sudo apt-get install" # see agi function
    _add_alias agu "sudo apt-get install --only-upgrade"

    _add_alias wa "watch -n 1"

    # System Info
    _add_alias cores "grep -c ^processor /proc/cpuinfo"
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
    _add_alias lsa "ls -alh -FG"
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

## 4b) Basic bash aliases
_add_alias sx "set +x"
_add_variable DATE_FORMAT "+%Y_%m_%d__%H_%M_%S"
_add_alias rem "remove_trailing_spaces"
# _add_alias find "find -L" # Too invasive, just don't forget to add -L for symbolic links
#_add_alias ! "sudo !!" # This is a terrible alias and breaks a lot of stuff
_add_alias c "cd \${OLDPWD}" # Use Ctrl-L instead of aliasing this to clear
_add_alias cp "cp -i"        # Warn when overwriting
_add_alias mv "mv -i"        # Warn when overwriting
_add_alias ln "ln -i"        # Warn when overwriting
_add_alias d "diff --color -U 0"
_add_alias dr "diff --color -r"
_add_alias dy "diff --color -y -W 180"
_add_alias dyf "diff --color -y -W 180 --suppress-common-lines"
_add_alias dw "diff -U 0 -w --color" # Ignore whitespace differences
_add_alias dff "diff --changed-group-format='%<' --unchanged-group-format=''"
_add_alias s "source"
_add_alias a "alias"
_add_alias un "unalias"
_add_alias rd "readlink -f"
_add_alias dx "dos2unix"
_add_alias sum "paste -sd+ - | bc" # A column of numbers should be piped into this one
_add_alias avg "awk '{ sum += \$0 } END { if (NR > 0) print sum / NR }'" # Ditto, spits out a float, TODO doesn't work yet
_add_alias pu "pushd"
_add_alias po "popd"
_add_alias wh "which"
_add_alias m "man"
_add_alias tlf "tail -f"
_add_alias tl "tail -f"
_add_alias t "tail"
_add_alias bp "bind -p" # list all GNU Readline keyboard bindings
_add_alias bl "bind -l" # list all GNU Readline functions
_add_alias bv "bind -V"
_add_alias bs "bind -S"
_add_alias chax "chmod a+x"
_add_alias chux "chmod u+x"
_add_alias bell "tput bel"
_add_alias y "yes"
_add_alias no "yes | tr 'y' 'n'"
_add_alias tmake "(\time -v make -j\$(cores)) &> \$(date $DATE_FORMAT)"
_add_alias cdate "date $DATE_FORMAT"
_add_alias nof "find ./ -maxdepth 1 -type f | wc -l" # Faster than: _add_alias nof "ls -l . | egrep -c '^-'"
_add_alias old "echo \$OLDPWD"
_add_alias sus no "sort | uniq -c | sort -h"
_add_alias blame  no "cut -d':' -f1,2 | tr ':' ' ' | while read f g; do git --no-pager blame -L\$g,\$g \$f 2>/dev/null | cut -d'(' -f2 | awk '{print \$1}'; done | sus"
_add_alias blamer no "cut -d':' -f1,2 | tr ':' ' ' | while read f g; do git --no-pager blame -L\$g,\$g \$f 2>/dev/null; done"
_add_alias extensions "find . -type f | awk -F. '!a[\$NF]++{print \$NF}'"
_add_alias spell "aspell -c -l en_US"
# Job Control
# http://www.tldp.org/LDP/gs/node5.html#secjobcontrol
_add_alias f "fg"       # Yes, I'm really lazy
_add_alias v "fg -"     #  ...stupidly so.
_add_alias j "jobs -l"  # Switched these two logically, because
_add_alias jl "jobs"    #  I always want to see the jobs' pids
_add_alias kl "kill %%" # Kill most recent background job
# Print out definition of bash function
_add_alias func "declare -f"  # could also be "type" but more succinct output.
_add_alias funcu "declare -f" # only useful for auto-complete. See `8) Miscellaneous`
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
# darwin*)
#     # Ctrl-Shift- (<Power Button> or <Eject Button>) locks screen in OSX
#     # Ctrl-Cmd-q locks screen in OSX
#     _add_alias afk ""
# ;;
esac

## 4c) Short program aliases
# CD
_add_alias .. "cd .."
_add_alias dots "cd ${DOTFILES_LOCATION}"
# ECHO
_add_alias ec "echo"
_add_alias ep "echo \$PATH"
_add_alias epp "echo \$PYTHONPATH"
#_add_alias el "echo \$LD_LIBRARY_PATH"
# Repo
_add_alias rf "repo forall -c"
_add_alias rfs "repo forall -c 'pwd && git status -s -uno'"
_add_alias rfb "repo forall -pc 'git rev-parse --abbrev-ref HEAD'"
_add_alias rfps "repo forall -c 'pwd && git status -s'"
_add_alias rfg "repo forall -c 'pwd && git remote | xargs -I{} git pull {}'"
#_add_alias rfg "repo forall -c 'pwd && git rev-parse --abbrev-ref HEAD | xargs -I{} git pull origin {}'"
#_add_alias rs "repo sync -j\$(cores)"
_add_alias rs "repo sync -j16 --no-tags --force-sync"
# Screen
_add_alias scr "screen -r"
_add_alias sc "screen -S"
_add_alias scl "screen -ls"
_add_alias scd "screen -D -R" # Re-attach to screen that is attached
_add_alias detach "screen -d -m" # Run a command inside screen
_add_variable LOCKPRG "/bin/true"  # Disable the password feature which has locked up many sessions of mine
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
    __git_complete glsn _git_log && _add_completion_function glsn
    __git_complete glo _git_log && _add_completion_function glo
    __git_complete gll _git_log && _add_completion_function gll
    __git_complete gg _git_log && _add_completion_function gg
    __git_complete g _git_pull && _add_completion_function g
    __git_complete gp _git_push && _add_completion_function gp
    __git_complete gpo _git_push && _add_completion_function gpo
    __git_complete gpr _git_push && _add_completion_function gpr
    __git_complete gr _git_reset && _add_completion_function gr
    __git_complete gsh _git_show && _add_completion_function gsh
    __git_complete gshh _git_show && _add_completion_function gshh
    __git_complete gshn _git_show && _add_completion_function gshn
    __git_complete gshs _git_show && _add_completion_function gshs
    __git_complete gshhs _git_show && _add_completion_function gshhs
    __git_complete gshhss _git_show && _add_completion_function gshhss
    __git_complete gshhn _git_show && _add_completion_function gshhn
    __git_complete gbd _git_branch && _add_completion_function gbd
    __git_complete gmm _git_merge && _add_completion_function gmm
    __git_complete gmb _git_checkout && _add_completion_function gmb
fi

_add_alias rbranches "for k in \$(git branch -r | perl -pe 's/^..(.*?)( ->.*)?\$/\1/'); do echo -e \$(git show --pretty=format:\"%Cgreen%ci %Cblue%cr%Creset \" \$k -- | head -n 1)\\\t\$k; done | sort -r"
_add_alias branches  "for k in \$(git branch | perl -pe 's/^..(.*?)( ->.*)?\$/\1/'); do echo -e \$(git show --pretty=format:\"%Cgreen%ci %Cblue%cr%Creset \" \$k -- | head -n 1)\\\t\$k; done | sort -r | head -n 30"
_add_alias redate_head "_CUR_DATE=\$(date); git commit --amend --no-verify -C HEAD --date=\"\${_CUR_DATE}\"; unset _CUR_DATE;"
_add_alias gf "git fetch"
_add_alias gft "git fetch --tags"
_add_alias gp "git push"
_add_alias gb "git branch"
_add_alias gba "git branch -a"
_add_alias gvv "git branch -vv"
_add_alias gmb "git merge-base"        # Find best common ancestor of two branches
_add_alias gmba "git merge-base --all" # Find all common ancestors of two branches
_add_alias gbl "git blame"
_add_alias ga "git add"
_add_alias gau "git add -u"
_add_alias gaf "git add -f"
_add_alias gco "git commit"
_add_alias gcon "git commit --no-verify"
_add_alias gauth "git commit --no-verify --amend -C HEAD --reset-author"
_add_alias gm "git commit -m"
_add_alias gca "git commit --amend"
_add_alias gmn "git commit --no-verify -m"
_add_alias gmna "git commit --no-verify --amend"
_add_alias gmam "git commit --amend -C HEAD"
_add_alias gmamn "git commit --amend -C HEAD --no-verify"
_add_alias gtu "git restore --staged" # Unstage
_add_alias gma "git merge --abort"
_add_alias gmm "git merge --no-ff"
_add_alias gt "git stash"
_add_alias gta "git stash apply"
_add_alias gtas "git stash apply stash@{0}"
_add_alias gtt "git show stash@{0}"
_add_alias gttn "git show --name-only stash@{0}"
_add_alias gtts "git show --stat stash@{0}"
_add_alias gtc "git stash clear"
_add_alias gtd "git stash drop"
_add_alias gtl "git stash list"
_add_alias gts "git stash show"
_add_alias gss "git status"
_add_alias gssi "git status --ignored"   # Show ignored files
_add_alias gsu "git status -s --ignored" # Show ignored files
_add_alias gs "git status -s -uno"       # Don't show untracked files
_add_alias gsm "git status -s -uno | grep '^ M'"
_add_alias gd "git diff"
_add_alias gdn "git diff --name-only"
_add_alias gdns "git diff --name-only --staged"
_add_alias gds "git diff --staged"
_add_alias gdss "git diff --stat"
_add_alias gdsss "git diff --staged --stat"
_add_alias gdr "git diff -R"      # Reverse the diff so you can see removed whitespace
_add_alias gdrs "git diff -R --staged"
_add_alias gdbb "git diff -b"
_add_alias gdsb "git diff --staged -b"
_add_alias gdc "echo 'Staged files:' && git diff --name-only --cached"
_add_alias gdscrb "git describe"
_add_alias gl "git log"
_add_alias gls "git log --stat"
_add_alias glsp "git log --pretty=fuller --stat"
_add_alias glsn "git log --stat -n 3"
_add_alias glo "git log --oneline"
_add_alias gll "git log --graph --pretty=oneline --abbrev-commit"
_add_alias gg "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cblue%an %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
_add_alias ggs "gg --stat"
_add_alias gsl "git shortlog -sn"            # All authors in this branch's history
_add_alias gnew "git log HEAD@{1}..HEAD@{0}" # Show commits since last pull
_add_alias gpb "git rev-parse --abbrev-ref @{-1}"
_add_alias gpbp "git reflog | grep -i \"checkout: moving\" | cut -d' ' -f6 | head | nl"
_add_alias gpbpe "git reflog | grep -i 'checkout: moving' | cut -d' ' -f6 | head -n 30 | nl"
_add_alias gc "git checkout"
_add_alias gch "git checkout -- ."
_add_alias gcp "git cherry-pick"
_add_alias gcpx "git cherry-pick -x"
_add_alias gcpa "git cherry-pick --abort"
_add_alias gcpc "git cherry-pick --continue"
_add_alias gcpcn "git cherry-pick --continue --no-verify"
_add_alias gpo "git push origin"
_add_alias gbr "git rev-parse --abbrev-ref HEAD" # Works on 1.7.x & 1.8.x
_add_alias grf "git reflog" # List all commits current branch points to
_add_alias gsh "git show"
_add_alias gshh "git show HEAD"
_add_alias gshhs "git show HEAD --stat"
_add_alias gshhss "git show HEAD --stat --stat-name-width=$(tput cols)" # Ensure filenames don't get chopped off
_add_alias gshhn "git show HEAD --name-only"
_add_alias gshn "git show --name-only"
_add_alias gshs "git show --stat"
_add_alias gv "git remote -v"
_add_alias gr "git reset"
_add_alias grh "git reset HEAD"
_add_alias grhh "git log -n 1 --stat; git reset HEAD~1"
_add_alias grhhs "git log -n 1 --stat; git reset HEAD~1 --soft"
_add_alias grhhh "git log -n 1 --stat; git reset HEAD~1"
_add_alias grb "git rebase"
_add_alias grbc "git rebase --continue"
_add_alias grba "git rebase --abort"
_add_alias gct "git checkout --theirs"
_add_alias g-- "git --version"
_add_alias gtip "git show-branch --sha1-name"
_add_alias gcf "git config"
_add_alias gcfl "git config --list"
_add_alias gcfe "git config user.email"
_add_alias gcfu "git config user.name"
_add_alias findgit "git rev-parse --git-dir"
_add_alias gitdir "git rev-parse --git-dir"
_add_alias toplevel "dirname \$(git rev-parse --git-dir)"
_add_alias findgits "find . -name .git -type d -prune | tee gits.txt" # Once found, don't continue to descend under git dir
_add_alias findtags "find . -name .git -type d -prune | xargs -I % sh -c 'echo -en \"%: \"; git --git-dir=% describe --tags --abbrev=0'"
_add_alias authors "git log --format='%ce' | sort | uniq -c"
_add_alias commits "git rev-list --all --count"
# GREP
_add_alias gre "grep -iInrs --color=always"   # case-insensitive
_add_alias lgre "grep -iIlnrs --color=always" # case-insensitive
_add_alias grel "grep -iIlnrs --color=always" # case-insensitive
_add_alias hgre "grep -hiIrs --color=always"  # case-insensitive
_add_alias gree "grep -HInrs --color=always"
# _add_alias greb "grep -Inrs --color=always --exclude-dir=build --exclude-dir=${BLOATED_DIR}"
# _add_alias lgreb "grep -Ilnrs --color=always --exclude-dir=build --exclude-dir=${BLOATED_DIR}"
_add_alias lgree "grep -Ilnrs --color=always"
_add_alias greel "grep -Ilnrs --color=always"
_add_alias hgree "grep -hIrs --color=always"
# HISTORY
_add_alias h "history"
_add_alias hist "history | grep -P --color=always \"^.*?]\" | \less -iFRX +G"
_add_alias hisd "history -d"
_add_variable HISTCONTROL "erasedups"
_add_alias freq "cut -f1 -d" " "$HISTFILE" | sort | uniq -c | sort -nr | head -n 30"
# Give history timestamps
_add_variable HISTTIMEFORMAT "[%F %T] "
# Johannes Gutenberg's Bible
_add_variable HISTSIZE 500000
_add_variable HISTFILESIZE 500000
 # Easily re-execute the last history command
_add_alias r "fc -s"
# Networking
_add_alias getip "nslookup"
# LESS
_add_alias les "less +G" # +G goes to end of file
_add_alias le "less -iS" # Truncate lines, case-insensitive search
# Node.js
_add_alias n "node"
# _add_alias nd "node server" # Needed for next_dir()
# Pip
_add_alias de "deactivate"
_add_alias pi "pip install"
_add_alias vv "virtualenv"
# PS
_add_alias psa "ps aux"
_add_alias p "ps aux | grep -v grep | grep \$(echo \$USER)"
_add_alias psm "ps aux | grep mongo | grep -v grep"
_add_alias psd "ps aux | grep mongod | grep -v grep"
_add_alias psp "ps -f -C mongod"
_add_alias pspf "ps --cols 20000 -f -C mongod"
_add_alias kmd "ps -f -C mongod | tr -s ' ' | cut -d' ' -f2 | tail -n +2 | xargs -I% kill %"
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
_add_alias pyk "pkill -9 python"
# TAR
_add_alias tarv "tar tvf"  # View an archive
_add_alias tarc "tar caf"  # Compress an archive
_add_alias untar "tar xvf" # Uncompress an archive, gzip -d
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

## 4d) Common
#_add_alias ed "\$EDITOR +\$((\$(wc -l ~/.diary | awk '{print \$1}')+1)) ~/.diary" # Programmer's Diary
_add_alias dl "grep --color -o -E \"^# [0-9]{2}/[0-9]{2}/[0-9]{4}\" ~/.diary | tail -n 1 | cut -d' ' -f2-"
_add_alias el "eval \$EDITOR +\$((\$(wc -l ~/.daily | awk '{print \$1}')+1)) ~/.daily" # Daily Journal
_add_alias td "tail ~/.diary"
_add_alias eb "open_file ~/.bashrc"
_add_alias eeb "open_file ${EMACS_INIT_FILE} ~/.bashrc"
_add_alias ebb "open_file ~/.bash_profile"
_add_alias em "open_file ~/.machine"
_add_alias tm "tail ~/.machine"
_add_alias ee "open_file ${EMACS_INIT_FILE}"
_add_alias eg "open_file ~/.gitconfig"
_add_alias es "open_file ~/.ssh/config"
_add_alias vb "vim ~/.bashrc"
_add_alias sb "_clear_environment; source ~/.bashrc;"
_add_alias exts "find . -type f | awk -F'/' '{print \$NF}' | awk -F'.' '{print \$NF}' | sort | uniq -c | sort -h"
_add_alias rb "rm ~/.emacs.d/configuration.el"
# This command should wipe out the previous environment and start over
_add_alias sbb "ps2; _clear_environment; source ~/.bash_profile"
# Clear all custom aliases, useful when they get in the way
_add_alias una "ps2; _clear_environment; alias sbb=\"source ~/.bash_profile\""
_add_alias unaa "unalias -a"
# Prepare Build Environment
_add_alias pb "una; echo -e '${YELLOW}Build Environment Ready${ENDCOLOR}'"


## 5) Prompt String
source_file ~/.git-prompt
_add_variable PS1_prev "$PS1"
case $OSTYPE in
linux*|msys*)
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
    # This is explained in bash(1) under PROMPTING
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
                _add_variable PS1 "${PS_STARTCOLOR}[\D{%m/%d/%y %r}]${ENDCOLOR}[$([[ \$? = 0 ]] && : || echo -e "${RED}")\${?:0:1}${ENDCOLOR}]${PS_STYCOLOR}[\${STY}]${PS_BRANCHCOLOR}\$(__git_ps1) ${PS_STARTCOLOR}\u:\W\$${PS_ENDCOLOR} "
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


## 6) Bash Functions
# Kill Child Processes
kcp() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "<pid>")
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
        return $(_error "" "[length]")
    fi
    local l=$1
    [ "$l" == "" ] && l=16
    LC_CTYPE=C tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
    # LC_TYPE=C is necessary for Mac OSX.
}
_add_function genpasswd
_rename_function genpasswd gen

gen_num() {
    if [[ $# -gt 1 ]]; then
        return $(_error "" "[length]")
    fi
    local l=$1
    [ "$l" == "" ] && l=16
    LC_CTYPE=C tr -dc 0-9 < /dev/urandom | head -c ${l} | xargs
    # LC_TYPE=C is necessary for Mac OSX.
}
_add_function gen_num

gen_hex() {
    if [[ $# -gt 1 ]]; then
        return $(_error "" "[length]")
    fi
    local l=$1
    [ "$l" == "" ] && l=16
    LC_CTYPE=C tr -dc a-f0-9 < /dev/urandom | head -c ${l} | xargs
    # LC_TYPE=C is necessary for Mac OSX.
}
_add_function gen_hex

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
            return $(_error "" "<line_length> <file>")
        fi
    else
        line_length=$1
        file=$2
    fi
    if [[ ! -f $file ]]; then
        return $(_error "$file is not a regular file")
    fi
    grep -nE "^.{$((line_length + 2))}" "$file" | cut -f1 -d: | xargs -I{} sh -c "echo -n "{}:" && sed -n {},{}p $file | grep --color=always -E ^.{$((line_length + 1))}"
}
_add_function longer

# Trailing Whitespace Remover
remove_trailing_spaces() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "<file|dir>")
    fi
    if [[ -d $1 ]]; then
        echo "doing it"
        find $1 | tail -n +2 | while read f; do sed -i 's/[ \t]*$//' "$f"; done
        return
    fi
    if [[ -f $1 ]]; then
        sed -i 's/[ \t]*$//' "$1"
        return
    fi
    return $(_error "$1 is not a regular file or directory")
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
        builtin cd "${@:1:$n-1}" "$(sed -e$e -e$e -e$e <<< "${!n}")";
    fi
}
_add_function cd

# Git Hook Checker
hooks() {
    if [[ $(git rev-parse --is-bare-repository 2>/dev/null) == "false" ]]; then
        if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == "true" ]]; then
            local gitdir=$(git rev-parse --git-dir)
            realpath "${gitdir}/hooks/"
            ls -lh "${gitdir}/hooks/"
        else
            return $(_error "not inside working tree.")
        fi
    else
        return $(_error "cannot be in a bare repository.")
    fi
}
_add_function hooks

_add_variable HOOK_SRC "\$(git config --get init.templatedir)"
if [[ -n "${HOOK_SRC}" ]]; then
    _add_alias hook "cp -rp \${HOOK_SRC}/hooks \$(findgit)/hooks"
fi

safely_call() {
    local temp_dir="${HOME}/tmp"
    if [[ ! -d $temp_dir ]]; then
        return $(_error "${temp_dir} doesn't exist")
    fi
    $@
}
_add_function safely_call

create_temp_src_file() {
    local _ext _temp_dir _tmpfile
    _ext=$1
    _temp_dir="${HOME}/tmp"
    if [[ ! -f ${_temp_dir}/template.${_ext} ]]; then
        return $(_error "template doesn't exist for ${_ext}")
    fi
    _tmpfile="$(mktemp ${_temp_dir}/XXXXXXXXXX.${_ext})" || return 1;
    # These sed's are designed to be cross-platform
    sed -e "s/^# Created:$/& $(date)\n\# Dir:     ${PWD//\//\\/}/" "${temp_dir}/template.${_ext}" \
        | sed -e "s/^# Author:$/&  $USER/" > "${_tmpfile}"
    eval ${EDITOR} +$(($(wc -l "${_temp_dir}/template.${_ext}" | awk '{print $1}')+2)) "${_tmpfile}"
}
_add_function create_temp_src_file

# Rapid Code Prototyping
# TODO: IMPLEMENT BASH AND PYTHON
# Usage: $ tmp [py|sh] # creates temp source file in language given
#        $ rmp [py|sh] # removes all temp source files for language
tmp() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "<script_template_extension>")
    fi
    safely_call create_temp_src_file "${1}"
}
_add_function tmp

remove_all_empty_temp_files() {
    local ext temp_dir dry_run
    ext=$1
    dry_run=$2
    temp_dir="${HOME}/tmp"
    if [[ ! -f ${HOME}/tmp/template.${ext} ]]; then
        return $(_error "template doesn't exist for ${ext}")
    fi
    for _file in $(\find "${temp_dir}" -name "*${ext}" -not -name "template*"); do
        if [[ ( "x$(\diff "${temp_dir}/template.${ext}" "${_file}")" = "x" ) ||
                  ( ! -s "${_file}" ) ]]; then
            if [[ ("x$dry_run" = "x") ]]; then
                set -x
                rm $_file
                { set +x; } &>/dev/null
            else
                echo "rm $_file"
            fi
        else
            echo "$_file is unique"
        fi
    done
}
_add_function remove_all_empty_temp_files

rmp() {
    local dry_run arg
    if [[ $1 = "-n" ]]; then
        dry_run="n"
        arg=$2
    else
        arg=$1
    fi
    safely_call remove_all_empty_temp_files "${arg}" "${dry_run}"
}
_add_function rmp

# Usage: g [DRY_RUN]
# Will let user select if more than 1 remote
# Any arguments coming after g implies dry run
g() {
    local _remote=$(git remote)
    local _num_remotes=$(git remote | wc -l)
    local _branch=$(git rev-parse --abbrev-ref HEAD)
    local _r

    if [[ "dryrun" = ${1} ]]; then
        echo -e "[${PURPLE}dry run${ENDCOLOR}]"
    elif [[ $# -gt 0 ]]; then
        return $(_error "too many arguments." "[dryrun]")
    fi

    if [[ ${_num_remotes} -eq 1 ]]; then
        echo -e "alias [${PURPLE}g${ENDCOLOR}] to [${PURPLE}git pull ${_remote} ${_branch}${ENDCOLOR}]"
        if [[ $# -eq 0 ]]; then
            git pull ${_remote} ${_branch}
        fi
    elif [[ ${_num_remotes} -gt 1 ]]; then
        select _r in ${_remote[@]}
        do
            echo -e "alias [${PURPLE}g${ENDCOLOR}] to [${PURPLE}git pull ${_r} ${_branch}${ENDCOLOR}]"
            if [[ $# -eq 0 ]]; then
                git pull ${_r} ${_branch}
            fi
            break
        done
    fi
}
_add_function g

# Git Push to all remotes
gpa() {
    if [[ "dryrun" = ${1} ]]; then
        echo -e "[${PURPLE}dry run${ENDCOLOR}]"
    fi
    if [[ "function" = $(type -t __git_remotes) ]]; then
        local cur_branch=$(git rev-parse --abbrev-ref HEAD)
        for _ith_remote in $(__git_remotes); do
            if [[ "dryrun" = ${1} ]]; then
                echo "git push ${2} ${_ith_remote} ${cur_branch}"
            elif [[ $# -eq 1 ]]; then
                set -x
                git push "${1}" "${_ith_remote}" "${cur_branch}"
                { set +x; } 2>/dev/null
            else
                set -x
                git push "${_ith_remote}" "${cur_branch}"
                { set +x; } 2>/dev/null
            fi
        done
    else
        return $(_error <<ERROR_MSG
You need to have the well-known ~/.git-completion file.
It is located at:
  https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
ERROR_MSG
            )
    fi
}
_add_function gpa

gpas() {
    gpa dryrun "${@}"
}
_add_function gpas

gpfa() {
    gpa -f
}
_add_function gpfa

create_shortcut() {
    if [[ $# -ne "1" ]]; then
        return $(_error "" "<new_alias>")
    fi

    is_alias=$(type -t "$1")
    if [[ "${is_alias}" = "alias" ]]; then
        return $(_error "$1 is already an alias.")
    fi
    echo "_add_alias __$(hostname)__ $1 \"cd ${PWD// /\\ }\" #generated by alias 'short'" >> ~/.machine
    source_file ~/.machine
    echo "_add_alias $1 \"cd ${PWD// /\\ }\" #generated by alias 'short'"
}
_add_function create_shortcut
_rename_function create_shortcut short

body() {
    if [[ $# -ne 3 ]]; then
        return $(_error "" "<start> <finish> <file>")
    elif [[ $3 != "-" && ! -f $3 ]]; then
        return $(_error "$3 is not a regular file.")
    fi
    if [[ $3 = "-" ]]; then
        sed -n "${1},${2}p"
    else
        sed -n "${1},${2}p" "${3}"
    fi
}
_add_function body

bodyn() {
    if [[ $# -ne 3 ]]; then
        return $(_error "" "<start> <finish> <file>")
    elif [[ $3 != "-" && ! -f $3 ]]; then
        return $(_error "$3 is not a regular file.")
    fi
    if [[ $3 = "-" ]]; then
        sed -n "${1},${2}p" | nl -v ${1}
    else
        sed -n "${1},${2}p" "${3}" | nl -v ${1}
    fi
}
_add_function bodyn

line() {
    if [[ $# -ne 2 ]]; then
        return $(_error "" "<line_number_to_echo> <file>")
    elif [[ ! -f $2 ]]; then
        return $(_error "$2 is not a regular file.")
    fi
    sed -n "${1},${1}p" "${2}"
}
_add_function line

case $OSTYPE in
linux*|msys*)
    tabs() {
        if [[ $# -ne 1 ]]; then
            return $(_error "" "<file>")
        elif [[ ! -f $1 ]]; then
            return $(_error "$1 is not a regular file.")
        fi
        diff --changed-group-format='%<' --unchanged-group-format='' <(expand -i --tabs=4 "${1}") "${1}"
    }
    _add_function tabs

    numtabs() {
        if [[ $# -ne 1 ]]; then
            return $(_error "" "<file>")
        elif [[ ! -f $1 ]]; then
            return $(_error "$1 is not a regular file.")
        fi
        diff --changed-group-format='%<' --unchanged-group-format='' <(expand -i --tabs=4 "${1}") "${1}" | wc -l
    }
    _add_function numtabs

    untabify() {
        if [[ $# -eq 1 ]]; then
            return $(_error "<file>")
        fi
        echo "There are [$(numtabs ${1})] tabs in [${1}]"
        echo "Tabs -> 4 spaces in [${1}]..."
        local tmpfilename="${1}.expanded4.$(date $DATE_FORMAT)"
        tab "${1}" > "${tmpfilename}"
        \mv -i "${tmpfilename}" "${1}"
    }
    _add_function untabify
;;
esac

search_file() {
    echo -en "searching for [${CYAN}${2}${ENDCOLOR}]"
    if [[ $# -gt 3 ]]; then
        _search_term="($2"
        for i in ${@:3:$(($#-3))}; do
            echo -en " and [${CYAN}${i}${ENDCOLOR}]"
            _search_term="${_search_term}|${i}"
        done
        _search_term="${_search_term})"
    else
        _search_term=$2
    fi
    echo -e " in [${CYAN}${@: -1}${ENDCOLOR}]" >&2
    \grep --color=always -inE "${_search_term}" "${@: -1}";
}
_add_function search_file

# 1: Number of args to calling script
# 2: First arg to calling script (search term)
# 3: File to search
_search_file_wrapper() {
    if [[ $1 -lt 1 ]]; then
        return $(_error "" "<search_term>")
    elif [[ ! -f "${@: -1}" ]]; then
        return $(_error "${@: -1} is not a regular file")
    fi
    search_file "${@}"
}
_add_function _search_file_wrapper

se() { _search_file_wrapper $# "${@}" ~/.bashrc; }
_add_function se

sd() { _search_file_wrapper $# "${@}" ~/.diary; }
_add_function sd

sm() { _search_file_wrapper $# "${@}" ~/.machine; }
_add_function sm

seb() { _search_file_wrapper $# "${@}" ${EMACS_INIT_FILE}; }
_add_function seb

# 1: Number of args to calling script
# 2: First arg to calling script (search term)
# 3: File to search
_search_file_occur_wrapper() {
    echo -e "occurences of [${CYAN}${2}${ENDCOLOR}] in [${CYAN}${3}${ENDCOLOR}]:" >&2
    if [[ $1 -ne 1 ]]; then
        return $(_error "" "<search_term>")
    elif [[ ! (-f "$3" || -L "$3") ]]; then
        return $(_error "$3 is not a regular file")
    fi
    search_file "$2" "$3" | wc -l
}
_add_function _search_file_occur_wrapper

sel() { _search_file_occur_wrapper $# "$1" ~/.bashrc; }
_add_function sel

sdl() { _search_file_occur_wrapper $# "$1" ~/.diary; }
_add_function sdl

sebl() { _search_file_occur_wrapper $# "$1" ${EMACS_INIT_FILE}; }
_add_function sebl

# Tell if something is a new alias
al() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "<alias>")
    fi
    local is_defined="$(type -t $1)"
    if [[ -n "${is_defined}" ]]; then
        echo "Yes"
    else
        echo "No"
    fi
}
_add_function al

# Generate a TAGS file for emacs
gentags() {
    if [[ 'c' = "$1" ]]; then
        command time -v find . -iname "*.[ch]" -o -iname "*.cc" 2>/dev/null | xargs etags -a 2>/dev/null &
    else
        command time -v find . -iname "*.[ch]" -o -iname "*.cc" -o -iname "*.[ch]pp" 2>/dev/null | xargs etags -a 2>/dev/null &
    fi
}
_add_function gentags

# Similar to mkd() but for git-clone(1)
gcl() {
    if [[ $# -lt 1 ]]; then
        return $(_error "" "<url>")
    fi
    # echo "\$#: [$#] \$@: [$@] \${!#%.git}: ${!#%.git} basename: $(basename -- ${!#%.git})"
    git clone "$@"
    if [[ $# -gt 1 ]]; then
        cd "$(basename -- ${!#%.git})"
    else
        cd "$(basename -- ${1%.git})"
    fi
}
_add_function gcl

# Similar to mkd() but for unzip(1)
unz() {
    if [[ $# -lt 1 ]]; then
        return $(_error "" "<url>")
    fi
    unzip "$1" -d "${1%.zip}"
    cd "$(basename -- ${1%.zip})"
}
_add_function unz

bk() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "<path>")
    fi
    set -x
    \cp -ipr "${1%/}" "${1%/}.bk"
    { set +x; } 2>/dev/null
}
_add_function bk

rtrav() {
    # TODO: _file should be allowed to have wildcards (e.g. $ rtrav images*)
    local _file="${1}"
    local _dir="${2}"
    if [[ $# -eq 1 ]]; then
        _dir=$(readlink -f .)
        test -e "${_dir}"/"${_file}" && echo "${_dir}" || { test "${_dir}" != / && rtrav "${_file}" "$(dirname ${_dir})";};
    elif [[ $# -eq 2 ]]; then
        test -e "${_dir}"/"${_file}" && echo "${_dir}" || { test "${_dir}" != / && rtrav "${_file}" "$(dirname ${_dir})";};
    else
        return $(_error "" "<name> [path]")
    fi
}
_add_function rtrav

wow() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "<command>")
    fi
    \ls  "$(which "$1")"
}
_add_function wow

wowz() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "<command>")
    fi
    ls -alh "$(which "$1")"
}
_add_function wowz

_git_branch_delete() {
    local _branch="${1}"
    local _remote_url=$(git remote get-url origin)
    if [[ $# -ne 1 ]]; then
        return $(_error "only one argument allowed" "<branch>")
    fi
    git rev-parse --verify --quiet "${_branch}" >/dev/null
    if [[ $? -ne 0 ]]; then
        return $(_error "branch ${_branch} doesn't exist")
    fi
    echo -ne "Are you sure you want to delete branch [${CYAN}${_branch}${ENDCOLOR}] from [${YELLOW}local${ENDCOLOR}]? "
    read -p "[y/n]: " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -en "\nDeleting branch [${GREEN}${_branch}${ENDCOLOR}] from [${YELLOW}local${ENDCOLOR}]..."
        echo
        set -x
        git branch -d "${_branch}" || git branch -D "${_branch}"
        { set +x; } 2>/dev/null
        echo " Done!"

        echo -ne "Are you sure you want to delete branch [${CYAN}${_branch}${ENDCOLOR}] from [${YELLOW}remote${ENDCOLOR}]? "
        read -p "[y/n]: " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -en "\nDeleting branch [${GREEN}${_branch}${ENDCOLOR}] from [${YELLOW}remote${ENDCOLOR}]..."
            git ls-remote --quiet --exit-code --heads ${_remote_url} ${_branch} >/dev/null
            if [[ $? -eq 0 ]]; then
                set -x
                git push origin ":${_branch}"
                { set +x; } 2>/dev/null
                echo " Done!"
            else
                echo -e "\nBranch didn't exist on remote [${PURPLE}${_remote_url}${ENDCOLOR}]"
            fi
        else
            echo " Exiting."
        fi
    else
        echo " Exiting."
    fi

}
_add_function _git_branch_delete
_rename_function _git_branch_delete gbd

_git_pull_rebase() {
    local _cur_branch=$(git rev-parse --abbrev-ref HEAD)
    local _remote_name="origin"
    local _branch_name="master"
    if [[ $# -gt 1 ]]; then
        return $(_error "only zero or one arguments allowed" "<remote_name>")
    elif [[ $# -eq 1 ]]; then
        _branch_name="${_cur_branch}"
    fi

    if ! git rev-parse --verify --quiet "${_branch_name}" >/dev/null; then
        return $(_error "branch [${_branch_name}] doesn't exist")
    fi

    if ! git ls-remote --exit-code --quiet "${_remote_name}" "${_branch_name}" >/dev/null 2>&1; then
        return $(_error "branch [${_branch_name}] doesn't exist on remote [${_remote_name}]")
    fi

    set -x
    git fetch "${_remote_name}"
    git pull --rebase "${_remote_name}" "${_branch_name}"
    { set +x; } 2>/dev/null
}
_add_function _git_pull_rebase
_rename_function _git_pull_rebase gpr

_git_blame_file() {
    local _line_num="${1}"
    local _file="${2}"
    if [[ $# -ne 2 ]]; then
        return $(_error "requires 2 arguments" "<line_num> <file>")
    fi
    set -x
    git blame -L${_line_num},+10 -- ${_file}
    { set +x; } 2>/dev/null
}
_add_function _git_blame_file
_rename_function _git_blame_file gbf

_git_cherrypick_file() {
    local _cur_branch=$(git rev-parse --abbrev-ref HEAD)
    local _branch="${1}"
    local _file="${2}"
    if [[ $# -ne 2 ]]; then
        return $(_error "only zero or one arguments allowed" "<branch_name> <file_path>")
    fi

    if ! git rev-parse --verify --quiet "${_branch}" >/dev/null; then
        return $(_error "branch ${_branch} doesn't exist")
    fi

    if [[ ! -f "${_file}" ]]; then
        return $(_error "file ${_file} doesn't exist")
    fi

    set -x
    git diff ${_cur_branch}^..${_branch} -- ${_file} | git apply
    { set +x; } 2>/dev/null
}
_add_function _git_cherrypick_file
_rename_function _git_cherrypick_file gcpf

_git_log_unpushed_commits() {
    local _cur_branch=$(git rev-parse --abbrev-ref HEAD)
    local _remote_name="${1:-origin}"
    if [[ $# -gt 1 ]]; then
        return $(_error "only zero or one arguments allowed" "<remote_name>")
    fi

    if ! git rev-parse --verify --quiet "${_cur_branch}" >/dev/null; then
        return $(_error "branch ${_cur_branch} doesn't exist")
    fi

    if ! git ls-remote --exit-code --quiet "${_remote_name}" "${_cur_branch}" >/dev/null 2>&1; then
        return $(_error "branch [${_cur_branch}] doesn't exist on remote [${_remote_name}]")
    fi

    set -x
    eval git log ${_remote_name}/${_cur_branch}..HEAD
    { set +x; } 2>/dev/null
}
_add_function _git_log_unpushed_commits
_rename_function _git_log_unpushed_commits unpushed
_rename_function _git_log_unpushed_commits unp

_git_log_ff() {
    local _first_branch="${1}"
    local _second_branch="${2}"
    if [[ $# -gt 2 || $# -lt 1 ]]; then
        return $(_error "incorrect number of arguments provided" "<branch1> <branch2>")
    fi
    if ! git rev-parse --verify --quiet "${_first_branch}" >/dev/null; then
        return $(_error "${_first_branch} doesn't exist")
    fi
    if [[ $# -eq 1 ]]; then
        #git rev-parse --abbrev-ref HEAD
        _second_branch=$(git rev-parse --abbrev-ref HEAD)
    fi
    git rev-parse --verify --quiet "${_second_branch}" >/dev/null
    if [[ $? -ne 0 ]]; then
        return $(_error "branch ${_second_branch} doesn't exist")
    fi
    set -x
    # git merge-base --is-ancestor ${_second_branch} ${_first_branch}
    # git merge-base --is-ancestor ${_first_branch} ${_second_branch}
    git merge-base ${_first_branch} ${_second_branch}
    { set +x; } 2>/dev/null
    merge_base_sha=$(git merge-base ${_first_branch} ${_second_branch})
    if [[ $? -eq 0 ]]; then
        echo
        git show $merge_base_sha
    fi
}
_add_function _git_log_ff
_rename_function _git_log_ff ff

num_files() {
    for i in ./*; do
        if [[ -d $i ]]; then
            echo -en "$i: \t"
            find $i -type f | wc -l;
        fi
    done
}
_add_function num_files
#_rename_function num_files nf

# Run args as a command in all dirs in cur dir
all() {
    long_opts="exclude:","help"
    if ! getopts=$(getopt -o e:h -l $long_opts -- "$@"); then
        echo "Error parsing arguments!"
        usage
    fi
    eval set -- "$getopts"
    while true; do
        case "$1" in
            -e|--exclude) exclude=$2 ; shift;;
            -h|--help) echo "Help"; return;;
            --) shift ; break ;;
            *) echo "Error processing args -- unrecognized option $1" >&2
               usage;;
        esac
        shift
    done
    echo "e: ${exclude}"
    for i in ./*; do
        if [[ "${i}" != "./${exclude}" ]]; then
            echo -e "${BROWN}[[${i}: ${@}]]${ENDCOLOR}"
            cd "${i}"
            set -x
            eval "${@}"
            { set +x; } &> /dev/null
            cd -
        fi
    done
}
_add_function all

vers() {
    "${@}" --version
}
_add_function vers

header_locations() {
    local _header=$1
    grep --color=never -Inrs "^#include" $_header                              \
        | cut -d' ' -f2                                                        \
        | tr -d "\""                                                           \
        | while read f; do                                                     \
            echo "--$f--";                                                     \
            find . -name $f;                                                   \
            printf "%0.s-" {1..80} && echo;                                    \
          done
}
_add_function header_locations
_rename_function header_locations hl

_git_rebase_theirs() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "<mainline_branch>")
    fi
    mainline_branch=${1}

    echo -ne "${PURPLE}" && set -x
    git rebase $mainline_branch
    local rebase_ret=$?
    { set +x; } &> /dev/null

    local num_rebase_commit_conflicts=0
    local num_rebase_file_conflicts=0
    IFS=''
    while [[ ${rebase_ret} -ne 0 ]]; do
        git status --porcelain -uno | while read l; do
            echo -ne "${ENDCOLOR}"
            echo "output: [${l}]"
            git_status_flag=${l:0:2}
            file_path=${l:3}
            full_path=$(git rev-parse --show-toplevel)/${file_path}

            if [[ ${git_status_flag:1:1} != " " ]]; then
                echo -ne "${PURPLE}" && set -x
                git checkout --theirs $full_path
                git add -u $full_path
                { set +x; } &> /dev/null && echo -ne "${ENDCOLOR}"
                num_rebase_file_conflicts=$((num_rebase_file_conflicts+1))
            fi
        done
        num_rebase_commit_conflicts=$((num_rebase_commit_conflicts+1))
        echo -ne "${PURPLE}" && set -x
        git rebase --continue
        rebase_ret=$?
        { set +x; } &> /dev/null && echo -ne "${ENDCOLOR}"
    done
    echo -ne "${ENDCOLOR}"

    echo "--conflicts--"
    echo "commits: [${num_rebase_commit_conflicts}] | files: [${num_rebase_file_conflicts}]"
}
_add_function _git_rebase_theirs
_rename_function _git_rebase_theirs grbt

# branches() {
#     for k in \$(git branch -r | perl -pe 's/^..(.*?)( ->.*)?\$/\1/'); do
#         echo -e \$(git show --pretty=format:\"%Cgreen%ci %Cblue%cr%Creset \" \$k -- | head -n 1)\\\t\$k;
#     done | sort -r
# }


# (W)hat (H)ave (I) (D)one?
# You know how you can't remember what you worked on recently?
#  This shortcut presents you with all git objects you have modified
#  in the past week to help you pick up where you left off and not
#  lose work.
whid() {
    # Branches
    echo -e "${PURPLE}# Branches${ENDCOLOR}"
    # for k in $(git branch -r | perl -pe 's/^..(.*?)( ->.*)?\$/\1/'); do
    #     echo -e $(git show --pretty=format:\"%Cgreen%ci %Cblue%cr%Creset \" \$k -- | head -n 1)\\\t\$k;
    # done | sort -r | grep days | rev | awk '{print $1}' | rev | while read f; do echo " $f"; done
    for k in $(git branch | perl -pe 's/^..(.*?)( ->.*)?$/\1/'); do echo -e $(git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset " $k -- | head -n 1)\\\t$k; done | sort -r | head
    #branches | sort -r | grep days | rev | awk '{print $1}' | rev | while read f; do echo " $f"; done
    # Stashes
    # set -x
    _num_stashes=$(git stash list | wc -l | while read l; do echo "$l - 1"; done | bc)
    # echo "${_num_stashes}"
    echo -e "${PURPLE}# Stashes${ENDCOLOR}"
    for i in $(seq 0 ${_num_stashes}); do echo -en "${CYAN}stash@{${i}}:${GREEN}" && git show --format="%ad%Creset %s" stash@{$i} | head -n 1; done
    # set +x
}
_add_function whid

# TODO
git_checkout_previous_branch() {
    local _previous_branch;
    local _previous_branches=$(for k in $(git branch | perl -pe 's/^..(.*?)( ->.*)?$/\1/'); do echo -e $(git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset " $k -- | head -n 1)\\\t$k; done | sort -r | head | cut -d' ' -f7- | awk -F' ' '{print $1}' | head -n 3 | tail -n 2)
    echo "0: ${_previous_branches[0]}"
    echo "1: ${_previous_branches[1]}"
}
_add_function git_checkout_previous_branch
_rename_function git_checkout_previous_branch gcpb

jira-cli-open() {
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<JIRA-ID>")
    fi
    local _jira_id=$1
    local _jira_tag
    echo "[$1]"
    $(echo "$1" | grep -E "^[a-zA-Z]{1,8}-[0-9]{1,6}$" &>/dev/null)
    if [[ $? -eq 0 ]]; then
        _jira_tag=$1
    else
        _jira_tag="SERVER-${_jira_id}"
    fi
    set -x
    jira open ${_jira_tag}
    { set +x; } &>/dev/null
}
_add_function jira-cli-open
_rename_function jira-cli-open jo

jira-cli-view() {
    if [[ $# -lt 1 ]]; then
        return $(_error "requires at least 1 argument" "<JIRA-ID>")
    fi
    local _jira_id=${@: -1}
    local _options=${@:1:-1}
    local _jira_tag
    echo "[$1]"
    $(echo "$1" | grep -E "^[a-zA-Z]{1,8}-[0-9]{1,6}$" &>/dev/null)
    if [[ $? -eq 0 ]]; then
        _jira_tag=$1
    else
        _jira_tag="SERVER-${_jira_id}"
    fi
    set -x
    jira issue view --plain --comments 5 ${_jira_tag}
    { set +x; } &>/dev/null
}
_add_function jira-cli-view
_rename_function jira-cli-view jv

scka() {
    : Documentation: GNU SCREEN KILL ALL SESSIONS
    local _screen_sessions=$(screen -ls | grep "\t" | tr -d '\t' | cut -d'(' -f1)
    echo "doing something"
    for session in ${_screen_sessions[@]}; do
        set -x
        screen -S $session -X quit
        { set +x; } &>/dev/null
    done
}
_add_function scka

sck() {
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<SCREEN_SESSION>")
    fi
    set -x
    screen -X quit -S $1
    { set +x; } &>/dev/null
}
_add_function sck

color() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "[search_words...]")
    fi
    grep --color "^\|${@}"
}
_add_function color

# Programmer's Diary
# Works! Now try to send the new date into the emacs buffer unsaved
#  This way, one can leave the file if just searching
ed() {
    local _cur_date _most_recent_date
    _cur_date=$(date +%m/%d/%Y)
    _most_recent_date=$(grep --color -o -E "^# [0-9]{2}/[0-9]{2}/[0-9]{4}" ~/.diary | tail -n 1 | cut -d' ' -f2-)
    if [[ "${_cur_date}" != "${_most_recent_date}" ]]; then
        if [[ -n "$(tail -c 1 ~/.diary)" ]]; then
            echo >> ~/.diary
        fi
        echo -e "\n#\n# ${_cur_date}\n#" >> ~/.diary
        echo "Command                                      Comments" >> ~/.diary
        printf "%0.s-" {1..90}  >> ~/.diary
        echo >> ~/.diary
    fi
    eval $EDITOR +$(($(wc -l ~/.diary | awk '{print $1}')+1)) ~/.diary
}
_add_function ed

# Given a path, find the greatest common ancestor of the
#  CWD, current working directory, and the given path
gcar() {
    local _path1 _path2
    _path1=${1}
    _path2=${PWD}
    echo "PATH1: [${_path1}]"
    if [[ ! -z ${2} ]]; then
        _path2=${2}
        echo "PATH2: [${_path2}]"
    else
        echo " PWD: [${_path2}]"
    fi
    greatest_common_ancestor=$(sed -e 's,$,/,;1{h;d;}' -e 'G;s,\(.*/\).*\n\1.*,\1,;h;$!d;s,/$,,' \
                               <(echo "${_path1}") \
                               <(echo "${_path2}"))
    printf "%0.s-" {1..80} && echo
    echo " GCA: [${greatest_common_ancestor}]"
    # https://unix.stackexchange.com
    #  /questions
    #  /67078
    #  /decomposition-of-path-specs-into-longest-common-prefix-suffix
    #  /67121
    #  #67121
}
_add_function gcar

remove_starting_point() {
    local _path1 _path2
    _path1=${1}
    _path2=${PWD}
    echo "PATH1: [${_path1}]"
    if [[ ! -z ${2} ]]; then
        _path2=${2}
        echo "PATH2: [${_path2}]"
    else
        echo " PWD: [${_path2}]"
    fi
    greatest_common_ancestor=$(sed -e 's,$,/,;1{h;d;}' -e 'G;s,\(.*/\).*\n\1.*,\1,;h;$!d;s,/$,,' \
                               <(echo "${_path1}") \
                               <(echo "${_path2}"))
    printf "%0.s-" {1..80} && echo
    echo "${without_starting_point}"
}
_add_function remove_starting_point

# More traceable pkg mgmt
agi() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "<package>")
    fi
    _prog=$1
    mkdir -p ~/.${HOSTNAME}.d
    echo "$(date) [${_prog}]" >> ~/.${HOSTNAME}.d/apt_get_packages
    set -x
    sudo apt-get install -y ${_prog} |& tee -a ~/.${HOSTNAME}.d/apt_get_packages
    { set +x; } &>/dev/null
}
_add_function agi

opt() {
    if [[ $# -ne 2 ]]; then
        return $(_error "" "<cmd> <opt>")
    fi
    man -P cat "${1}" | ul | grep "\-${2}[ ,]"
}
_add_function opt

# Find
findn() {
    local _ext="py"
    if [[ $# -eq 1 ]]; then
        _ext=$1
    elif [[ $3 -gt 1 ]]; then
        return $(_error "" "<extension>")
    fi
    for f in $(ls .); do
        echo "$f";
        find $f -type f | sed -e '/.*\/[^\/]*\.[^\/]*$/!s/.*/(none)/' -e 's/.*\.//' \
            | LC_COLLATE=C sort \
            | uniq -c \
            | grep $_ext;
    done
}
_add_function findn

# Most Recent N modified files
mrf() {
    local _n=${1:-3}
    case $OSTYPE in
    linux*|msys*)
        find . -type f -exec stat -c '%Y %n' {} \; | sort -nr | awk -v var="${_n}" 'NR==1,NR==var {print $0}' | while read t f; do d=$(date -d @$t "+%b %d %T %Y"); echo "$d -- $f"; done
    ;;
    darwin*)
        find . -type f -exec stat -f '%Dm %N' {} \; | sort -nr | awk -v var="${_n}" 'NR==1,NR==var {print $0}' | xargs -I{} stat -f '%Sm %N' {}
    ;;
    esac
}
_add_function mrf

#
# Cpp Greps
#
# TODO: retry searches with case-insensitive searches if no match found
cpptype () {
    local _search_term=$1
    local _opt=$2
    local _dir=${3:-src/mongo}
    local _grep_colors="ms=:mc=:sl=:cx=:fn=35:ln=32:bn=32:se=36" # Turn off the red for matches, but leave the file and line number coloring on
    if [[ ! -d ${_dir} ]]; then
        return $(_error "directory [${_dir}] doesn't exist. Run from within a src tree.")
    fi
    echo -e "Searching for C++ type [${CYAN}${_search_term}${ENDCOLOR}] in [${GREEN}${_dir}${ENDCOLOR}]"
    GREP_COLORS="${_grep_colors}" grep -Inrs --color=always ${_opt} \
	       "^[[:space:]]*\(namespace\|typedef\|class\|enum\|struct\|enum class\)[[:space:]]\+\([][0-9a-zA-Z()_]\+[[:space:]]\+\)\?${_search_term}\([[:space:]]\+{\|[[:space:]]*$\|[[:space:]]\+\([a-z]\+[[:space:]]\+\)\:\)" ${_dir} \
	    | grep --color=always ${_opt} "${_search_term}"
    if [[ $? -ne 0 ]]; then
        # Try "using" statements
        GREP_COLORS="${_grep_colors}" grep -Inrs --color=always ${_opt} \
	               "^[[:space:]]*\(using\)[[:space:]]\+\([0-9a-zA-Z()_]\+[[:space:]]\+\)\?${_search_term}[[:space:]]*=" ${_dir} \
	        | grep --color=always ${_opt} "${_search_term}"
        if [[ $? -ne 0 ]]; then
            if [[ "${_dir}" != "build" ]]; then
                cpptype "${_search_term}" "${_opt}" "build/${NBD}"
                cppdef "${_search_term}" "${_opt}"
            fi
        fi
    fi
}
_add_function cpptype

cppdef () {
    local _opt=$2
    local _search_term=$1
    local _dir=${3:-src/mongo}
    local _grep_colors="ms=:mc=:sl=:cx=:fn=35:ln=32:bn=32:se=36" # Turn off the red for matches, but leave the file and line number coloring on
    if [[ ! -d ${_dir} ]]; then
        return $(_error "directory [${_dir}] doesn't exist. Run from within a src tree.")
    fi
    echo -e "Searching for C++ #define [${CYAN}${_search_term}${ENDCOLOR}] in [${GREEN}${_dir}${ENDCOLOR}]"
    GREP_COLORS="${_grep_colors}" grep -Inrs --color=always ${_opt} \
	       "^[[:space:]]*\(#define\)[[:space:]]*${_search_term}\([[:space:]]*(\|[[:space:]]*$\)" ${_dir} \
	| grep --color=always ${_opt} "${_search_term}"
    if [[ $? -ne 0 ]]; then
        if [[ "${_dir}" != "build" ]]; then
            cppdef "${_search_term}" "${_opt}" "build/${NBD}"
        fi
    fi
}
_add_function cppdef

cpptypectx () {
    local _search_term=$1
    cpptype "${_search_term}" "-A 8"
}
_add_function cpptypectx

enterMacPassword() {
  sleep 1
  osascript -e "tell application \"System Events\" to keystroke tab"
  osascript -e "tell application \"System Events\" to keystroke \"${1}\""
  osascript -e "tell application \"System Events\" to keystroke return"
}
_add_function enterMacPassword

gitdiffhead() {
    : <<DOCSTRING
Diffs N commits against head.
DOCSTRING
    local _num_commits=$1
    local _args=${@:2}
    local _file
    local _git_args
    local _is_file_delim_found=0
    local _pretty_print_file
    local _pretty_print_git_args
    if [[ $# -eq 0 ]]; then
        return $(_error "" "<number_of_commits>")
    elif [[ ! "${_num_commits}" -gt 0 ]]; then
        return $(_error "num commits must be greater than 0")
    fi
    for i in ${_args}; do
        if [ "${i}" == "--" ] || [ ${_is_file_delim_found} -eq 1 ]; then
            _is_file_delim_found=1
            _file+=($i)
        else
            _git_args+=(${i})
        fi
    done
    if [[ "${#_git_args[@]}" -gt 0 ]]; then
        _pretty_print_git_args=" [${PURPLE}${_git_args[*]}${ENDCOLOR}]"
    fi
    if [[ "${#_file[@]}" -gt 0 ]]; then
        _pretty_print_file="[${PURPLE}${_file[*]}${ENDCOLOR}]"
    fi
    echo -e "git diff${_pretty_print_git_args} HEAD~${PURPLE}${_num_commits}${ENDCOLOR}..HEAD ${_pretty_print_file}"
    eval git diff ${_git_args[*]} HEAD~${_num_commits}..HEAD ${_file[*]}
}
_add_function gitdiffhead
_rename_function gitdiffhead gdh

grbi() {
    if [[ $# -ne 1 ]]; then
        return $(_error "" "<number_of_commits>")
    fi
    local _num_commits=$1
    set -x
    eval git rebase -i HEAD~${_num_commits}
    { set +x; } &>/dev/null
}
_add_function grbi

totsv() {
    if [[ -r "${1}" ]]; then
        #echo "${1%.csv}.tsv"
        set -x
        sed -E 's/("([^"]*)")?,/\2\t/g' "${1}" > "${1%.csv}.tsv"
        { set +x; } &> /dev/null
        echo "  > ${1%.csv}.tsv"
    fi
}
_add_function totsv

# Find Multiple Strings in file
# Returns files that contain all strings
# i.e. a logical AND operator
fms() {
    if [[ $# -ne 2 ]]; then
        return $(_error "requires 2 arguments" "<search_term1> <search_term2> ...")
    fi
    # TODO: Support N args
    grep -Iilrs --color=never "${1}" . | xargs -I{} grep -lIirs "${2}" {}
}
_add_function fms

most_recent_file() {
    # Alternative: \ls -t --color=never | head -n 1
    local _path=${1:-.}
    eval find ${_path} -maxdepth 1 -printf '%T@ %f\n' 2>/dev/null | grep -v ' \.$' | sort -n | tail -n 1 | cut -d' ' -f2-
}
_add_function most_recent_file

most_recent_file_exclude_hidden() {
    local _path=${1:-.}
    eval find ${_path} -maxdepth 1 -printf '%T@ %f\n' 2>/dev/null | grep -v ' \.' | sort -n | tail -n 1
}
_add_function most_recent_file_exclude_hidden

_most_recently_modified_file() {
    local _dirname="${1:-.}"
    local _mrmf;
    local latest_filename=$(\find "${_dirname}" -maxdepth 1 -type f -printf '%T@ %f\n' 2>/dev/null | sort -n 2>/dev/null | cut -d' ' -f2- 2>/dev/null | tail -n 1) #2 2>/dev/null | head -n 1)
    if [[ -n "${latest_filename}" ]]; then
        if [[ "${_dirname}" == */ ]]; then
            _mrmf="${_dirname}${latest_filename}"
        else
            _mrmf="${_dirname}/${latest_filename}"
        fi
    fi
    echo "${_mrmf}"
}
_add_function _most_recently_modified_file
_rename_function _most_recently_modified_file mrmf

_most_recently_modified_text_file() {
    local _dirname="${1:-.}"
    local _mrmtf;
    # local latest_filename=$(find "${_dirname}" -maxdepth 1 -printf '%T@ %f\n' 2>/dev/null | sort -n 2>/dev/null | cut -d' ' -f2- 2>/dev/null | xargs -I% grep -HIFl '' % 2>/dev/null | tail -n 2 2>/dev/null | head -n 1)
    local latest_filename=$(\find "${_dirname}" -maxdepth 1 -type f -printf '%T@ %f\n' 2>/dev/null | sort -n 2>/dev/null | cut -d' ' -f2- 2>/dev/null | grep -v "\.core" | tail -n 1) #2 2>/dev/null | head -n 1)
    if [[ -n "${latest_filename}" ]]; then
        if [[ "${_dirname}" == */ ]]; then
            _mrmtf="${_dirname}${latest_filename}"
        else
            _mrmtf="${_dirname}/${latest_filename}"
        fi
    fi
    echo "${_mrmtf}"
}
_add_function _most_recently_modified_text_file
_rename_function _most_recently_modified_text_file mrmtf

# TODO: For efficiency,
#  Have functions like `cpptype` set an env variable that is first checked here.
#  Falls back to re-running the command.
open_file_from_prior_cmd_in_less() {
    local _output=$(history -p !!)
    local _last_line=""
    case $OSTYPE in
    linux*|msys*)
        if [[ ! -x $(which ansi2txt) ]]; then
            return $(_error "ansi2txt not installed. Run 'apt-get install colorized-logs'")
        fi
        _last_line=$(eval "${_output}" | tail -n 1 | ansi2txt)
    ;;
    darwin*)
        _last_line=$(eval "${_output}" | tail -n 1)
    ;;
    esac

    local _file=$(echo "${_last_line}" | cut -d':' -f1)

    if [[ ! -r "${_file}" ]]; then
        return $(_error "file [${_file}] does not exist.")
    fi

    local _line_num=$(echo "${_last_line}" | cut -d':' -f2)

    if [[ ("${_line_num}" -gt 0) && ("${_line_num}" -lt $(wc -l "${_file}" | cut -d' ' -f1)) ]]; then
        echo -e "opening: [${_file}] @ [${GREEN}${_line_num}${ENDCOLOR}]"
        _line_num_arg="+${_line_num} -N"
    else
        echo "opening: [${_file}]"
    fi

    set -x
    eval less ${_line_num_arg} "${_file}"
    { set +x; } &> /dev/null
}
_add_function open_file_from_prior_cmd_in_less
_rename_function open_file_from_prior_cmd_in_less opf

open_file_from_prior_cmd_in_editor() {
    : args - num_prior = index, 1+, starting from bottom of line to open as file default: 1
    local _num_prior=${1:-1}
    local _output=$(history -p !!)
    local _last_line=""
    case $OSTYPE in
    linux*|msys*)
        if [[ ! -x $(which ansi2txt) ]]; then
            return $(_error "ansi2txt not installed. Run 'apt-get install colorized-logs'")
        fi
        _last_line=$(eval "${_output}" | tail -n ${_num_prior} | head -n 1| ansi2txt)
    ;;
    darwin*)
        _last_line=$(eval "${_output}" | tail -n ${_num_prior} | head -n 1)
    ;;
    esac

    local _file=$(echo "${_last_line}" | cut -d':' -f1)

    if [[ ! -r "${_file}" ]]; then
        # Try to remove git status -s markings
        local _status_removed=$(echo "${_file}" | ansi2txt | tr -s ' ' | cut -d' ' -f2)
        # Unstaged changes have a leading space that needs special handling
        if [[ $_status_removed = "M" || $_status_removed = "A" || $_status_removed = "R" || $_status_removed = "D" || $_status_removed = "C" || $_status_removed = "U" ]]; then
            _status_removed=$(echo "${_file}" | tr -s ' ' | cut -d' ' -f3)
        fi
        _file=$_status_removed
        if [[ ! -r "${_file}" ]]; then
            return $(_error "file [${_file}] does not exist.")
        fi
    fi

    local _unadjusted_line_num=$(echo "${_last_line}" | cut -d':' -f2 -s)
    local _line_num_arg
    if [[ -n $_unadjusted_line_num ]]; then
        # Account for terminal height so line number appears at top of editor
        _line_num=$((_unadjusted_line_num+$(tput lines)-8))

        if [[ ("${_line_num}" -gt 0) && ("${_line_num}" -lt $(wc -l "${_file}" | cut -d' ' -f1)) ]]; then
            echo -e "opening: [${_file}] @ [${GREEN}${_line_num}${ENDCOLOR}]"
            _line_num_arg="+${_line_num}"
        fi
    else
        echo "opening: [${_file}]"
    fi

    set -x
    eval ${EDITOR} ${_line_num_arg} "${_file}"
    { set +x; } &> /dev/null
}
_add_function open_file_from_prior_cmd_in_editor
_rename_function open_file_from_prior_cmd_in_editor opfe

open_file_from_prior_cmd_around() {
    local _output=$(history -p !!)
    local _last_line=""
    case $OSTYPE in
    linux*|msys*)
        if [[ ! -x $(which ansi2txt) ]]; then
            return $(_error "ansi2txt not installed. Run 'apt-get install colorized-logs'")
        fi
        _last_line=$(eval "${_output}" | tail -n 1 | ansi2txt)
    ;;
    darwin*)
        _last_line=$(eval "${_output}" | tail -n 1)
    ;;
    esac

    local _file=$(echo "${_last_line}" | cut -d':' -f1)

    if [[ ! -r "${_file}" ]]; then
        return $(_error "file [${_file}] does not exist.")
    fi

    local _unadjusted_line_num=$(echo "${_last_line}" | cut -d':' -f2 -s)
    local _line_num_arg
    if [[ -n $_unadjusted_line_num ]]; then
        # Account for terminal height so line number appears at top of editor
        _line_num=$((_unadjusted_line_num+$(tput lines)-8))

        if [[ ("${_line_num}" -gt 0) && ("${_line_num}" -lt $(wc -l "${_file}" | cut -d' ' -f1)) ]]; then
            echo -e "opening: [${_file}] @ [${GREEN}${_line_num}${ENDCOLOR}]"
            _line_num_arg="+${_line_num}"
        fi
    else
        echo "opening: [${_file}]"
    fi

    local _context_before=20
    local _context_after=${1:-20}
    local _begin=$((_unadjusted_line_num-_context_before))
    if [[ ! ($_begin -ge 0) ]]; then
        _begin=0
    fi
    local _end=$((_unadjusted_line_num+_context_after))
    set -x
    sed -n "${_begin},${_end}p" ${_file}
    { set +x; } &> /dev/null
}
_add_function open_file_from_prior_cmd_around
_rename_function open_file_from_prior_cmd_around opfa

open_file() {
    # echo "=> [${1@Q}]"
    # echo "=> [${1@E}]"
    # echo "=> [${1@P}]"
    # echo "=> [${1@A}]"
    # echo "=> [${1@a}]"
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 arguments" "<file>")
    fi
   local _linux_path="${1//\\//}"
    echo "Opening [${1}] as: [${_linux_path}]"
    if [[ ! -f ${_linux_path} ]]; then
        echo "[${_linux_path}] doesn't exist" >&2
        read -p "Are you sure? " -n 1 -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return $(_error "[${_linux_path}] doesn't exist")
        fi
    fi
    eval emacs ${EDITOR_OPTS} ${_linux_path}
}
_add_function open_file
_rename_function open_file e

# num commits since head
num_commits_since_head() {
    if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) != "true" ]]; then
            return $(_error "not inside working tree.")
    fi
    local _base_branch=${1:-master}
    git rev-list --count ${_base_branch}.. #$(git rev-parse --abbrev-ref HEAD)
}
_add_function num_commits_since_head

sincehead() {
    local _delimiter=${1:-SERVER}
    local _commit=$(git log --format="format:%s|%H" | grep "^${_delimiter}-[0-9]\+" | head -n 1 | rev | cut -d'|' -f1 | rev)
    echo -e "${PURPLE}first commit off parent${ENDCOLOR}: [${CYAN}${_commit}${ENDCOLOR}]\n"
    git rev-list --ancestry-path --date=local --pretty=format:"%h - %Cgreen%cd%Creset - %s" ${_commit}^..HEAD | grep -v "^commit "
    echo
    git diff --stat ${_commit}^..HEAD | grep -v "^commit "
    local _num_commits=$(git rev-list --ancestry-path ${_commit}^..HEAD | wc -l | awk -F' ' '{print $1}')
    echo -e "${GREEN}${_num_commits}${ENDCOLOR} commits."
    read -p "See diff? [y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        eval gitdiffhead "${_num_commits}"
    fi
}
_add_function sincehead
_rename_function sincehead si

sha8() {
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<file>")
    fi
    echo $1 | head -c 8 && echo
}
_add_function sha8

includes() {
    echo "" | ${MYCOMPILER:-g++} -v -x c++ -E - |& grep "^ [^\"(].*$" | xargs -I{} readlink -f {}
}
_add_function includes

findsys() {
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<search_term>")
    fi
    local _filename=$1
    local _system_files=$(includes | tr '\n' ' ')
    set -x
    find ${_system_files} -name "${_filename}"
    { set +x; } &> /dev/null
}
_add_function findsys

findinsys() {
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<search_term>")
    fi
    local _search_term=$1
    local _system_files=$(includes | tr '\n' ' ')
    set -x
    grep -Irs --color=always "${_search_term}" ${_system_files}
    { set +x; } &> /dev/null
}
_add_function findinsys

lfindinsys() {
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<search_term>")
    fi
    local _search_term=$1
    local _system_files=$(includes | tr '\n' ' ')
    set -x
    grep -lIrs "${_search_term}" ${_system_files}
    { set +x; } &> /dev/null
}
_add_function lfindinsys

git_file_and_line() {
    local _diff_output=$(git diff --unified=0 HEAD~1..HEAD)
    local _filtered_output=$(echo "$_diff_output" | grep -Po '(^diff --git [a-zA-Z/._]*|^@@.*@@)')
    echo "$_filtered_output" | while read l; do
        if [[ -n ${l##@@*} ]]; then
            f=${l#*/}
        else
            echo "$f:${l##@@ }" | cut -d' ' -f1 | tr -d '-'
        fi
    done
}
_add_function git_file_and_line

blame_every_line() {
    git_file_and_line | while read l; do
        file=${l%%:*}
        line=${l##*:}
        git blame -L${line},+1 HEAD^ -- ${file}
    done
}
_add_function blame_every_line
_rename_function blame_every_line bel

next_file() {
    : Next File
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<filename>")
    fi
    local _filename=$1
    # find highest number given filename base
    local _counter=0
    local _file_list_count
    case $OSTYPE in
    linux*|msys*)
        _file_list_count=$(ls ${_filename}* 2>/dev/null | grep "${_filename}[0-9]\+$" | wc -l)
    ;;
    darwin*)
        _file_list_count=$(ls ${_filename}* 2>/dev/null | grep "${_filename}[0-9]\+$" | wc -l | awk -F' ' '{print $1}')
    ;;
    esac
    #echo "cnt: ${_file_list_count}"
    if [[ "${_file_list_count}" -gt 0 ]]; then
        ls "${_filename}*" 2>/dev/null | while read file; do
            echo "f: ${file}"
        done
        while [[ -f "${_filename}${_file_list_count}" ]]; do
            _file_list_count=$((_file_list_count + 1))
        done
    fi
    echo "${_filename}${_file_list_count}"
}
_add_function next_file
_rename_function next_file nf

next_dir() {
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<filename>")
    fi
    local _fullpath=$1
    local _filename=$(basename $1)
    local _dirname=$(dirname $1)
    local _file_list_count
    case $OSTYPE in
    linux*|msys*)
        _file_list_count=$(\find /Users/matt.kneiser/data/db -maxdepth 1 -mindepth 1 -name "test*" | wc -l)
    ;;
    darwin*)
        _file_list_count=$(\find /Users/matt.kneiser/data/db -maxdepth 1 -mindepth 1 -name "test*" | wc -l | awk -F' ' '{print $1}')
    ;;
    esac

    # echo "cnt: ${_file_list_count}"
    if [[ "${_file_list_count}" -gt 0 ]]; then
        while [[ -d "${_fullpath}${_file_list_count}" ]]; do
            _file_list_count=$((_file_list_count + 1))
        done
    fi
    echo "${_fullpath}${_file_list_count}"
}
_add_function next_dir
_rename_function next_dir nd

head-and-tail() {
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<filename>")
    fi
    local _file=$1
    local _cols=$(tput cols)
    tput rmam
    head $_file
    for a in $(seq ${_cols}); do echo -n '-'; done && echo
    tail $_file
    tput smam
}
_add_function head-and-tail
_rename_function head-and-tail hat

# Dive one layer deeper than `func`, usually for renames
ffunc() {
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<filename>")
    fi
    local _funcname=$1
    local _nested_funcname=$(declare -f $_funcname | head -n 3 | tail -n 1 | tr -s ' ' | cut -d' ' -f2)
    declare -f $_nested_funcname
}
_add_function ffunc

# Iterates through each file, opening each one in `more`
# Usage:
#  $ find . -name '*.txt' | each
each() {
    declare -a _files=${1:-$(</dev/stdin)};
    # read _files
    if [[ $# -eq 0 && ${#_files[@]} -eq 0 ]]; then
        return $(_error "requires at least 1 argument" "<filename>")
    fi
    # echo "  @: [${@}]"
    # local _files=${@}
    # if [[ $1 = "alias [" ]]; then
    #     _files=${@:2}
    # fi
    # echo "@:2: [${@:2}]"
    clear
    tput smcup
    for f in ${_files[@]}; do
        if [[ -f $f ]]; then
            echo "file [$f]"
            sleep 1
            # \less -cR +F $f
            if [[ $OSTYPE =~ darwin* ]]; then
                more -c $f
                local _wait_pid=$!
                wait -f $_wait_pid
            else
                less $f
                local _wait_pid=$!
                wait -n $_wait_pid
            fi
        else
            echo "File [$f] does not exist. Skipping."
        fi
    done
    tput rmcup
}
_add_function each

_git_backup_branch() {
    local _cur_branch=$(git rev-parse --abbrev-ref HEAD)
    set -x
    git checkout -b "${_cur_branch}.bk"
    { set +x; } &>/dev/null
    git checkout -
}
_add_function _git_backup_branch
_rename_function _git_backup_branch gbb

_git_checkout_prior_branch() {
    if [[ $# -ne 1 ]]; then
        return $(_error "requires 1 argument" "<number>")
    fi
    local _prior_branch_number=$1
    echo -e -n "Checkout [${GREEN}$(git rev-parse --abbrev-ref @{-${_prior_branch_number}})${ENDCOLOR}]"
    read -p "? [y/n]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout "@{-${_prior_branch_number}}"
    fi
}
_add_function _git_checkout_prior_branch
_rename_function _git_checkout_prior_branch gcpb

lint-diary() {
    local _dates=$(grep "^# [0-9]\{2\}/[0-9]\{2\}/[0-9]\{4\}" ~/.diary | cut -d' ' -f2-)
    diff -q <(echo "${_dates}") <(echo "${_dates}" | sort -t'/' -k3,3 -k1,1 -k2,2) 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}error:${ENDCOLOR} .diary dates not lined up" >&2
        diff -y --color <(echo "${_dates}") <(echo "${_dates}" | sort -t'/' -k3,3 -k1,1 -k2,2)
        # TODO: auto-fix
    else
        echo -e "${GREEN}diary sorted!${ENDCOLOR}"
    fi
}
_add_function lint-diary

# list last few touched files
lt() {
    if [[ $# -gt 0 ]]; then
        las -r . | tail -n ${1}
    else
        # las -r ${1:-.} | tail
        las -r | tail
    fi
}
_add_function lt


# is-jira-ticket() {
# }

# jira-cli-open() {
#     if [[ $# -ne 1 ]]; then
#         return $(_error "requires 1 argument" "<JIRA-ID>")
#     fi
#     local _jira_id=$1
#     jira-cli issue view SERVER-${_jira_id}
# }
# _add_function jira-cli-open
# _rename_function jira-cli-open jo

# jira-cli-branch-open() {
#     local _cur_branch=$(git rev-parse --abbrev-ref HEAD)
# }

# Inspiration: https://askubuntu.com/questions/1188024/how-to-test-oom-killer-from-command-line
oomlog() {
    local _boot_num=0 # `journalctl --list-boots` for full history
    if [[ -n $1 ]]; then
        _boot_num=$1
    fi
    local _boot_option="-b ${_boot_num}"

    # Get timestamp if recorded with `logger` command:
    journalctl --identifier=kernel "${_boot_option}" | grep -A 2 'oom-killer' | tail -n 3

    # Get Call Trace
    journalctl --identifier=kernel "${_boot_option}" | grep 'Call Trace:' | tail -n 1
    journalctl --identifier=kernel "${_boot_option}" | grep ' kernel\:  .*0x[a-f0-9]\+$'

    # Print headings for last oom-killer
    journalctl --identifier=kernel "${_boot_option}" | grep '\[[ ]\+pid[ ]\+]' -B 11 | tail -n 11

    # Get last oom_reaper entry's PID
    PID=$(journalctl --identifier=kernel "${_boot_option}" | grep oom_reaper | tail -n 1 | cut -d' ' -f9)

    # Print pid information
    journalctl --identifier=kernel "${_boot_option}" | grep "$PID"']' | tail -n1

    # Print summary infomation
    journalctl --identifier=kernel "${_boot_option}" | grep oom_reaper -B2 | tail -n 3
}
_add_function oomlog

yesterday() {
    local _yesterday_date=$(date -d yesterday "+%Y-%m-%d")
    set -x
    cat ~/.logs/bash-history-${_yesterday_date}.log
    { set +x; } &>/dev/null
}
_add_function yesterday

today() {
    local _today_date=$(date +%F)
    set -x
    cat ~/.logs/bash-history-${_today_date}.log
    { set +x; } &>/dev/null
}
_add_function today

## 7) Bash Completion
# Enable bash completion in interactive shells
# recursively sources everything in /etc/bash_completion.d/
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
    # Args:[cdc out cdc] C:[1] 1:[cdc] 2:[out]
    local _mrmf;
    if [[ "${COMP_CWORD}" -eq 1 ]]; then
        if [[ -n "${2}" && (-f "${2}" || -d "${2}") ]]; then
            _mrmf=$(_most_recently_modified_file "${2}")
        elif [[ -z "${2}" ]]; then
             _mrmf=$(_most_recently_modified_file)
             #echo "not doing"
        # else
        #     _mrmf=$(compgen -w "${verbs[*]}" -- "${COMP_WORDS[COMP_CWORD]}")
        fi
        #echo "result: ${_mrmf}"
        COMPREPLY="${_mrmf}"
    fi
    # if [[ ("${COMP_CWORD}" -eq 1) && (-n "${2}") ]]; then
    #     local latest_filename=$(find "${2}" -maxdepth 1 -printf '%T@ %f\n' 2>/dev/null | sort -n 2>/dev/null | cut -d' ' -f2- 2>/dev/null | tail -n 2 2>/dev/null | head -n 1)
    #     if [[ -n "${latest_filename}" ]]; then
    #         if [[ "${2}" == */ ]]; then
    #             COMPREPLY="${2}${latest_filename}"
    #         else
    #             COMPREPLY="${2}/${latest_filename}"
    #         fi
    #     fi
    # elif [[ "${COMP_CWORD}" -eq 1 ]]; then
    #     COMPREPLY=$(\ls -t --color=never | head -n 1)
    # fi
}
_add_function _complete_most_recently_modified_file
complete -o default -F _complete_most_recently_modified_file tl l dx unz \
    && _add_completion_function tl l dx unz

_complete_most_recently_modified_text_file() {
    local _mrmtf;
    if [[ "${COMP_CWORD}" -eq 1 ]]; then
        if [[ -n "${2}" && (-f "${2}" || -d "${2}") ]]; then
            _mrmtf=$(_most_recently_modified_text_file "${2}")
        elif [[ -z "${2}" ]]; then
             _mrmtf=$(_most_recently_modified_text_file)
        fi
        COMPREPLY="${_mrmtf}"
    fi
}
complete -o default -F _complete_most_recently_modified_text_file les le
_add_completion_function les le

# Add bash auto-completion to `screen -r` alias
_complete_scr() {
    local does_screen_exist=$(type -t _screen_sessions)
    local cur=$2 # Needed by _screen_sessions
    if [[ "function" = "${does_screen_exist}" ]]; then
        _screen_sessions "Detached"
    fi
}
_add_function _complete_scr
complete -F _complete_scr scr sck && _add_completion_function scr sck

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
    local cur prev;
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
complete -F _apt_get_install _agi agi acs && _add_completion_function _agi agi acs

_mail_addresses() {
    local cur prev;
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
complete -F _man man # therefore the m alias will pick this up

_add_alias cdc "cd"
complete -F _complete_most_recently_modified_file cdc && _add_completion_function


## 8) Miscellaneous
# Set XTERM window name
case "$TERM" in
xterm*|rxvt*)
    #_add_variable PROMPT_COMMAND 'echo -ne "\033]0;${PWD##*/}| ${USER}@${HOSTNAME}\007"'
    # Store *all* bash history in ~/.logs
    if [[ ! -d ~/.logs ]]; then
        mkdir ~/.logs
    fi
    _add_variable PROMPT_COMMAND 'if [ "$(id -u)" -ne 0 ]; then echo "$(date "+%Y-%m-%d.%H:%M:%S") $(pwd) $(history 1)" >> ~/.logs/bash-history-$(date "+%Y-%m-%d").log; fi; echo -ne "\033]0;${PWD##*/}| ${USER}@${HOSTNAME}\007"'
;;
dumb*) # Emacs
    _add_variable TERM xterm-256color
;;
esac
_add_variable EDITOR_OPTS "-nw" # --no-init"
_add_variable EDITOR "emacs ${EDITOR_OPTS}"
_add_variable GIT_EDITOR "${EDITOR}"
_add_variable GIT_PAGER "less -iFXR"
_add_variable MAN_PAGER "less -i"
_add_variable LESS "-iFXR"
_add_variable LESSEDIT "${EDITOR}"
if [[ -x $(which source-highlight 2>/dev/null) ]]; then
    # _add_variable LESSOPEN "| /usr/share/source-highlight/src-hilite-lesspipe.sh %s"
    colors=$(tput colors)
    if [[ "${colors}" -eq 256  ]]; then
        NB="256"
    else
        NB=""
    fi
    _add_variable LESSOPEN "| source-highlight --outlang-def=esc${NB}.outlang --style-file=esc${NB}.style -i %s"
    # _add_variable LESSOPEN "| /usr/bin/source-highlight-esc.sh %s"
else
    if [[ $OSTYPE = "linux*" ]]; then
        _error "LESSOPEN not set. 'brew/apt-get install source-highlight'"
    fi
fi


## 9) Machine-Specific
# Recommended to define in .machine:
#  - VPN_NAME: machine-consumable name of VPN network to connect to
#  - VPN_KEYCHAIN_NAME: uuid generated str
source_file ~/.machine
sem() { _search_file_wrapper $# "${@}" ~/.machine; }
_add_function sem
case $OSTYPE in
darwin*)
    _add_alias vpnc "scutil --nc start '${VPN_NAME}' --user ${USER} --password \$(security find-generic-password -s ${VPN_KEYCHAIN_NAME} -w) --secret \$(security find-generic-password -s ${VPN_KEYCHAIN_NAME}.SS -w)"
    _add_alias vpnd "scutil --nc stop '${VPN_NAME}'"
    _add_alias vpns "scutil --nc status '${VPN_NAME}'"
    _add_alias vpnl "scutil --nc list"
    _add_alias vpnr "vpnd; sleep 2; vpnc;"
;;
esac

seml() { _search_file_occur_wrapper $# "$1" ~/.machine; }
_add_function seml

# _add_variable USER_EMAIL "${USER}@${HOSTNAME}"


## 10) Cleanup
unset DATE_FORMAT


## 11) SSH
reboot-ssh-agent() {
    # Kill the main ssh-agent
    eval "$(ssh-agent -k)"

    # Kill any duplicates, orphans, zombies.
    pgrep -a ssh-agent
    pkill ssh-agent

    # Start anew.
    eval "$(ssh-agent -s)"
}
_add_function reboot-ssh-agent

# ssh-add -l # list all fingerprints of identities loaded by agent

if [[ -n $SSH_AGENT_PID ]] && ps -p $SSH_AGENT_PID >/dev/null; then
   echo -e "${PURPLE}ssh-agent already running${ENDCOLOR}"
else
    num_ssh_keys=$(find -L ~/.ssh -name 'id_*' | wc -l | awk -F' ' '{print $1}')
    if [[ $num_ssh_keys -gt 0 ]]; then
        if [[ ! -x $(which keychain 2>/dev/null) ]]; then
            case $OSTYPE in
            linux*)
                sudo apt-get install -y keychain
            ;;
            darwin*)
                brew install keychain
            ;;
            esac
        fi

        if [[ ! -d ~/.keychain ]]; then
            set -x
            keychain id_rsa
            . ~/.keychain/`uname -n`-sh
            { set +x; } &>/dev/null
        fi
        eval "$(ssh-agent -s)"
        . ~/.keychain/`uname -n`-sh
    fi
fi

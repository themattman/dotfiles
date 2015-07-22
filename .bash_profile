##
# .bash_profile
#
# Author:       Matt Kneiser
# Created:      02/06/2014
# Last updated: 07/22/2015

# Bashrc Guard
if [ -z "${PS1}" ]; then
    return
fi

if [[ -n "${SSH_TTY}" ]]; then
cat <<WELCOME_MSG
     ___          ___                       ___          ___          ___          ___
    /\  \        /\__\                     /\__\        /\  \        /\  \        /\__\\
   _\:\  \      /:/ _/_                   /:/  /       /::\  \      |::\  \      /:/ _/_
  /\ \:\  \    /:/ /\__\                 /:/  /       /:/\:\  \     |:|:\  \    /:/ /\__\\
 _\:\ \:\  \  /:/ /:/ _/_  ___     ___  /:/  /  ___  /:/  \:\  \  __|:|\:\  \  /:/ /:/ _/_
/\ \:\ \:\__\/:/_/:/ /\__\/\  \   /\__\/:/__/  /\__\/:/__/ \:\__\/::::|_\:\__\/:/_/:/ /\__\\
\:\ \:\/:/  /\:\/:/ /:/  /\:\  \ /:/  /\:\  \ /:/  /\:\  \ /:/  /\:\~~\  \/__/\:\/:/ /:/  /
 \:\ \::/  /  \::/_/:/  /  \:\  /:/  /  \:\  /:/  /  \:\  /:/  /  \:\  \       \::/_/:/  /
  \:\/:/  /    \:\/:/  /    \:\/:/  /    \:\/:/  /    \:\/:/  /    \:\  \       \:\/:/  /
   \::/  /      \::/  /      \::/  /      \::/  /      \::/  /      \:\__\       \::/  /
    \/__/        \/__/        \/__/        \/__/        \/__/        \/__/        \/__/
      ___           ___        ___        ___           ___           ___           ___
     /\__\         /\  \      /\  \      /\  \         /\__\         /\  \         /\__\\
    /::|  |       /::\  \     \:\  \     \:\  \       /::|  |       /::\  \       /::|  |
   /:|:|  |      /:/\:\  \     \:\  \     \:\  \     /:|:|  |      /:/\:\  \     /:|:|  |
  /:/|:|__|__   /::\~\:\  \    /::\  \    /::\  \   /:/|:|__|__   /::\~\:\  \   /:/|:|  |__
 /:/ |::::\__\ /:/\:\ \:\__\  /:/\:\__\  /:/\:\__\ /:/ |::::\__\ /:/\:\ \:\__\ /:/ |:| /\__\\
 \/__/~~/:/  / \/__\:\/:/  / /:/  \/__/ /:/  \/__/ \/__/~~/:/  / \/__\:\/:/  / \/__|:|/:/  /
       /:/  /       \::/  / /:/  /     /:/  /            /:/  /       \::/  /      |:/:/  /
      /:/  /        /:/  /  \/__/      \/__/            /:/  /        /:/  /       |::/  /
     /:/  /        /:/  /                              /:/  /        /:/  /        /:/  /
     \/__/         \/__/                               \/__/         \/__/         \/__/
WELCOME_MSG
fi

# Make backspace work
#stty erase ^H

export EDITOR="emacs -nw"
export GIT_EDITOR="emacs -nw"
export MAN_PAGER="less -i"
source ~/.bashrc

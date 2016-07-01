##
# .bash_profile
#
# Author:       Matt Kneiser
# Created:      02/06/2014
# Last updated: 06/30/2016

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

# Make sure IFS is set correctly
unset IFS

# Make backspace work
#stty erase ^H

# # Android Studio/Intellij Paths
# PATH=$PATH:/usr/lib/jvm/java-1.7.0-openjdk-amd64/bin
# PATH=$PATH:.../android/android-studio/bin
# STUDIO_JDK=.../android/jdk1.8.0_65
# export STUDIO_JDK
# ANDROID_SDK=.../android/android-sdk-linux
# export ANDROID_SDK
# JDK_HOME=$STUDIO_JDK
# export JDK_HOME
# ANDROID_HOME=$ANDROID_SDK
# export ANDROID_HOME
# ANDROID_NDK=.../android/android-ndk-r10e
# export ANDROID_NDK
# PATH=$PATH:$ANDROID_SDK/platform-tools:$ANDROID_SDK/tools:$ANDROID_SDK/build-tools:$ANDROID_NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin
# JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk-amd64
# export JAVA_HOME
# GRADLE_HOME=.../android/android-studio/gradle/gradle-2.8/bin
# PATH=$PATH:$GRADLE_HOME
# export GRADLE_HOME
# PATH=$PATH:$JAVA_HOME


export EDITOR="emacs -nw"
export GIT_EDITOR="emacs -nw"
export MAN_PAGER="less -i"
export USER_EMAIL="" # TODO: Set this
source ~/.bashrc

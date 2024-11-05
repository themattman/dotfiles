#!/usr/bin/env bash

echo
echo "##########################"
echo "# Install MacOS Packages #"
echo "##########################"
which brew &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "Error: homebrew doesn't exist. Install via https://github.com/Homebrew/brew or https://brew.sh/" >&2
    exit 1
fi
# / bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew_formulae=(bash bash-completion boost cppfilt dos2unix emacs jira-cli jq keychain moreutils rust screen source-highlight stow wget)
# ffmpeg

for formula in ${brew_formulae[@]}; do
    set -x
    brew install ${formula}
    { set +x; } &>/dev/null
done

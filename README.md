# .:dotfiles:.
My configuration files.

## Installation

### Install this repo

In one mighty step:

    $ git clone https://github.com/themattman/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./bootstrap.sh
    
Or in three:

    $ git clone https://github.com/themattman/dotfiles.git ~/.dotfiles
    $ cd ~/.dotfiles
    $ ./bootstrap.sh

Provide `-h` to `bootstrap.sh` to get the help menu for the installation script.

### Make local modifications

Add aliases and functions customized for each machine's environment. For me, this usually means aliasing the `cd` builtin to help the user navigate the machine's filesystem or aliasing common `ssh` hostnames. These customizations usually aren't shared across machines and must be created on a case-by-case basis.

    $ touch ~/.machine
    $ $EDITOR ~/.machine # assumes $EDITOR is set to your preferred editor

## Requirements
Python 2.7.x
(Untested on other versions)

## Inspiration

https://github.com/bamos/dotfiles

http://dotfiles.github.io/

# .:dotfiles:.
My configuration files.

## Install

    $ git clone https://github.com/themattman/dotfiles.git && cd dotfiles && source bootstrap.sh

### Make local modifications

Add aliases and functions customized for each machine's environment. For me, this usually means aliasing the `cd` builtin to help the user navigate the machine's filesystem or aliasing common `ssh` hostnames. These customizations usually aren't shared across machines and must be created on a case-by-case basis.

    $ touch ~/.machine
    $ $EDITOR ~/.machine # assumes $EDITOR is set to your preferred editor

## Inspiration

https://github.com/bamos/dotfiles

https://dotfiles.github.io/

https://github.com/rafi/etc-skel


## In Action

![img](https://raw.githubusercontent.com/themattman/dotfiles/master/how_to_use.gif)

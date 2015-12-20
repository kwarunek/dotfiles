[ -z "$PS1" ] && return

HISTCONTROL=ignoredups:ignorespace

export PATH=$PATH:$HOME/.local/bin:$HOME/bin

shopt -s histappend
shopt -s checkwinsize

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=100000
PROMPT_COMMAND='history -a'

export EDITOR="vim"

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

[[ -s ~/.bash_aliases ]] && . ~/.bash_aliases
[[ -s ~/.bash_functions ]] && . ~/.bash_functions

CU='32'
[[ "$SUDO_USER " == " " ]] || CU='36'
[[ "$USER " == "root " ]] && CU='31'

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;${CU}m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# nvm and rvm should set these in .bash_profile on install
[[ -s ~/.nvm/nvm.sh ]] && . ~/.nvm/nvm.sh
[[ -s ~/.rvm/scripts/rvm ]] && . ~/.rvm/scripts/rvm

[[ -s ~/.bash_profile ]] && . ~/.bash_profile

[ -z "$PS1" ] && return

HISTCONTROL=ignoredups:ignorespace

export PATH="$HOME/bin:$PATH"


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


PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
#   PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '


. ~/.bash_aliases

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi



extract () {
  if [ -f $1 ] ; then
      case $1 in
          *.tar.bz2)   tar xvjf $1    ;;
          *.tar.gz)    tar xvzf $1    ;;
          *.bz2)       bunzip2 $1     ;;
          *.rar)       rar x $1       ;;
          *.gz)        gunzip $1      ;;
          *.tar)       tar xvf $1     ;;
          *.tbz2)      tar xvjf $1    ;;
          *.tgz)       tar xvzf $1    ;;
          *.zip)       unzip $1       ;;
          *.Z)         uncompress $1  ;;
          *.7z)        7z x $1        ;;
          *)           echo "don't know how to extract '$1'..." ;;
      esac
  else
      echo "'$1' is not a valid file!"
  fi
}

[[ -s ~/.nvm/nvm.sh ]] && . ~/.nvm/nvm.sh
[[ -s ~/.rvm/scripts/rvm ]] && . ~/.rvm/scripts/rvm
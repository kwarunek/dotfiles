[ -z "$PS1" ] && return

HISTCONTROL=ignoredups:erasedups:ignorespace

shopt -s histappend
shopt -s checkwinsize

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=100000
PROMPT_COMMAND='history -a'

if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
*-256color)
    alias ssh='TERM=${TERM%-256color} ssh'
    ;;
*)
    POTENTIAL_TERM=${TERM}-256color
    POTENTIAL_TERMINFO=${TERM:0:1}/$POTENTIAL_TERM

    # better to check $(toe -a | awk '{print $1}') maybe?
    BOX_TERMINFO_DIR=/usr/share/terminfo
    [[ -f $BOX_TERMINFO_DIR/$POTENTIAL_TERMINFO ]] && \
        export TERM=$POTENTIAL_TERM

    HOME_TERMINFO_DIR=$HOME/.terminfo
    [[ -f $HOME_TERMINFO_DIR/$POTENTIAL_TERMINFO ]] && \
        export TERM=$POTENTIAL_TERM

    TERM_CAP_LIST==$(toe -a | awk '{print $1}')
    [[ "$TERM_CAP_LIST" =~ "$POTENTIAL_TERM" ]] && \
        export TERM=$POTENTIAL_TERM

    ;;
esac

[[ -s ~/.bash_aliases ]] && . ~/.bash_aliases
[[ -s ~/.bash_functions ]] && . ~/.bash_functions
[[ -s ~/.bash_local ]] && . ~/.bash_local


[[ -z ${UserTColor-} ]] && UserTColor=95

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;${UserTColor}m\]\u@\h\[\033[00m\]:\[\033[01;36m\]\w\[\033[00m\]\$ '

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

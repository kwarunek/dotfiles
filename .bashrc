[[ -z "$PS1" ]] && return

HISTCONTROL=ignoredups:erasedups:ignorespace

shopt -s histappend
shopt -s checkwinsize

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=9999999999
export HISTFILESIZE=9999999999
export HISTIGNORE="ls:ls -l:ll:history:vi:vim:top:ps:ps axf:cd:git reclone:git pull:git diff:git push:git st:pyhn:git log:fg:mc:clear:pwd"

PROMPT_COMMAND='history -a;'

if [[ -z "$debian_chroot" ]] && [[ -r /etc/debian_chroot ]]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
*-256color)
    alias ssh='TERM=${TERM%-256color} ssh'
    ;;
*)
    POTENTIAL_TERM=${TERM}-256color
    POTENTIAL_TERMINFO=${TERM:0:1}/$POTENTIAL_TERM

    BOX_TERMINFO_DIR=/usr/share/terminfo
    [[ -f $BOX_TERMINFO_DIR/$POTENTIAL_TERMINFO ]] && \
        export TERM=$POTENTIAL_TERM

    HOME_TERMINFO_DIR=$HOME/.terminfo
    [[ -f $HOME_TERMINFO_DIR/$POTENTIAL_TERMINFO ]] && \
        export TERM=$POTENTIAL_TERM
    ;;
esac

[[ -f ~/.bash_colors ]] && source ~/.bash_colors
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases
[[ -f ~/.bash_functions ]] && source ~/.bash_functions
[[ -f ~/.bash_local ]] && source ~/.bash_local


[[ -z ${UserTColor-} ]] && UserTColor=95

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;${UserTColor}m\]\u@\h\[\033[00m\]:\[\033[01;36m\]\w\[\033[00m\]\$ '

if [[ -f /etc/bash_completion ]] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

[[ -f "$HOME/.asdf/asdf.sh" ]] && source "$HOME/.asdf/asdf.sh"
[[ -f "$HOME/.asdf/completions/asdf.bash" ]] && source "$HOME/.asdf/completions/asdf.bash"


# Kubernetes
if command -v kubectl &>/dev/null; then
    [[ -f ~/.kubectl_aliases ]] && source ~/.kubectl_aliases

    if [[ ! -f ~/.bash_cache.d/kubectl_completion ]]; then
        kubectl completion bash > ~/.bash_cache.d/kubectl_completion
    fi

    source ~/.bash_cache.d/kubectl_completion
    complete -F __start_kubectl k
fi

# Terraform
if command -v terraform &>/dev/null; then
    complete -C terraform terraform
fi

if command -v starship &>/dev/null; then
    if [[ ! -f ~/.bash_cache.d/starship ]]; then
        starship init bash > ~/.bash_cache.d/starship
    fi
    source ~/.bash_cache.d/starship
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi


# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias k='kubectl'
alias tf='terraform'
alias jfd='docker run releases-docker.jfrog.io/jfrog/jfrog-cli-v2-jf jf'
alias apt-get='sudo apt-get'
alias ..='cd ..'
alias sha1='openssl sha1'
alias now='date +"%T"'
alias ports='netstat -tulanp'
alias reboot='sudo /sbin/reboot'
alias poweroff='sudo /sbin/poweroff'
alias halt='sudo /sbin/halt'
alias shutdown='sudo /sbin/shutdown'
alias jq='jq -r'
alias docker="sudo /usr/bin/docker"
alias docker-compose="sudo /usr/local/bin/docker-compose"
alias git-reclone='source ~/bin/git-reclone'
alias ssh-new-key='ssh-keygen -t ed25519 -a 128'

alias yaml2json="python3 -c 'import sys, yaml, json; json.dump(yaml.safe_load(sys.stdin if len(sys.argv) != 2 else open(sys.argv[1])), sys.stdout, indent=4)'"
alias json2yaml="python3 -c 'import sys, yaml, json; yaml.dump(json.load(sys.stdin if len(sys.argv) != 2 else open(sys.argv[1])), sys.stdout, indent=2)'"

alias suroot="sudo -Es su -m"

# clipboard
alias cc='xclip -selection c -i'
alias cv='xclip -selection c -o'

alias vi=vim
alias nvimrc='nvim ~/.config/nvim/init.lua'

alias ip-lan="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'"
alias ip-wan="dig +short myip.opendns.com @resolver1.opendns.com"
alias rm-DS="find . -type f -name '*.DS_Store' -ls -delete"
alias rm-pyc="find . -type f -name '*.pyc' -ls -delete"
alias rot13='tr a-zA-Z n-za-mN-ZA-M'

[[ -s ~/.bash_local_aliases ]] && . ~/.bash_local_aliases

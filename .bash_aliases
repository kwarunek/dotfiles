# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
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


alias cpt='xclip -selection c -i'

# lil. nasty thing
alias vi=vim

alias ip-lan="ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'"
alias ip-wan="dig +short myip.opendns.com @resolver1.opendns.com"
alias rm-DS="find . -type f -name '*.DS_Store' -ls -delete"
alias rm-pyc="find . -type f -name '*.pyc' -ls -delete"
alias rot13='tr a-zA-Z n-za-mN-ZA-M'
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
	alias "$method"="lwp-request -m '$method'"
done

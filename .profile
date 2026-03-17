export PATH=$PATH:$HOME/.local/bin:$HOME/bin:$HOME/.krew/bin
export NOSPLASH=1
export NOWELCOME=1
export PAGER=less
export EDITOR=vim
export SAM_CLI_TELEMETRY=0
export TERMINAL=lxterminal

[ -f ~/.profile_local ] && . ~/.profile_local
[ -f ~/.cargo/env ] && . ~/.cargo/env

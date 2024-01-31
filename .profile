export PATH=$PATH:$HOME/.local/bin:$HOME/bin:$HOME/.krew/bin
export NOSPLASH=1
export NOWELCOME=1
export PAGER=less
export EDITOR=vim
export SAM_CLI_TELEMETRY=0

test -e ~/.profile_local && source ~/.profile_local
test -e ~/.cargo/env && source ~/.cargo/env

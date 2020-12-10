export PATH=$PATH:$HOME/.local/bin:$HOME/bin:$HOME/.krew/bin
export NOSPLASH=1
export NOWELCOME=1
export PAGER=less
export EDITOR=vim

test -e ~/.profile_local && source ~/.profile_local
test -e ~/.bashrc && source ~/.bashrc
